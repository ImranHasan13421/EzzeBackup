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

  // Palette of avatar gradient colors for visual richness
  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF4F46E5), Color(0xFF7C3AED)], // Indigo to Purple
    [Color(0xFF06B6D4), Color(0xFF3B82F6)], // Cyan to Blue
    [Color(0xFF10B981), Color(0xFF059669)], // Emerald
    [Color(0xFFF59E0B), Color(0xFFD97706)], // Amber
    [Color(0xFFEC4899), Color(0xFFDB2777)], // Pink
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Violet
  ];

  List<Color> _getGradientForName(String name) {
    if (name.isEmpty) return _avatarGradients[0];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return _avatarGradients[hash % _avatarGradients.length];
  }

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
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(next.successMessage!)),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Contact Backup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload Snapshot',
            onPressed: state.isSyncing ? null : () => notifier.loadSnapshot(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Top Control Hero Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _buildHeroCard(context, state, notifier, snapshot, isDark),
          ),

          // Search Bar & Filter Count
          if (allContacts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchBar(isDark, filteredContacts.length, allContacts.length),
            ),
            const SizedBox(height: 10),
          ],

          // Contacts List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : (snapshot == null || allContacts.isEmpty)
                    ? _buildEmptySnapshotState(isDark)
                    : filteredContacts.isEmpty
                        ? _buildNoSearchResultsState(isDark)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filteredContacts.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 8),
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

  Widget _buildHeroCard(
    BuildContext context,
    ContactBackupState state,
    ContactBackupNotifier notifier,
    dynamic snapshot,
    bool isDark,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      border: BorderSide(
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF14B8A6).withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.contacts_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            snapshot != null ? '${snapshot.contactCount} Contacts Saved' : 'No Contact Snapshot',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (snapshot != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successGreenSubtle,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      snapshot != null
                          ? 'Synced ${DateFormatter.formatReadable(DateTime.tryParse(snapshot.lastSuccessfulSyncAt))}'
                          : 'Read device contacts and store into encrypted JSON snapshot',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Reconciliation notification badge
          if (state.lastResult != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: state.lastResult!.isUpToDate
                    ? AppColors.primaryBlueSubtle
                    : AppColors.successGreenSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.lastResult!.isUpToDate
                      ? AppColors.primaryBlue.withAlpha(50)
                      : AppColors.successGreen.withAlpha(50),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.lastResult!.isUpToDate
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: state.lastResult!.isUpToDate
                        ? AppColors.primaryBlue
                        : AppColors.successGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Primary Sync Button
          AppButton(
            text: snapshot != null ? 'Update Numbers Backup' : 'Back Up All Contacts',
            icon: Icons.sync_rounded,
            variant: ButtonVariant.gradient,
            isLoading: state.isSyncing,
            onPressed: () => notifier.syncContacts(),
          ),

          // PDF and JSON export actions
          if (snapshot != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Preview PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    variant: ButtonVariant.secondary,
                    onPressed: () => context.push('/contact-pdf-preview'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    text: 'Export JSON',
                    icon: Icons.data_object_rounded,
                    variant: ButtonVariant.outline,
                    isLoading: state.isExporting,
                    onPressed: () => notifier.exportJson(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, int filteredCount, int totalCount) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or email...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary.withAlpha(140) : AppColors.lightTextSecondary.withAlpha(140),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 14),
              ),
            ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryBlueSubtle,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$filteredCount',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactListItem(ContactRecord c, bool isDark) {
    final gradient = _getGradientForName(c.displayName);

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled Initials Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withAlpha(50),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              c.displayName.isNotEmpty ? c.displayName.characters.first.toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Contact details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.displayName.isNotEmpty ? c.displayName : 'Unnamed Contact',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c.organization != null && c.organization!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueSubtle,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.organization!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),

                // Phone numbers row
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c.primaryPhone.isNotEmpty ? c.primaryPhone : 'No phone number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (c.alternativePhone.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.alternativePhone,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Email row if available
                if (c.primaryEmail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c.primaryEmail,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildEmptySnapshotState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF14B8A6).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_outlined,
                size: 40,
                color: Color(0xFF14B8A6),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Contact Snapshot Found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Back Up All Contacts" above to read device contacts and create an encrypted local snapshot with PDF and JSON exports.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? AppColors.darkTextSecondary.withAlpha(100) : AppColors.lightTextSecondary.withAlpha(100),
            ),
            const SizedBox(height: 14),
            Text(
              'No contacts match "$_searchQuery"',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with a different name, phone number, or email.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
