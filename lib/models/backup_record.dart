class BackupStatus {
  static const String pending = 'Pending';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
  static const String completedWithWarnings = 'Completed With Warnings';
  static const String failed = 'Failed';
  static const String cancelled = 'Cancelled';
}

class BackupType {
  static const String file = 'file';
  static const String contactJson = 'contact_json';
  static const String contactPdf = 'contact_pdf';
}

class BackupRecord {
  final int? id;
  final String backupType; // 'file', 'contact_json', 'contact_pdf'
  final String category; // 'Documents', 'Images', 'Videos', 'Audio', 'Other', 'Custom', 'Contacts'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String destination;
  final String filename;
  final int itemCount;
  final int inputSize;
  final int outputSize;
  final String status;
  final String? errorSummary;
  final int manifestVersion;

  const BackupRecord({
    this.id,
    required this.backupType,
    required this.category,
    required this.createdAt,
    this.completedAt,
    required this.destination,
    required this.filename,
    required this.itemCount,
    required this.inputSize,
    required this.outputSize,
    required this.status,
    this.errorSummary,
    this.manifestVersion = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'backup_type': backupType,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'destination': destination,
      'filename': filename,
      'item_count': itemCount,
      'input_size': inputSize,
      'output_size': outputSize,
      'status': status,
      'error_summary': errorSummary,
      'manifest_version': manifestVersion,
    };
  }

  factory BackupRecord.fromMap(Map<String, dynamic> map) {
    return BackupRecord(
      id: map['id'] as int?,
      backupType: map['backup_type'] as String? ?? 'file',
      category: map['category'] as String? ?? 'Custom',
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      destination: map['destination'] as String? ?? '',
      filename: map['filename'] as String? ?? '',
      itemCount: map['item_count'] as int? ?? 0,
      inputSize: map['input_size'] as int? ?? 0,
      outputSize: map['output_size'] as int? ?? 0,
      status: map['status'] as String? ?? BackupStatus.pending,
      errorSummary: map['error_summary'] as String?,
      manifestVersion: map['manifest_version'] as int? ?? 1,
    );
  }

  BackupRecord copyWith({
    int? id,
    String? backupType,
    String? category,
    DateTime? createdAt,
    DateTime? completedAt,
    String? destination,
    String? filename,
    int? itemCount,
    int? inputSize,
    int? outputSize,
    String? status,
    String? errorSummary,
    int? manifestVersion,
  }) {
    return BackupRecord(
      id: id ?? this.id,
      backupType: backupType ?? this.backupType,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      destination: destination ?? this.destination,
      filename: filename ?? this.filename,
      itemCount: itemCount ?? this.itemCount,
      inputSize: inputSize ?? this.inputSize,
      outputSize: outputSize ?? this.outputSize,
      status: status ?? this.status,
      errorSummary: errorSummary ?? this.errorSummary,
      manifestVersion: manifestVersion ?? this.manifestVersion,
    );
  }
}
