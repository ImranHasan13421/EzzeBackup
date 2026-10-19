import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_backup/core/errors/app_exceptions.dart';
import 'package:ezze_backup/services/zip_service.dart';

void main() {
  group('ZIP Path Sanitization and Traversal Defense Tests', () {
    test('Allows safe relative paths', () {
      expect(ZipService.sanitizeRelativePath('Documents/contract.pdf'), 'Documents/contract.pdf');
      expect(ZipService.sanitizeRelativePath('Images/Photos/holiday.jpg'), 'Images/Photos/holiday.jpg');
      expect(ZipService.sanitizeRelativePath('notes.txt'), 'notes.txt');
    });

    test('Strips leading slashes and normalizes Windows backslashes', () {
      expect(ZipService.sanitizeRelativePath(r'/Documents\report.xlsx'), 'Documents/report.xlsx');
      expect(ZipService.sanitizeRelativePath(r'\Media\Audio\song.mp3'), 'Media/Audio/song.mp3');
    });

    test('Rejects directory traversal attempts with ../', () {
      expect(
        () => ZipService.sanitizeRelativePath('../../etc/passwd'),
        throwsA(isA<ZipException>()),
      );
      expect(
        () => ZipService.sanitizeRelativePath('Documents/../../secret.key'),
        throwsA(isA<ZipException>()),
      );
      expect(
        () => ZipService.sanitizeRelativePath(r'Photos\..\..\system.dll'),
        throwsA(isA<ZipException>()),
      );
    });
  });
}
