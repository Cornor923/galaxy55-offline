import zlib, struct, sys
OPS = {0x01:'bkpt',0x02:'nop',0x03:'throw',0x04:'getsuper:m',0x05:'setsuper:m',0x06:'dxns:u',0x07:'dxnslate',0x08:'kill:u',0x09:'label',
0x0C:'ifnlt:s',0x0D:'ifnle:s',0x0E:'ifngt:s',0x0F:'ifnge:s',0x10:'jump:s',0x11:'iftrue:s',0x12:'iffalse:s',0x13:'ifeq:s',0x14:'ifne:s',0x15:'iflt:s',0x16:'ifle:s',0x17:'ifgt:s',0x18:'ifge:s',0x19:'ifstricteq:s',0x1A:'ifstrictne:s',
0x1B:'lookupswitch',0x1C:'pushwith',0x1D:'popscope',0x1E:'nextname',0x1F:'hasnext',0x20:'pushnull',0x21:'pushundefined',0x23:'nextvalue',0x24:'pushbyte:b',0x25:'pushshort:u',0x26:'pushtrue',0x27:'pushfalse',0x28:'pushnan',0x29:'pop',0x2A:'dup',0x2B:'swap',
0x2C:'pushstring:S',0x2D:'pushint:I',0x2E:'pushuint:U',0x2F:'pushdouble:D',0x30:'pushscope',0x31:'pushnamespace:u',0x32:'hasnext2:uu',
0x35:'li8',0x36:'li16',0x37:'li32',0x38:'lf32',0x39:'lf64',0x3A:'si8',0x3B:'si16',0x3C:'si32',0x3D:'sf32',0x3E:'sf64',
0x40:'newfunction:u',0x41:'call:u',0x42:'construct:u',0x43:'callmethod:uu',0x44:'callstatic:uu',0x45:'callsuper:mu',0x46:'callproperty:mu',0x47:'returnvoid',0x48:'returnvalue',0x49:'constructsuper:u',0x4A:'constructprop:mu',0x4C:'callproplex:mu',0x4E:'callsupervoid:mu',0x4F:'callpropvoid:mu',
0x50:'sxi1',0x51:'sxi8',0x52:'sxi16',0x53:'applytype:u',0x55:'newobject:u',0x56:'newarray:u',0x57:'newactivation',0x58:'newclass:u',0x59:'getdescendants:m',0x5A:'newcatch:u',0x5D:'findpropstrict:m',0x5E:'findproperty:m',0x5F:'finddef:m',0x60:'getlex:m',0x61:'setproperty:m',0x62:'getlocal:u',0x63:'setlocal:u',0x64:'getglobalscope',0x65:'getscopeobject:b',0x66:'getproperty:m',0x68:'initproperty:m',0x6A:'deleteproperty:m',0x6C:'getslot:u',0x6D:'setslot:u',0x6E:'getglobalslot:u',0x6F:'setglobalslot:u',
0x70:'convert_s',0x71:'esc_xelem',0x72:'esc_xattr',0x73:'convert_i',0x74:'convert_u',0x75:'convert_d',0x76:'convert_b',0x77:'convert_o',0x78:'checkfilter',0x80:'coerce:m',0x82:'coerce_a',0x85:'coerce_s',0x86:'astype:m',0x87:'astypelate',
0x90:'negate',0x91:'increment',0x92:'inclocal:u',0x93:'decrement',0x94:'declocal:u',0x95:'typeof',0x96:'not',0x97:'bitnot',
0xA0:'add',0xA1:'subtract',0xA2:'multiply',0xA3:'divide',0xA4:'modulo',0xA5:'lshift',0xA6:'rshift',0xA7:'urshift',0xA8:'bitand',0xA9:'bitor',0xAA:'bitxor',0xAB:'equals',0xAC:'strictequals',0xAD:'lessthan',0xAE:'lessequals',0xAF:'greaterthan',0xB0:'greaterequals',0xB1:'instanceof',0xB2:'istype:m',0xB3:'istypelate',0xB4:'in',
0xC0:'increment_i',0xC1:'decrement_i',0xC2:'inclocal_i:u',0xC3:'declocal_i:u',0xC4:'negate_i',0xC5:'add_i',0xC6:'subtract_i',0xC7:'multiply_i',
0xD0:'getlocal0',0xD1:'getlocal1',0xD2:'getlocal2',0xD3:'getlocal3',0xD4:'setlocal0',0xD5:'setlocal1',0xD6:'setlocal2',0xD7:'setlocal3',
0xEF:'debug:bubu',0xF0:'debugline:u',0xF1:'debugfile:S',0xF2:'bkptline:u'}

class R:
    def __init__(s,b,p=0): s.b=b; s.p=p
    def u8(s): v=s.b[s.p]; s.p+=1; return v
    def u30(s):
        r=0; sh=0
        while True:
            x=s.b[s.p]; s.p+=1; r|=(x&0x7f)<<sh; sh+=7
            if not x&0x80: return r
    def s24(s):
        v=s.b[s.p]|(s.b[s.p+1]<<8)|(s.b[s.p+2]<<16); s.p+=3
        return v-0x1000000 if v&0x800000 else v

def load_swf(f):
    d=open(f,'rb').read(); body=zlib.decompress(d[8:]) if d[:3]==b'CWS' else d[8:]
    nb=body[0]>>3; pos=(5+nb*4+7)//8+4; abcs=[]; sym={}; bins={}
    while pos<len(body):
        h=struct.unpack('<H',body[pos:pos+2])[0]; t=h>>6; l=h&63; pos+=2
        if l==63: l=struct.unpack('<I',body[pos:pos+4])[0]; pos+=4
        data=body[pos:pos+l]
        if t==82:
            e=data.index(b'\0',6); abcs.append(data[e+1:])
        elif t==72: abcs.append(data)
        elif t==76:
            r=R(data); n=struct.unpack('<H',data[:2])[0]; q=2
            for _ in range(n):
                cid=struct.unpack('<H',data[q:q+2])[0]; q+=2; e=data.index(b'\0',q); sym[cid]=data[q:e].decode(); q=e+1
        elif t==87: bins[struct.unpack('<H',data[:2])[0]]=data[6:]
        pos+=l
    return abcs,sym,bins

class ABC:
    def __init__(s,b):
        r=R(b,4); s.r=r
        s.ints=[0]+[ (lambda v: v-(1<<32) if v>=1<<31 else v)(r.u30()) for _ in range(max(r.u30()-1,0))] if False else None
        n=r.u30(); s.ints=[0]+[r.u30() for _ in range(max(n-1,0))]
        n=r.u30(); s.uints=[0]+[r.u30() for _ in range(max(n-1,0))]
        n=r.u30(); s.dbl=[0.0]
        for _ in range(max(n-1,0)): s.dbl.append(struct.unpack('<d',b[r.p:r.p+8])[0]); r.p+=8
        n=r.u30(); s.str=['']
        for _ in range(max(n-1,0)):
            l=r.u30(); s.str.append(b[r.p:r.p+l].decode('utf8','replace')); r.p+=l
        n=r.u30(); s.ns=[('',)]
        for _ in range(max(n-1,0)): k=r.u8(); s.ns.append((k,s.str[r.u30()]))
        n=r.u30(); s.nss=[[]]
        for _ in range(max(n-1,0)): s.nss.append([r.u30() for _ in range(r.u30())])
        n=r.u30(); s.mn=[None]
        for _ in range(max(n-1,0)):
            k=r.u8()
            if k in (7,13): ns=r.u30(); nm=r.u30(); s.mn.append(('Q',s.ns[ns][1] if ns<len(s.ns) else '',s.str[nm]))
            elif k in (0xF,0x10): s.mn.append(('RT',s.str[r.u30()]))
            elif k in (0x11,0x12): s.mn.append(('RTL',))
            elif k in (9,0x0E): nm=r.u30(); r.u30(); s.mn.append(('M',s.str[nm]))
            elif k==0x1B: r.u30(); s.mn.append(('MLate',))
            elif k==0x1C: r.u30(); s.mn.append(('MLateA',))
            elif k==0x1D:
                r.u30(); 
                for _ in range(r.u30()): r.u30()
                s.mn.append(('TN',))
            else: raise Exception('mn kind %x'%k)
        nm=r.u30(); s.methods=[]
        for _ in range(nm):
            pc=r.u30(); r.u30(); [r.u30() for _ in range(pc)]; r.u30(); fl=r.u8()
            if fl&8:
                for _ in range(r.u30()): r.u30(); r.u8()
            if fl&0x80: [r.u30() for _ in range(pc)]
            s.methods.append(None)
        for _ in range(r.u30()):
            r.u30()
            for _ in range(r.u30()): r.u30(); r.u30()
        ni=r.u30(); s.inst=[]
        def traits():
            out=[]
            for _ in range(r.u30()):
                nm=r.u30(); k=r.u8(); kind=k&15
                if kind in (0,6):
                    sid=r.u30(); ty=r.u30(); vi=r.u30()
                    if vi: r.u8()
                    out.append((kind,nm,sid,ty))
                elif kind in (1,2,3):
                    did=r.u30(); m=r.u30(); out.append((kind,nm,m))
                elif kind in (4,5):
                    sid=r.u30(); c=r.u30(); out.append((kind,nm,c))
                if k&0x40:
                    for _ in range(r.u30()): r.u30()
            return out
        for _ in range(ni):
            name=r.u30(); sup=r.u30(); fl=r.u8()
            if fl&8: r.u30()
            for _ in range(r.u30()): r.u30()
            iinit=r.u30(); t=traits(); s.inst.append((name,sup,iinit,t))
        s.cls=[]
        for _ in range(ni): ci=r.u30(); s.cls.append((ci,traits()))
        for _ in range(r.u30()): r.u30(); traits()
        s.body={}
        for _ in range(r.u30()):
            m=r.u30(); ms=r.u30(); ls=r.u30(); r.u30(); r.u30(); cl=r.u30(); code=b[r.p:r.p+cl]; r.p+=cl
            for _ in range(r.u30()): [r.u30() for _ in range(5)]
            traits(); s.body[m]=code
    def mname(s,i):
        m=s.mn[i] if i<len(s.mn) else None
        return '%s.%s'%(m[1],m[2]) if m and m[0]=='Q' else str(m)
    def dis(s,mi):
        code=s.body[mi]; r=R(code); out=[]
        while r.p<len(code):
            pc=r.p; op=r.u8(); d=OPS.get(op)
            if d is None: out.append('%04x: ??%02x'%(pc,op)); continue
            nm,_,k=d.partition(':'); args=[]
            if nm=='lookupswitch':
                df=r.s24(); c=r.u30(); args=[df]+[r.s24() for _ in range(c+1)]
            else:
                for ch in k:
                    if ch=='u': args.append(r.u30())
                    elif ch=='b': args.append(r.u8())
                    elif ch=='s': v=r.s24(); args.append('->%04x'%(r.p+v))
                    elif ch=='m': args.append(s.mname(r.u30()))
                    elif ch=='S': args.append(repr(s.str[r.u30()]))
                    elif ch=='I': args.append(s.ints[r.u30()])
                    elif ch=='U': args.append(s.uints[r.u30()])
                    elif ch=='D': args.append(s.dbl[r.u30()])
            out.append('%04x: %s %s'%(pc,nm,' '.join(map(str,args))))
        return out
