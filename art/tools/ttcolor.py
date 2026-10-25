"""Game #4 (tea-bakery) palette + colour-vision-deficiency (CVD) tools. Original work, PKD."""
import numpy as np

UI = [  # name, hex, use
 ("rosewater_bg",  "#F6E3DE", "App background / wallpaper base"),
 ("clotted_cream", "#FFF8EC", "Panels, recipe card, empty-cell lift"),
 ("earl_grey_ink", "#43283A", "Text, icons, mold + cake outlines (plum-brown, never navy/black)"),
 ("raspberry_jam", "#B0365A", "Primary buttons (Play, Hint), cake frosting"),
 ("sage_leaf",     "#55724E", "Secondary buttons, toggles, success ticks"),
 ("pewter_tray",   "#A8A09F", "Serving-tray rim (silver plate, not wood)"),
 ("toasted_crust", "#C9803A", "Solved glow / golden tray, progress dots, streak accents"),
 ("cherry_alert",  "#A61E2E", "Conflict ring + hatch (always with ! badge, never colour-only)"),
 ("honey_chip",    "#EDBB80", "Info chip fill (day / streak / board n of 5) with ink text (7.5:1)"),
]
# 9 dough-patch regions (9x9 boards need 9). name, hex, pattern
REGIONS = [
 ("strawberry", "#FA93AC", "dots"),
 ("butter",     "#FDE87D", "stripes"),
 ("pistachio",  "#B8DFA6", "gingham"),
 ("lavender",   "#D5BCF1", "lattice"),
 ("honey",      "#DDB664", "crumb"),
 ("blueberry",  "#8E9CC9", "shortbread"),
 ("cocoa",      "#AE906C", "diamond"),
 ("rhubarb",    "#CB6F91", "sprig"),
 ("vanilla",    "#E8E6D9", "pinstripe"),
]

def hex2rgb(h): h=h.lstrip('#'); return np.array([int(h[i:i+2],16) for i in (0,2,4)],float)/255
def rgb2hex(c): c=np.clip(np.round(np.asarray(c)*255),0,255).astype(int); return "#%02X%02X%02X"%tuple(c)
def to_lin(c): c=np.asarray(c,float); return np.where(c<=0.04045,c/12.92,((c+0.055)/1.055)**2.4)
def from_lin(c): c=np.clip(c,0,1); return np.where(c<=0.0031308,c*12.92,1.055*c**(1/2.4)-0.055)

# Machado, Oliveira & Fernandes 2009, severity 1.0 (applied in linear RGB)
MACHADO = {
 "deuteranopia": np.array([[0.367322,0.860646,-0.227968],[0.280085,0.672501,0.047413],[-0.011820,0.042940,0.968881]]),
 "protanopia":   np.array([[0.152286,1.052583,-0.204868],[0.114503,0.786281,0.099216],[-0.003882,-0.048116,1.051998]]),
 "tritanopia":   np.array([[1.255528,-0.076749,-0.178779],[-0.078411,0.930809,0.147602],[0.004733,0.691367,0.303900]]),
}
def simulate(rgb, kind):
    """rgb: (...,3) sRGB floats 0..1"""
    lin = to_lin(rgb)
    return from_lin(lin @ MACHADO[kind].T)

def rgb2lab(rgb):
    lin = to_lin(rgb)
    M = np.array([[0.4124564,0.3575761,0.1804375],[0.2126729,0.7151522,0.0721750],[0.0193339,0.1191920,0.9503041]])
    xyz = lin @ M.T / np.array([0.95047,1.0,1.08883])
    f = np.where(xyz>216/24389, np.cbrt(xyz), (24389/27*xyz+16)/116)
    return np.stack([116*f[...,1]-16, 500*(f[...,0]-f[...,1]), 200*(f[...,1]-f[...,2])],-1)

def de2000(l1,l2):
    L1,a1,b1=l1; L2,a2,b2=l2
    C1=np.hypot(a1,b1); C2=np.hypot(a2,b2); Cb=(C1+C2)/2
    G=0.5*(1-np.sqrt(Cb**7/(Cb**7+25**7)))
    a1p,a2p=(1+G)*a1,(1+G)*a2
    C1p,C2p=np.hypot(a1p,b1),np.hypot(a2p,b2)
    h1=np.degrees(np.arctan2(b1,a1p))%360; h2=np.degrees(np.arctan2(b2,a2p))%360
    dL=L2-L1; dC=C2p-C1p
    dh=h2-h1
    if C1p*C2p==0: dh=0
    elif dh>180: dh-=360
    elif dh<-180: dh+=360
    dH=2*np.sqrt(C1p*C2p)*np.sin(np.radians(dh/2))
    Lb=(L1+L2)/2; Cbp=(C1p+C2p)/2
    if C1p*C2p==0: hb=h1+h2
    elif abs(h1-h2)<=180: hb=(h1+h2)/2
    elif h1+h2<360: hb=(h1+h2+360)/2
    else: hb=(h1+h2-360)/2
    T=1-0.17*np.cos(np.radians(hb-30))+0.24*np.cos(np.radians(2*hb))+0.32*np.cos(np.radians(3*hb+6))-0.20*np.cos(np.radians(4*hb-63))
    dth=30*np.exp(-((hb-275)/25)**2); Rc=2*np.sqrt(Cbp**7/(Cbp**7+25**7))
    Sl=1+0.015*(Lb-50)**2/np.sqrt(20+(Lb-50)**2); Sc=1+0.045*Cbp; Sh=1+0.015*Cbp*T
    Rt=-np.sin(np.radians(2*dth))*Rc
    return float(np.sqrt((dL/Sl)**2+(dC/Sc)**2+(dH/Sh)**2+Rt*(dC/Sc)*(dH/Sh)))

def rel_lum(rgb): l=to_lin(rgb); return float(l@np.array([0.2126,0.7152,0.0722]))
def contrast(a,b):
    la,lb=sorted([rel_lum(hex2rgb(a)),rel_lum(hex2rgb(b))],reverse=True); return (la+0.05)/(lb+0.05)

def pair_report(threshold=10.0):
    out={}
    for kind in ["normal"]+list(MACHADO):
        cols=[hex2rgb(h) for _,h,_ in REGIONS]
        if kind!="normal": cols=[simulate(c,kind) for c in cols]
        labs=[rgb2lab(c) for c in cols]
        pairs=[]
        for i in range(len(REGIONS)):
            for j in range(i+1,len(REGIONS)):
                pairs.append((de2000(labs[i],labs[j]),REGIONS[i][0],REGIONS[j][0]))
        pairs.sort(); out[kind]=pairs
    return out

if __name__=="__main__":
    r=pair_report()
    for k,p in r.items():
        print(k, "min:", ["%s/%s %.1f"%(a,b,d) for d,a,b in p[:5]])

# ---- Role-based contrast gate (structure adapted from Sudoku Dash docs/art/tools/palette.py @a795a1a, PKD in-house) ----
# (fg, bg, required ratio): 4.5 = text (WCAG 1.4.3), 3.0 = non-text UI / graphics (WCAG 1.4.11)
CONTRAST_RULES = [
 ("earl_grey_ink","clotted_cream",4.5), ("earl_grey_ink","rosewater_bg",4.5),
 ("clotted_cream","raspberry_jam",4.5), ("clotted_cream","sage_leaf",4.5),
 ("clotted_cream","cherry_alert",4.5), ("earl_grey_ink","toasted_crust",3.0),
 ("earl_grey_ink","honey_chip",4.5), ("earl_grey_ink","pewter_tray",3.0),
 ("cherry_alert","clotted_cream",3.0),
] + [("earl_grey_ink", n, 3.0) for n,_,_ in REGIONS]   # region borders + X-marks on every patch

def contrast_table():
    P={n:h for n,h,_ in UI}; P.update({n:h for n,h,_ in REGIONS})
    rows=[]
    for fg,bg,need in CONTRAST_RULES:
        v=contrast(P[fg],P[bg]); rows.append((fg,bg,round(v,2),need,"PASS" if v>=need else "FAIL"))
    return rows

def export_palette_json(path):
    import json
    json.dump({"ui":[list(x) for x in UI],"regions":[list(x) for x in REGIONS]},open(path,"w"),indent=1)
