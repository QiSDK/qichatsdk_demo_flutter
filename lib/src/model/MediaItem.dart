class MediaItem {
  final String url;
  final bool isVideo;

  const MediaItem({required this.url, required this.isVideo});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem && other.url == url && other.isVideo == isVideo;

  @override
  int get hashCode => Object.hash(url, isVideo);
}
