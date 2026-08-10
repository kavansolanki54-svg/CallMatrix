import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionGuardService {
  /// All required permissions: Call Logs, Contacts, Music & Audio, Notifications, Phone, Display Over Other Apps
  static const List<Permission> _requiredPermissions = [
    Permission.phone,
    Permission.contacts,
    Permission.audio,
    Permission.notification,
    Permission.systemAlertWindow,
  ];

  /// Check if all required permissions are granted
  static Future<bool> checkPermissionsGranted() async {
    for (final perm in _requiredPermissions) {
      final status = await perm.status;
      if (!status.isGranted) {
        return false;
      }
    }
    return true;
  }

  /// Request all required permissions
  static Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await _requiredPermissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  /// Show mandatory permissions dialog. Returns true if user granted all permissions.
  static Future<bool> ensurePermissionsOrShowModal(BuildContext context) async {
    final granted = await checkPermissionsGranted();
    if (granted) return true;

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User cannot dismiss without action
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.security_rounded, color: Colors.cyan, size: 28),
                SizedBox(width: 10),
                Text(
                  'Permissions Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To use Callalyze, you MUST grant all permissions below. The app will NOT sync calls without them:',
                    style: TextStyle(fontSize: 14, height: 1.4, color: Colors.white70),
                  ),
                  SizedBox(height: 14),
                  _PermissionItem(
                    icon: Icons.phone_callback_rounded,
                    title: 'Call Logs',
                    subtitle: 'Read phone call history & duration',
                  ),
                  SizedBox(height: 8),
                  _PermissionItem(
                    icon: Icons.contacts_rounded,
                    title: 'Contacts',
                    subtitle: 'Match phone numbers with client names',
                  ),
                  SizedBox(height: 8),
                  _PermissionItem(
                    icon: Icons.audiotrack_rounded,
                    title: 'Music & Audio',
                    subtitle: 'Access call recording files',
                  ),
                  SizedBox(height: 8),
                  _PermissionItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifications',
                    subtitle: 'Background sync & call alerts',
                  ),
                  SizedBox(height: 8),
                  _PermissionItem(
                    icon: Icons.phone_rounded,
                    title: 'Phone',
                    subtitle: 'Detect live call state (Ringing, Offhook, Idle)',
                  ),
                  SizedBox(height: 8),
                  _PermissionItem(
                    icon: Icons.layers_rounded,
                    title: 'Display Over Other Apps',
                    subtitle: 'Show summary popup',
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Access is blocked until all permissions are allowed.',
                    style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                },
                child: const Text('Open Settings', style: TextStyle(color: Colors.cyan)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final isGrantedNow = await requestAllPermissions();
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop(isGrantedNow);
                  }
                },
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.cyan, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade300)),
            ],
          ),
        ),
      ],
    );
  }
}
