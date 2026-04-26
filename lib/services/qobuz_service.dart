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

  // BUSCAR CANCIONES (TRACKS)
  Future<List<SonauraTrack>> search(String query) async {
    try {
      final response = await _directClient.get(
        Uri.parse('https://www.qobuz.com/api.json/0.2/track/search?query=$query&limit=20'),
        headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List items = data['tracks']['items'];
        return items.map((item) => SonauraTrack.fromJson(item)).toList();
      }
    } catch (e) { print("Error: $e"); }
    return [];
  }

  // BUSCAR ÁLBUMES (NUEVO)
  Future<List<SonauraAlbum>> searchAlbums(String query) async {
    try {
      final response = await _directClient.get(
        Uri.parse('https://www.qobuz.com/api.json/0.2/album/search?query=$query&limit=20'),
        headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List items = data['albums']['items'];
        return items.map((item) => SonauraAlbum.fromJson(item)).toList();
      }
    } catch (e) { print("Error Álbumes: $e"); }
    return [];
  }

  Future<String?> getHiResStreamUrl(String trackId) async {
    final String timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    const String formatId = "27";
    const String intent = "stream";
    final String signatureInput = "trackgetFileUrlformat_id${formatId}intent${intent}track_id${trackId}${timestamp}${appSecret}";
    final String requestSig = md5.convert(utf8.encode(signatureInput)).toString();
    try {
      final url = 'https://www.qobuz.com/api.json/0.2/track/getFileUrl?track_id=$trackId&format_id=$formatId&intent=$intent&request_ts=$timestamp&request_sig=$requestSig';
      final response = await _directClient.get(Uri.parse(url), headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId});
      if (response.statusCode == 200) return jsonDecode(response.body)['url'];
    } catch (e) { print("Error Stream: $e"); }
    return null;
  }
}
