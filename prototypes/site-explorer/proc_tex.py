import sys
from PIL import Image
def process(src, dst, size=256, q=80):
    Image.open(src).convert("RGB").resize((size,size), Image.LANCZOS).save(dst, format="JPEG", quality=q)
if __name__=="__main__":
    process(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv)>3 else 256)
    print("wrote", sys.argv[2])
