class OfflineThemeDownload {
  const OfflineThemeDownload({
    required this.userId,
    required this.themeId,
    required this.areaSlug,
    required this.themeName,
    required this.fileName,
    required this.localPath,
    required this.byteSize,
    required this.downloadedAt,
  });

  final String userId;
  final String themeId;
  final String areaSlug;
  final String themeName;
  final String fileName;
  final String localPath;
  final int byteSize;
  final DateTime downloadedAt;
}

class OfflineStorageSummary {
  const OfflineStorageSummary({required this.count, required this.totalBytes});

  final int count;
  final int totalBytes;

  factory OfflineStorageSummary.fromDownloads(
    List<OfflineThemeDownload> downloads,
  ) => OfflineStorageSummary(
    count: downloads.length,
    totalBytes: downloads.fold<int>(
      0,
      (total, download) => total + download.byteSize,
    ),
  );
}

String formatStorageSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  final megabytes = kilobytes / 1024;
  if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
  return '${(megabytes / 1024).toStringAsFixed(1)} GB';
}
