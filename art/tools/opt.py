import numpy as np, ttcolor as T
rng=np.random.default_rng(4)
def lab2rgb(lab):
    L,a,b=lab; fy=(L+16)/116; fx=fy+a/500; fz=fy-b/200
    f=np.array([fx,fy,fz]); xyz=np.where(f**3>216/24389,f**3,(116*f-16)/(24389/27))*np.array([0.95047,1,1.08883])
    M=np.linalg.inv(np.array([[0.4124564,0.3575761,0.1804375],[0.2126729,0.7151522,0.0721750],[0.0193339,0.1191920,0.9503041]]))
    lin=M@xyz
    if (lin<-1e-4).any() or (lin>1+1e-4).any(): return None
    return T.from_lin(lin)
# hue targets (deg in Lab) to keep names meaningful
targets={"strawberry":5,"butter":90,"pistachio":120,"lavender":300,"apricot":60,"blueberry":280,"cocoa":50,"rhubarb":350,"vanilla":85}
names=[n for n,_,_ in T.REGIONS]
cur=[T.rgb2lab(T.hex2rgb(h)) for _,h,_ in T.REGIONS]
def score(labs):
    rgbs=[lab2rgb(l) for l in labs]
    if any(r is None for r in rgbs): return -1
    m=1e9
    for k in [None]+list(T.MACHADO):
        cs=[r if k is None else T.simulate(r,k) for r in rgbs]
        ls=[T.rgb2lab(c) for c in cs]
        for i in range(9):
            for j in range(i+1,9):
                m=min(m,T.de2000(ls[i],ls[j]))
    return m
best=score(cur); print("start",best)
for it in range(2500):
    i=rng.integers(9); cand=[c.copy() for c in cur]
    c=cand[i]+rng.normal(0,3,3)
    L=c[0]; C=np.hypot(c[1],c[2]); h=np.degrees(np.arctan2(c[2],c[1]))%360
    dh=((h-targets[names[i]]+180)%360)-180
    if abs(dh)>25 or L<58 or L>93 or (names[i]!="vanilla" and C<18) or C>55: continue
    cand[i]=c; s=score(cand)
    if s>best: best,cur=s,cand
print("best",best)
for n,l in zip(names,cur): print(n,T.rgb2hex(lab2rgb(l)),np.round(l,1))
