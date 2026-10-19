class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message ${code != null ? '($code)' : ''}';
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.details});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.details});
}

class ZipException extends AppException {
  const ZipException(super.message, {super.code, super.details});
}

class ContactException extends AppException {
  const ContactException(super.message, {super.code, super.details});
}

class PdfException extends AppException {
  const PdfException(super.message, {super.code, super.details});
}
