import os
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

MUSIC_PATH = "/run/media/koila1998/NIKO/MUSIKK"

def find_cover(root_folder):
    # Buscamos archivos de imagen comunes en la carpeta del álbum
    valid_covers = ['cover.jpg', 'folder.jpg', 'cover.png', 'front.jpg', 'album.jpg']
    for file in os.listdir(root_folder):
        if file.lower() in valid_covers:
            return file
    return None

@app.route('/list')
def list_music():
    songs = []
    if not os.path.exists(MUSIC_PATH):
        return jsonify({"error": "Disco NIKO no montado"}), 404
        
    for root, dirs, files in os.walk(MUSIC_PATH):
        # Intentar encontrar una carátula en esta carpeta
        cover_file = find_cover(root)
        
        for file in files:
            if file.lower().endswith(('.flac', '.mp3', '.wav', '.m4a')):
                rel_path = os.path.relpath(os.path.join(root, file), MUSIC_PATH)
                
                # Si hay carátula, creamos la URL para ella
                cover_url = ""
                if cover_file:
                    rel_root = os.path.relpath(root, MUSIC_PATH)
                    cover_url = f"file/{os.path.join(rel_root, cover_file)}"

                songs.append({
                    "title": file,
                    "path": rel_path,
                    "cover": cover_url
                })
    return jsonify(songs)

@app.route('/file/<path:filename>')
def get_file(filename):
    return send_from_directory(MUSIC_PATH, filename)

if __name__ == '__main__':
    print(f"--- Servidor Sonaura Pro: Carátulas Activas ---")
    app.run(host='0.0.0.0', port=5050, threaded=True)
