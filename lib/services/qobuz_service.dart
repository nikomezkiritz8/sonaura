import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/track_model.dart';

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
      final response = await _directClient.get(
        Uri.parse('https://www.qobuz.com/api.json/0.2/track/search?query=$query&limit=20'),
        headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['tracks'] != null) {
          List items = data['tracks']['items'];
          return items.map((item) => SonauraTrack.fromJson(item)).toList();
        }
      }
    } catch (e) { print("Sonaura Search Error: $e"); }
    return [];
  }

  Future<String?> getHiResStreamUrl(String trackId) async {
    final String timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    const String formatId = "27"; // Hi-Res FLAC
    const String intent = "stream";

    // FIRMA EXACTA: método (sin barras) + parámetros ordenados + timestamp + app_secret
    // Parámetros a incluir: format_id, intent, track_id
    final String signatureInput = "trackgetFileUrlformat_id${formatId}intent${intent}track_id${trackId}${timestamp}${appSecret}";
    final String requestSig = md5.convert(utf8.encode(signatureInput)).toString();

    try {
      final url = 'https://www.qobuz.com/api.json/0.2/track/getFileUrl?'
          'track_id=$trackId&format_id=$formatId&intent=$intent&request_ts=$timestamp&request_sig=$requestSig';
      
      final response = await _directClient.get(
        Uri.parse(url),
        headers: {'x-user-auth-token': userAuthToken, 'x-app-id': appId},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url']; // Aquí llega la URL del FLAC
      } else {
        print("Qobuz API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) { print("Sonaura Stream Error: $e"); }
    return null;
  }
}
