import urllib.parse
def parse(s):
    p=[0]; cache=[]
    def val():
        c=s[p[0]]; p[0]+=1
        if c=='n': return None
        if c=='a':
            out=[]
            while s[p[0]]!='h':
                if s[p[0]]=='u':
                    p[0]+=1; j=p[0]
                    while s[p[0]].isdigit(): p[0]+=1
                    out+= [None]*int(s[j:p[0]])
                else: out.append(val())
            p[0]+=1; return out
        if c=='y':
            j=p[0]
            while s[p[0]]!=':': p[0]+=1
            n=int(s[j:p[0]]); p[0]+=1
            raw=s[p[0]:p[0]+n]; p[0]+=n
            v=urllib.parse.unquote(raw); cache.append(v); return v
        if c=='R':
            j=p[0]
            while p[0]<len(s) and s[p[0]].isdigit(): p[0]+=1
            return cache[int(s[j:p[0]])]
        if c=='i':
            j=p[0]
            while p[0]<len(s) and (s[p[0]].isdigit() or s[p[0]]=='-'): p[0]+=1
            return int(s[j:p[0]])
        raise Exception('tok '+c+' at %d'%p[0])
    return val()
