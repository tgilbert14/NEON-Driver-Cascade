#!/usr/bin/env python3
"""Embed the generated ground/bark textures into walk.html as inline data-URIs.

Reads prototypes/site-explorer/tex/*.jpg (256px, generated via image-gen — see
build_tex.md for the prompts), base64-encodes each, and writes/refreshes the
<script id="texData"> JSON block in walk.html. Only the small derived JPEGs are
committed; the multi-MB raw generations are not. Re-run after regenerating a tile.
"""
import base64, json, os, re
HERE=os.path.dirname(os.path.abspath(__file__))
TEXDIR=os.path.join(HERE,"tex"); WALK=os.path.join(HERE,"walk.html")
names=["forest","grassland","dryland","tundra","other","barkconifer","barkdecid"]
data={}
for k in names:
    p=os.path.join(TEXDIR,k+".jpg")
    if os.path.exists(p):
        data[k]="data:image/jpeg;base64,"+base64.b64encode(open(p,'rb').read()).decode()
html=open(WALK).read()
html=re.sub(r'<script id="texData"[^>]*>.*?</script>\n?','',html,flags=re.S)
tag='<script id="texData" type="application/json">'+json.dumps(data)+'</script>'
lines=html.split("\n")
for i,l in enumerate(lines):
    if l.startswith('<script id="walkSites"'): lines.insert(i+1,tag); break
open(WALK,"w").write("\n".join(lines))
print("embedded:",list(data.keys())," tag KB:",len(tag)//1024)
