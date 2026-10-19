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

    if (snapshot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contact Directory PDF')),
        body: const Center(
          child: Text('No contact snapshot found to generate PDF.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Directory PDF'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt_rounded),
            tooltip: 'Save to Ezze Backup Folder',
            onPressed: () async {
              final exported = await ref.read(contactBackupProvider.notifier).exportPdf();
              if (context.mounted && exported != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Saved PDF: ${exported.path}'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfService.generateContactPdfBytes(snapshot),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: 'Contact_Directory_${snapshot.contactCount}.pdf',
      ),
    );
  }
}
