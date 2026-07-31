/// Model classes cho Edge TTS metadata, dùng cho word highlighting khi phát offline audio.
class EdgeMetadataChunk {
  final String type;
  final int offset;
  final int duration;
  final String text;

  EdgeMetadataChunk({
    required this.type,
    required this.offset,
    required this.duration,
    required this.text,
  });
}
