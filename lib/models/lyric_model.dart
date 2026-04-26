class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class SonauraLyrics {
  final List<LyricLine> lines;
  SonauraLyrics(this.lines);

  // Parsea el formato [00:12.34] Texto
  factory SonauraLyrics.parse(String lrcContent) {
    List<LyricLine> lines = [];
    final RegExp regExp = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');
    
    for (String line in lrcContent.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();
        final duration = Duration(milliseconds: (minutes * 60000 + seconds * 1000).toInt());
        lines.add(LyricLine(time: duration, text: text));
      }
    }
    return SonauraLyrics(lines);
  }
}
