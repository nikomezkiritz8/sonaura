class LyricLine {
  final Duration time;
  final String text;
  LyricLine({required this.time, required this.text});
}

class SonauraLyrics {
  final List<LyricLine> lines;
  SonauraLyrics(this.lines);

  factory SonauraLyrics.parse(String lrcContent) {
    List<LyricLine> lines = [];
    // Regex mejorada para capturar tiempos como [00:12.34] o [00:12:34]
    final RegExp regExp = RegExp(r'\[(\d{2}):(\d{2})[\.:](\d{2,3})\](.*)');
    
    for (String line in lrcContent.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final text = match.group(4)!.trim();
        if (text.isNotEmpty) {
          lines.add(LyricLine(
            time: Duration(minutes: min, seconds: sec),
            text: text
          ));
        }
      }
    }
    return SonauraLyrics(lines);
  }
}
