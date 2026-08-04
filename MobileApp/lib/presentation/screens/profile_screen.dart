import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../../core/storage/preferences_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _apiKeyController = TextEditingController();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadCustomApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomApiKey() async {
    final key = await _storage.read(key: 'gemini_api_key');
    if (key != null && key.isNotEmpty) {
      _apiKeyController.text = key;
    }
  }

  Future<void> _saveCustomApiKey(String val) async {
    await _storage.write(key: 'gemini_api_key', value: val.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gemini API key saved locally')),
      );
    }
  }

  Future<void> _pickCustomFolder(PreferencesService service) async {
    try {
      String? result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        await service.setCustomRecordingPath(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Recording scan folder updated to: $result')),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _pickProfileImage(PreferencesService service) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await service.setProfileImagePath(path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully')),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final prefs = ref.watch(preferencesProvider);
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        title: const Text('Profile Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D2939),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User identity card
            if (user != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D2939),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _pickProfileImage(ref.read(preferencesProvider)),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: const Color(0xFF465FFF).withOpacity(0.2),
                            backgroundImage: prefs.profileImagePath.isNotEmpty && File(prefs.profileImagePath).existsSync()
                                ? FileImage(File(prefs.profileImagePath))
                                : null,
                            child: prefs.profileImagePath.isNotEmpty && File(prefs.profileImagePath).existsSync()
                                ? null
                                : Text(
                                    user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: Color(0xFF465FFF), fontWeight: FontWeight.bold, fontSize: 26),
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF465FFF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.userName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Employee ID: ${user.employeeId}',
                            style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Gemini API settings
            _buildSectionTitle('Gemini Integration'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2939),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Override Gemini API Key',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optionally add your custom Gemini key to override the default credentials.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter API Key...',
                      hintStyle: TextStyle(color: Colors.blueGrey.shade400),
                      filled: true,
                      fillColor: const Color(0xFF0C111D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _saveCustomApiKey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Scan settings
            _buildSectionTitle('Call Recording Folder'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2939),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom Recording Path',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Specify a custom directory to search for recording files generated by your phone dialer.',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => _pickCustomFolder(ref.read(preferencesProvider)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C111D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              prefs.customRecordingPath.isNotEmpty ? prefs.customRecordingPath : 'Default storage directories',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.folder_open_rounded, color: Color(0xFF465FFF), size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout card
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text(
                  'Sign Out Account',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.blueGrey.shade400,
      ),
    );
  }
}
