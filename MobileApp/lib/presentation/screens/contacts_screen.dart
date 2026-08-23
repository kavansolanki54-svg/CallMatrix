import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/contacts_provider.dart';
import '../widgets/empty_state.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppContact> _filter(List<AppContact> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    return contacts.where((c) =>
        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        c.phone.replaceAll(' ', '').contains(_searchQuery.replaceAll(' ', ''))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsProvider);
    final filtered = _filter(contactsState.contacts);
    final favorites = filtered.where((c) => c.isFavorite).toList();
    final others = filtered.where((c) => !c.isFavorite).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C111D),
        title: const Text(
          'Contacts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.read(contactsProvider.notifier).loadContacts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0070F3), size: 18),
                filled: true,
                fillColor: const Color(0xFF1D2939),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: const Color(0xFF334155).withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF0070F3)),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Content
          Expanded(
            child: contactsState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0070F3)))
                : !contactsState.hasPermission
                    ? EmptyState(
                        icon: Icons.contacts_rounded,
                        title: 'Contacts Permission Required',
                        subtitle: contactsState.error ?? 'Grant permission to see your contacts',
                        actionLabel: 'Grant Permission',
                        onAction: () => ref.read(contactsProvider.notifier).loadContacts(),
                      )
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: Icons.person_search_rounded,
                            title: _searchQuery.isNotEmpty ? 'No results' : 'No contacts',
                            subtitle: _searchQuery.isNotEmpty
                                ? 'Try a different search term'
                                : 'Your device contacts will appear here',
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref.read(contactsProvider.notifier).loadContacts(),
                            color: const Color(0xFF0070F3),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${filtered.length} contacts found',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade400,
                                    ),
                                  ),
                                ),
                                if (favorites.isNotEmpty) ...[
                                  _SectionHeader(title: 'FAVORITES', count: favorites.length),
                                  ...favorites.asMap().entries.map((e) =>
                                    _ContactTile(
                                      contact: e.value,
                                      onFavoriteToggle: () => ref.read(contactsProvider.notifier).toggleFavorite(e.value.id),
                                    ).animate(delay: (e.key * 30).ms).fadeIn(duration: 250.ms).slideX(begin: 0.03)),
                                  const SizedBox(height: 12),
                                ],
                                _SectionHeader(title: 'ALL CONTACTS', count: others.length),
                                ...others.asMap().entries.map((e) =>
                                  _ContactTile(
                                    contact: e.value,
                                    onFavoriteToggle: () => ref.read(contactsProvider.notifier).toggleFavorite(e.value.id),
                                  ).animate(delay: ((favorites.length + e.key) * 20).ms).fadeIn(duration: 200.ms)),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.blueGrey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0070F3).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0070F3).withOpacity(0.2)),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38bdf8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final AppContact contact;
  final VoidCallback onFavoriteToggle;
  const _ContactTile({required this.contact, required this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    final initials = contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?';
    final colors = [const Color(0xFF0070F3), const Color(0xFF10B981), const Color(0xFF38BDF8), const Color(0xFFF59E0B), const Color(0xFF8B5CF6)];
    final color = colors[contact.name.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            contact.phone,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onFavoriteToggle,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  contact.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: contact.isFavorite ? const Color(0xFFF59E0B) : Colors.blueGrey.shade500,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:${contact.phone}')),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 16),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('sms:${contact.phone}')),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0070F3).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.message_rounded, color: Color(0xFF38bdf8), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
