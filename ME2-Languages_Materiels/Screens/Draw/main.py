import matplotlib.pyplot as plt
from PIL import Image, ImageDraw, ImageFont

# Charger l'image originale
img_path = "C:\\Users\\bnola\\Documents\\Polytech\\ETN5\\SETR-2026-2027\\ME2-Languages_Materiels\\Screens\\Screens\\1.png"
img = Image.open(img_path).convert("RGB")
draw = ImageDraw.Draw(img)

# Polices de caractères (par défaut si police système non trouvée)
try:
    font = ImageFont.truetype("arial.ttf", 14)
    font_bold = ImageFont.truetype("arialbd.ttf", 15)
except IOError:
    font = ImageFont.load_default()
    font_bold = font

# Dimensions
width, height = img.size

# --- 1. Lignes verticales pour marquer les fronts montants d'horloge ---
# Coordonnées X approximatives des fronts d'horloge (10ns, 20ns, 30ns)
x_10ns = int(width * 0.385)
x_20ns = int(width * 0.455)
x_30ns = int(width * 0.525)

# Dessiner les lignes d'horloge
draw.line([(x_10ns, 0), (x_10ns, height)], fill="red", width=2)
draw.line([(x_20ns, 0), (x_20ns, height)], fill="red", width=2)

# Texte sur les lignes d'horloge
draw.text((x_10ns - 25, 5), "Front 1", fill="red", font=font_bold)
draw.text((x_20ns - 25, 5), "Front 2", fill="red", font=font_bold)

# --- 2. Encadré explicatif pour l'état non initialisé UU ---
# Zone de DataOut entre 0 et 10ns
draw.rectangle([(int(width * 0.315), int(height * 0.42)), (x_10ns, int(height * 0.50))], outline="orange", width=2)
draw.text((int(width * 0.32), int(height * 0.52)), "1. Non initialisé (UU)", fill="orange", font=font_bold)

# --- 3. Flèche montrant la prise en compte au front d'horloge ---
# Flèche du front 10ns vers la donnée DataOut = 00
draw.line([(x_10ns, int(height * 0.65)), (x_10ns + 15, int(height * 0.46))], fill="cyan", width=2)
draw.text((x_10ns + 20, int(height * 0.42)), "2. Écriture & Sortie de '00'", fill="cyan", font=font_bold)

# Sauvegarder l'image annotée
output_path = "C:\\Users\\bnola\\Documents\\Polytech\\ETN5\\SETR-2026-2027\\ME2-Languages_Materiels\\Screens\\Screens\\chronogramme_annote.png"
img.save(output_path)
print(f"Image sauvegardée sous {output_path}")