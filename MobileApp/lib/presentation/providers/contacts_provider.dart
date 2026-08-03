import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class AppContact {
  final String id;
  final String name;
  final String phone;
  bool isFavorite;
  final String? photo;

  AppContact({
    required this.id,
    required this.name,
    required this.phone,
    this.isFavorite = false,
    this.photo,
  });
}

class ContactsState {
  final List<AppContact> contacts;
  final bool isLoading;
  final bool hasPermission;
  final String? error;

  const ContactsState({
    this.contacts = const [],
    this.isLoading = true,
    this.hasPermission = false,
    this.error,
  });
}

class ContactsNotifier extends StateNotifier<ContactsState> {
  ContactsNotifier() : super(const ContactsState()) {
    loadContacts();
  }

  Future<void> loadContacts() async {
    state = const ContactsState(isLoading: true);
    try {
      var status = await Permission.contacts.status;
      if (!status.isGranted) {
        try {
          status = await Permission.contacts.request();
        } catch (_) {}
      }

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) {
          openAppSettings();
        }
        state = const ContactsState(
          isLoading: false,
          hasPermission: false,
          error: 'Contacts permission denied. Please allow contacts access in Settings.',
        );
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final appContacts = contacts
          .where((c) => c.phones.isNotEmpty)
          .map((c) => AppContact(
                id: c.id,
                name: c.displayName.isNotEmpty ? c.displayName : 'Unknown',
                phone: c.phones.first.number,
                isFavorite: c.isStarred,
              ))
          .toList();

      appContacts.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      state = ContactsState(
        contacts: appContacts,
        isLoading: false,
        hasPermission: true,
      );
    } catch (e) {
      state = ContactsState(
        isLoading: false,
        hasPermission: false,
        error: e.toString(),
      );
    }
  }

  void toggleFavorite(String id) {
    final updated = state.contacts.map((c) {
      if (c.id == id) c.isFavorite = !c.isFavorite;
      return c;
    }).toList();
    state = ContactsState(contacts: updated, isLoading: false, hasPermission: true);
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>((ref) {
  return ContactsNotifier();
});
