import os
from flask import Flask, jsonify, send_from_directory, Response
from flask_cors import CORS
from mutagen.flac import FLAC
from mutagen.mp3 import MP3
from mutagen.id3 import ID3

app = Flask(__name__)
CORS(app)

MUSIC_PATH = "/run/media/koila1998/NIKO/MUSIKK"

@app.route('/list')
def list_music():
    songs = []
    if not os.path.exists(MUSIC_PATH):
        return jsonify({"error": "Disco NIKO no montado"}), 404
        
    for root, dirs, files in os.walk(MUSIC_PATH):
        for file in files:
            if file.lower().endswith(('.flac', '.mp3')):
                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, MUSIC_PATH)
                
                # VALORES POR DEFECTO
                bit_depth = 16
                sample_rate = 44100
                
                # EXTRACCIÓN DE METADATOS REALES
                try:
                    if file.lower().endswith('.flac'):
                        audio = FLAC(full_path)
                        bit_depth = audio.info.bits_per_sample
                        sample_rate = audio.info.sample_rate
                    elif file.lower().endswith('.mp3'):
                        audio = MP3(full_path)
                        sample_rate = audio.info.sample_rate
                        bit_depth = 16 # MP3 es técnicamente 16-bit
                except:
                    pass

                songs.append({
                    "title": file,
                    "path": rel_path,
                    "cover": f"art/{rel_path}",
                    "bit_depth": bit_depth,
                    "sample_rate": sample_rate // 1000 # Lo pasamos a kHz (ej: 44)
                })
    return jsonify(songs)

@app.route('/file/<path:filename>')
def get_file(filename):
    return send_from_directory(MUSIC_PATH, filename)

@app.route('/art/<path:filename>')
def get_art(filename):
    full_path = os.path.join(MUSIC_PATH, filename)
    try:
        if filename.lower().endswith('.flac'):
            audio = FLAC(full_path)
            if audio.pictures:
                return Response(audio.pictures[0].data, mimetype=audio.pictures[0].mime)
        elif filename.lower().endswith('.mp3'):
            audio = MP3(full_path, ID3=ID3)
            tags = audio.tags.getall("APIC")
            if tags:
                return Response(tags[0].data, mimetype=tags[0].mime)
    except:
        pass
    return "No art", 404

if __name__ == '__main__':
    print("--- Servidor Sonaura: Metadatos Reales Activos ---")
    app.run(host='0.0.0.0', port=5050, threaded=True)
