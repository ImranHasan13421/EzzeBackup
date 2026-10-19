class ManifestEntry {
  final String relativePath;
  final int originalSizeBytes;
  final String? modifiedAt;
  final String? sha256;

  const ManifestEntry({
    required this.relativePath,
    required this.originalSizeBytes,
    this.modifiedAt,
    this.sha256,
  });

  Map<String, dynamic> toJson() {
    return {
      'relativePath': relativePath,
      'originalSizeBytes': originalSizeBytes,
      if (modifiedAt != null) 'modifiedAt': modifiedAt,
      if (sha256 != null) 'sha256': sha256,
    };
  }

  factory ManifestEntry.fromJson(Map<String, dynamic> json) {
    return ManifestEntry(
      relativePath: json['relativePath'] as String? ?? '',
      originalSizeBytes: json['originalSizeBytes'] as int? ?? 0,
      modifiedAt: json['modifiedAt'] as String?,
      sha256: json['sha256'] as String?,
    );
  }
}

class BackupManifest {
  final String appName;
  final int archiveFormatVersion;
  final String createdAt;
  final String category;
  final int totalFiles;
  final int totalInputBytes;
  final List<ManifestEntry> entries;

  const BackupManifest({
    this.appName = 'Ezze Backup',
    this.archiveFormatVersion = 1,
    required this.createdAt,
    required this.category,
    required this.totalFiles,
    required this.totalInputBytes,
    required this.entries,
  });

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'archiveFormatVersion': archiveFormatVersion,
      'createdAt': createdAt,
      'category': category,
      'totalFiles': totalFiles,
      'totalInputBytes': totalInputBytes,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    return BackupManifest(
      appName: json['appName'] as String? ?? 'Ezze Backup',
      archiveFormatVersion: json['archiveFormatVersion'] as int? ?? 1,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      category: json['category'] as String? ?? 'Files',
      totalFiles: json['totalFiles'] as int? ?? 0,
      totalInputBytes: json['totalInputBytes'] as int? ?? 0,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => ManifestEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
