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
        title: const Text('Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D2939),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(contactsProvider.notifier).loadContacts(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: Colors.blueGrey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF465FFF)),
                filled: true,
                fillColor: const Color(0xFF1D2939),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20, color: Colors.white70),
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
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF465FFF)))
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
                            color: const Color(0xFF465FFF),
                            child: ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    '${filtered.length} contacts',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey.shade300,
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
                                  const SizedBox(height: 8),
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
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.blueGrey.shade300,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF465FFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF465FFF)),
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
    final colors = [const Color(0xFF465FFF), Colors.teal, Colors.blue, Colors.orange, Colors.purple];
    final color = colors[contact.name.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: const Color(0xFF1D2939),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.15),
          child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          contact.phone,
          style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade300),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onFavoriteToggle,
              child: Icon(
                contact.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: contact.isFavorite ? Colors.orange : Colors.blueGrey.shade400,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:${contact.phone}')),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.call_rounded, color: Colors.green, size: 18),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('sms:${contact.phone}')),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.message_rounded, color: Colors.blue, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
