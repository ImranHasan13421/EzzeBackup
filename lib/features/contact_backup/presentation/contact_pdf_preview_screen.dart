import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/service_providers.dart';
import 'contact_backup_controller.dart';

class ContactPdfPreviewScreen extends ConsumerWidget {
  const ContactPdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactState = ref.watch(contactBackupProvider);
    final snapshot = contactState.snapshot;
    final pdfService = ref.read(pdfServiceProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (snapshot == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Contact Directory PDF'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.errorRed, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Contact Snapshot Available',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please back up contacts first to generate the printable directory PDF.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Contact Directory PDF'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final exported = await ref.read(contactBackupProvider.notifier).exportPdf(context);
                if (context.mounted && exported != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Saved PDF to: ${exported.path}')),
                        ],
                      ),
                      backgroundColor: AppColors.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandStart.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.save_alt_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Save PDF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfService.generateContactPdfBytes(snapshot),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'EzzeBackup_Contacts_${snapshot.contactCount}.pdf',
        previewPageMargin: const EdgeInsets.all(12),
        scrollViewDecoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
        ),
      ),
    );
  }
}
