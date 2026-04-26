import 'package:flutter/material.dart';
import '../models/album_model.dart';
import 'sonaura_style.dart';

class AlbumResultsScreen extends StatelessWidget {
  final List<SonauraAlbum> albums;
  final String appId;
  final String appSecret;
  final String token;

  const AlbumResultsScreen({super.key, required this.albums, required this.appId, required this.appSecret, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("DISCOGRAFÍA ENCONTRADA", style: TextStyle(fontSize: 10, letterSpacing: 2))),
      body: GridView.builder(
        padding: const EdgeInsets.all(25),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 20, mainAxisSpacing: 20),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(image: NetworkImage(album.coverUrl), fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(album.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(album.artist.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
            ],
          );
        },
      ),
    );
  }
}
