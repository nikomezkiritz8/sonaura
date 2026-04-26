import os
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
import urllib.parse

app = Flask(__name__)
CORS(app)

# Tu ruta exacta en CachyOS
MUSIC_PATH = "/run/media/koila1998/NIKO/MUSIKK"

@app.route('/list')
def list_music():
    songs = []
    if not os.path.exists(MUSIC_PATH):
        return jsonify({"error": "Disco NIKO no montado"}), 404
        
    for root, dirs, files in os.walk(MUSIC_PATH):
        for file in files:
            if file.lower().endswith(('.flac', '.mp3', '.wav', '.m4a')):
                rel_path = os.path.relpath(os.path.join(root, file), MUSIC_PATH)
                songs.append({
                    "title": file,
                    "path": rel_path
                })
    return jsonify(songs)

@app.route('/file/<path:filename>')
def get_file(filename):
    # Decodificar el nombre del archivo para soportar espacios y caracteres especiales
    decoded_path = urllib.parse.unquote(filename)
    return send_from_directory(MUSIC_PATH, decoded_path)

if __name__ == '__main__':
    print(f"--- Servidor Sonaura Iniciado ---")
    print(f"Escuchando en puerto 5050...")
    # Escucha en 0.0.0.0 para que sea accesible vía Tailscale
    app.run(host='0.0.0.0', port=5050, debug=False)
