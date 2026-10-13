import sys
def ksa(key):
    K=[i&127 for i in range(256)]; j=0
    for i in range(256):
        j=(j+K[i]+ord(key[i%len(key)]))&127
        K[i],K[j]=K[j],K[i]
    return K
def decode(data):
    key=data[:5].decode('latin1'); chk=data[5:9].decode('latin1'); body=bytearray(data[9:])
    K=ksa(key); a,b=K[0],K[1]
    for i in range(len(body)):
        c=body[i]; x=c^K[i&255]
        body[i]= c if x==0 else x
        if x==0: c=0
        a=(a+c)%65521; b=(b+a)%65521
    return bytes(body)
