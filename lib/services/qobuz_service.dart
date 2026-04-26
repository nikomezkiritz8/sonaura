import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/track_model.dart';
import '../models/album_model.dart';

class QobuzService {
  final String appId;
  final String appSecret;
  final String userAuthToken;

  QobuzService({required this.appId, required this.appSecret, required this.userAuthToken});

  http.Client get _directClient {
    final ioc = HttpClient();
    ioc.findProxy = (uri) => "DIRECT";
    return IOClient(ioc);
  }

  Future<List<SonauraTrack>> search(String query) async {
    try {
      final url = 'https://www.qobuz.com/api.json/0.2/track/search?query=${Uri.encodeComponent(query)}&limit=50';
      final response = await _directClient.get(Uri.parse(url), headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['tracks'] != null) return (data['tracks']['items'] as List).map((item) => SonauraTrack.fromJson(item)).toList();
      }
    } catch (e) { print("Error Search: $e"); }
    return [];
  }

  Future<List<SonauraAlbum>> searchAlbums(String query) async {
    try {
      final url = 'https://www.qobuz.com/api.json/0.2/album/search?query=${Uri.encodeComponent(query)}&limit=50';
      final response = await _directClient.get(Uri.parse(url), headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['albums'] != null) return (data['albums']['items'] as List).map((item) => SonauraAlbum.fromJson(item)).toList();
      }
    } catch (e) { print("Error Album: $e"); }
    return [];
  }

  Future<String?> getHiResStreamUrl(String trackId) async {
    final String ts = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final String sig = md5.convert(utf8.encode("trackgetFileUrlformat_id27intentstreamtrack_id${trackId}${ts}${appSecret}")).toString();
    try {
      final url = 'https://www.qobuz.com/api.json/0.2/track/getFileUrl?track_id=$trackId&format_id=27&intent=stream&request_ts=$ts&request_sig=$sig';
      final response = await _directClient.get(Uri.parse(url), headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId});
      if (response.statusCode == 200) return jsonDecode(response.body)['url'];
    } catch (e) { print("Error Stream: $e"); }
    return null;
  }
  
  Future<List<SonauraTrack>> getAlbumTracks(String albumId) async {
    try {
      final response = await _directClient.get(Uri.parse('https://www.qobuz.com/api.json/0.2/album/get?album_id=$albumId'), headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? cover = data['image'] != null ? data['image']['large'] : null;
        if (data['tracks'] != null) return (data['tracks']['items'] as List).map((item) => SonauraTrack.fromJson(item, defaultCover: cover)).toList();
      }
    } catch (e) { print("Error Album Tracks: $e"); }
    return [];
  }
}
