import 'package:flutter/material.dart';
import '../services/local_music_service.dart';
import '../models/track_model.dart';
import 'sonaura_style.dart';
import 'player_screen.dart';

class LibraryScreen extends StatefulWidget {
  final String appId;
  final String appSecret;
  final String token;

  const LibraryScreen({
    super.key,
    required this.appId,
    required this.appSecret,
    required this.token,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SonauraTrack> _allTracks = [];
  List<SonauraTrack> _filteredTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    final tracks = await LocalMusicService().getLocalTracks();
    setState(() {
      _allTracks = tracks;
      _filteredTracks = tracks;
      _isLoading = false;
    });
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredTracks = _allTracks.where((track) {
        final titleLower = track.cleanTitle.toLowerCase();
        final artistLower = track.artist.toLowerCase();
        final searchLower = query.toLowerCase();
        return titleLower.contains(searchLower) || artistLower.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonauraColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "NIKO VAULT",
          style: TextStyle(fontSize: 12, letterSpacing: 5, fontWeight: FontWeight.w900, color: SonauraColors.accentGold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SonauraColors.accentGold, strokeWidth: 1))
          : CustomScrollView(
              slivers: [
                // HEADER CON TITULO Y BUSCADOR
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.only(top: 120, left: 30, right: 30, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tu Colección", style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
                        const SizedBox(height: 25),
                        
                        // BARRA DE BÚSQUEDA AUDIÓFILA
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: SonauraColors.surface,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.white10, width: 0.5),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterSearch,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            cursorColor: SonauraColors.accentGold,
                            decoration: InputDecoration(
                              hintText: "Buscar artista, álbum o canción...",
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 13, letterSpacing: 1),
                              border: InputBorder.none,
                              icon: const Icon(Icons.search, color: SonauraColors.accentGold, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white24, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterSearch("");
                                    },
                                  )
                                : null,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${_filteredTracks.length} RESULTADOS",
                              style: const TextStyle(color: SonauraColors.accentGold, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.filter_list, color: Colors.white10, size: 16),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Container(height: 0.5, color: Colors.white10),
                      ],
                    ),
                  ),
                ),
                
                // GRID DE RESULTADOS
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  sliver: _filteredTracks.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50),
                              child: Text("Sin coincidencias en el Vault", style: TextStyle(color: Colors.white10)),
                            ),
                          ),
                        )
                      : SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 25,
                            crossAxisSpacing: 25,
                            childAspectRatio: 0.72,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final track = _filteredTracks[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen(
                                    playlist: _filteredTracks,
                                    initialIndex: index,
                                    appId: widget.appId,
                                    appSecret: widget.appSecret,
                                    token: widget.token,
                                  )));
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Hero(
                                        tag: track.id,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(4),
                                            color: SonauraColors.surface,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.5),
                                                blurRadius: 15,
                                                offset: const Offset(0, 8),
                                              )
                                            ],
                                            image: DecorationImage(
                                              image: NetworkImage(track.coverUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      track.cleanTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      track.artist.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                            childCount: _filteredTracks.length,
                          ),
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}
