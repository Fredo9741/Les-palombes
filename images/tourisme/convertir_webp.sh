#!/bin/bash

# Script de conversion JPG/JPEG → WebP avec redimensionnement, nettoyage EXIF,
# et option de suppression des originaux avec confirmation

VENV_DIR=".venv"

# Créer un environnement virtuel si nécessaire
if [ ! -d "$VENV_DIR" ]; then
    echo "🔧 Création de l'environnement virtuel..."
    python3 -m venv "$VENV_DIR"
fi

# Activer l'environnement
source "$VENV_DIR/bin/activate"

# Installer Pillow si nécessaire
pip show pillow > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "📦 Installation de Pillow..."
    pip install pillow
fi

# Exécuter le script de conversion
python3 - <<EOF
from PIL import Image, ImageOps
import os

MAX_WIDTH = 800
MAX_HEIGHT = 800
current_folder = os.getcwd()
converted_files = []

for filename in os.listdir(current_folder):
    if filename.lower().endswith((".jpg", ".jpeg")):
        img_path = os.path.join(current_folder, filename)
        webp_path = os.path.join(current_folder, os.path.splitext(filename)[0] + ".webp")

        if os.path.exists(webp_path):
            print(f"⏭️ {filename} ignorée (déjà convertie)")
            continue

        with Image.open(img_path) as img:
            img = ImageOps.exif_transpose(img)
            width, height = img.size

            if width <= MAX_WIDTH and height <= MAX_HEIGHT:
                resized_img = img
            else:
                if width >= height:
                    new_width = MAX_WIDTH
                    new_height = int((new_width / width) * height)
                else:
                    new_height = MAX_HEIGHT
                    new_width = int((new_height / height) * width)
                resized_img = img.resize((new_width, new_height), Image.LANCZOS)

            # Supprimer les métadonnées
            data = list(resized_img.getdata())
            clean_img = Image.new(resized_img.mode, resized_img.size)
            clean_img.putdata(data)

            clean_img.save(webp_path, "WEBP", quality=90)
            print(f"✅ {filename} convertie et nettoyée ({webp_path})")
            converted_files.append(filename)

# Enregistrer les fichiers convertis dans un fichier temporaire pour bash
with open(".to_delete_list.txt", "w") as f:
    for fname in converted_files:
        f.write(fname + "\n")
EOF

# Désactiver le venv
deactivate

# Proposer la suppression après confirmation
if [ -f ".to_delete_list.txt" ]; then
    echo ""
    read -p "🗑️  Supprimer les fichiers originaux JPG/JPEG convertis ? (o/n) : " choix

    if [[ "$choix" == "o" || "$choix" == "O" ]]; then
        echo "🚮 Suppression des fichiers originaux..."
        while IFS= read -r file; do
            rm -f "$file"
            echo "❌ Supprimé : $file"
        done < .to_delete_list.txt
    else
        echo "📂 Fichiers originaux conservés."
    fi

    rm .to_delete_list.txt
fi

# Supprimer l'environnement virtuel
read -p "🧹 Supprimer l'environnement virtuel (.venv) ? (o/n) : " supprvenv
if [[ "$supprvenv" == "o" || "$supprvenv" == "O" ]]; then
    rm -rf "$VENV_DIR"
    echo "🗑️ Environnement .venv supprimé."
else
    echo "✅ Environnement .venv conservé pour une future utilisation."
fi