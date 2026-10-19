import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/contact_record.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import 'contact_backup_controller.dart';

class ContactBackupScreen extends ConsumerStatefulWidget {
  const ContactBackupScreen({super.key});

  @override
  ConsumerState<ContactBackupScreen> createState() => _ContactBackupScreenState();
}

class _ContactBackupScreenState extends ConsumerState<ContactBackupScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactBackupProvider);
    final notifier = ref.read(contactBackupProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<ContactBackupState>(contactBackupProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    });

    final snapshot = state.snapshot;
    final allContacts = snapshot?.contacts ?? [];
    final filteredContacts = _searchQuery.trim().isEmpty
        ? allContacts
        : allContacts.where((c) {
            final q = _searchQuery.toLowerCase();
            final name = c.displayName.toLowerCase();
            final phone = c.primaryPhone.toLowerCase();
            final alt = c.alternativePhone.toLowerCase();
            final email = c.primaryEmail.toLowerCase();
            return name.contains(q) || phone.contains(q) || alt.contains(q) || email.contains(q);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Backup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Snapshot',
            onPressed: state.isSyncing ? null : () => notifier.loadSnapshot(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Control Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              border: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.contacts_rounded, color: AppColors.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot != null ? '${snapshot.contactCount} Contacts Backed Up' : 'No Contact Backup Yet',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              snapshot != null
                                  ? 'Last sync: ${DateFormatter.formatReadable(DateTime.tryParse(snapshot.lastSuccessfulSyncAt))}'
                                  : 'Tap below to read device contacts and create JSON snapshot.',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Reconciliation Summary if present
                  if (state.lastResult != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: state.lastResult!.isUpToDate
                            ? AppColors.primaryBlueSubtle
                            : AppColors.successGreenSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.lastResult!.summaryMessage,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: state.lastResult!.isUpToDate
                              ? AppColors.primaryBlue
                              : AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: snapshot != null ? 'Update Numbers Backup' : 'Back Up All Contacts',
                          icon: Icons.sync_rounded,
                          isLoading: state.isSyncing,
                          onPressed: () => notifier.syncContacts(),
                        ),
                      ),
                    ],
                  ),
                  if (snapshot != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Preview PDF',
                            icon: Icons.picture_as_pdf_outlined,
                            variant: ButtonVariant.secondary,
                            onPressed: () => context.push('/contact-pdf-preview'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            text: 'Export JSON',
                            icon: Icons.download_rounded,
                            variant: ButtonVariant.outline,
                            isLoading: state.isExporting,
                            onPressed: () => notifier.exportJson(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Search Field
          if (allContacts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts by name, phone, or email...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Contacts List View
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : (snapshot == null || allContacts.isEmpty)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search_outlined,
                                size: 56,
                                color: isDark
                                    ? AppColors.darkTextSecondary.withAlpha(100)
                                    : AppColors.lightTextSecondary.withAlpha(100),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No Contacts Snapshot Found',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap "Back Up All Contacts" to read device contacts and create your encrypted local snapshot.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: filteredContacts.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final c = filteredContacts[index];
                          return _buildContactListItem(c, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactListItem(ContactRecord c, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryBlue.withAlpha(25),
            child: Text(
              c.displayName.isNotEmpty ? c.displayName.characters.first.toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (c.organization != null && c.organization!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    c.organization!,
                    style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      c.primaryPhone.isNotEmpty ? c.primaryPhone : 'No phone',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (c.alternativePhone.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Alt: ${c.alternativePhone}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
                if (c.primaryEmail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        c.primaryEmail,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
