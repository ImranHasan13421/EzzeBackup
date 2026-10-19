import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../core/constants/storage_constants.dart';
import '../core/errors/app_exceptions.dart';
import '../core/utils/date_formatter.dart';
import '../models/backup_record.dart';
import '../models/contact_snapshot.dart';
import 'backup_history_service.dart';
import 'storage_service.dart';

class PdfService {
  final StorageService _storageService;
  final BackupHistoryService _historyService;

  pw.Font? _cachedBengaliFont;
  pw.Font? _cachedRobotoFont;

  PdfService({
    required StorageService storageService,
    required BackupHistoryService historyService,
  })  : _storageService = storageService,
        _historyService = historyService;

  Future<void> _loadFonts() async {
    if (_cachedBengaliFont != null && _cachedRobotoFont != null) return;
    try {
      final bengaliBytes = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      _cachedBengaliFont = pw.Font.ttf(bengaliBytes);

      final robotoBytes = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      _cachedRobotoFont = pw.Font.ttf(robotoBytes);
    } catch (e) {
      // Fallback to standard PDF font if asset loading fails
      _cachedBengaliFont = pw.Font.helvetica();
      _cachedRobotoFont = pw.Font.helvetica();
    }
  }

  /// Builds the complete PDF document bytes from the active contact snapshot
  Future<Uint8List> generateContactPdfBytes(ContactSnapshot snapshot) async {
    await _loadFonts();

    final doc = pw.Document(
      title: 'Ezze Backup — Contact Directory',
      author: 'Ezze Backup',
      creator: 'Ezze Backup v1.0',
    );

    final bengaliFont = _cachedBengaliFont!;
    final robotoFont = _cachedRobotoFont!;

    final theme = pw.ThemeData.withFont(
      base: bengaliFont,
      bold: bengaliFont,
      fontFallback: [robotoFont],
    );

    final exportDateStr = DateFormatter.formatReadable(DateTime.now());
    final snapshotDateStr = DateFormatter.formatReadable(DateTime.tryParse(snapshot.updatedAt));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        theme: theme,
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.blue800, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EZZE BACKUP — CONTACT DIRECTORY',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Total Contacts: ${snapshot.contacts.length}  •  Snapshot: $snapshotDateStr  •  Exported: $exportDateStr',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.blue300, width: 0.5),
                  ),
                  child: pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 12),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Ezze Backup  •  Confidential Personal Directory',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            _buildContactsTable(snapshot),
          ];
        },
      ),
    );

    return await doc.save();
  }

  pw.Widget _buildContactsTable(ContactSnapshot snapshot) {
    final headers = ['Name', 'Phone Number', 'Alternative Phone', 'Email'];

    final tableRows = <pw.TableRow>[
      // Table Header Row
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blue900),
        children: headers.map((h) {
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(
              h,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          );
        }).toList(),
      ),
    ];

    for (int i = 0; i < snapshot.contacts.length; i++) {
      final c = snapshot.contacts[i];
      final isEven = i % 2 == 0;
      final rowColor = isEven ? PdfColors.white : PdfColors.grey100;

      // Primary row
      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowColor),
          children: [
            // Name column
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    c.displayName,
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                  ),
                  if (c.organization != null && c.organization!.trim().isNotEmpty)
                    pw.Text(
                      c.organization!,
                      style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                    ),
                ],
              ),
            ),
            // Primary Phone
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                c.primaryPhone.isNotEmpty ? c.primaryPhone : '—',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            // Alternative Phone
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                c.alternativePhone.isNotEmpty ? c.alternativePhone : '—',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
            // Primary Email
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(
                c.primaryEmail.isNotEmpty ? c.primaryEmail : '—',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),
          ],
        ),
      );

      // Continuation row for additional numbers or emails (preserving all data)
      final hasExtraPhones = c.extraPhones.isNotEmpty;
      final hasExtraEmails = c.extraEmails.isNotEmpty;
      if (hasExtraPhones || hasExtraEmails) {
        final extraPhoneText = c.extraPhones.map((p) => '${p.number} (${p.label})').join(', ');
        final extraEmailText = c.extraEmails.map((e) => e.address).join(', ');

        tableRows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: rowColor),
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(left: 12, right: 6, bottom: 4),
                child: pw.Text(
                  '↳ Extra details:',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.blue800),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: pw.Text(
                  extraPhoneText.isNotEmpty ? extraPhoneText : '—',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                ),
              ),
              pw.Container(),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: pw.Text(
                  extraEmailText.isNotEmpty ? extraEmailText : '—',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                ),
              ),
            ],
          ),
        );
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.0),
        1: pw.FlexColumnWidth(2.3),
        2: pw.FlexColumnWidth(2.3),
        3: pw.FlexColumnWidth(2.4),
      },
      children: tableRows,
    );
  }

  /// Exports the contact PDF directly to the configured user-accessible storage
  /// (e.g. "Ezze Backup/Contacts/Contacts_2026-10-19_211500.pdf").
  Future<File> exportPdfToSharedStorage(ContactSnapshot snapshot) async {
    try {
      final pdfBytes = await generateContactPdfBytes(snapshot);
      final contactsDir = await _storageService.getCategoryExportDir(StorageConstants.contactsFolder);
      final exportFile = await _storageService.generateUniqueExportFile(
        directory: contactsDir,
        prefix: 'Contacts',
        extension: 'pdf',
      );

      await exportFile.writeAsBytes(pdfBytes, flush: true);

      // Record in history
      await _historyService.insertRecord(
        BackupRecord(
          backupType: BackupType.contactPdf,
          category: 'Contacts',
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
          destination: exportFile.path,
          filename: exportFile.path.split(Platform.pathSeparator).last,
          itemCount: snapshot.contacts.length,
          inputSize: snapshot.contacts.length * 150,
          outputSize: pdfBytes.length,
          status: BackupStatus.completed,
          errorSummary: null,
        ),
      );

      return exportFile;
    } catch (e) {
      throw PdfException('Failed to generate or export PDF: $e', details: e);
    }
  }
}
