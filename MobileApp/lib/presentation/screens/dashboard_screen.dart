import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/home_provider.dart';
import '../../core/utils/formatters.dart';
import '../../services/permission_guard_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  const DashboardScreen({super.key, required this.onLogout});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Run auto permission check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionGuardService.ensurePermissionsOrShowModal(context);
    });
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    final count = await ref.read(homeProvider.notifier).syncAndReload();
    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('$count call logs successfully synchronized'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF465FFF), Color(0xFF7A5AF8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'CM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'CallMatrix',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1D2939),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: stats.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF465FFF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Executive Gradient Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF465FFF), Color(0xFF7A5AF8), Color(0xFF9333EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF465FFF).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Device Telemetry',
                              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Approved',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Agent Call Sync',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Background call recording & sync enabled',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 24),

                  // Metrics Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.phone_in_talk,
                          value: stats.totalCalls.toString(),
                          label: 'Total Calls',
                          iconColor: const Color(0xFF465FFF),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.timer_rounded,
                          value: Formatters.duration(stats.totalDuration),
                          label: 'Total Duration',
                          iconColor: Colors.teal,
                        ),
                      ),
                    ],
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.people_alt_rounded,
                          value: stats.uniqueContacts.toString(),
                          label: 'Unique Contacts',
                          iconColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.call_missed_rounded,
                          value: stats.missedCalls.toString(),
                          label: 'Today Missed',
                          iconColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 28),

                  // Sync Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _triggerSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(
                        _isSyncing ? 'Syncing Logs...' : 'Sync Call Logs Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF465FFF),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFF465FFF).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ).animate(delay: 300.ms).fadeIn().scale(),

                  const SizedBox(height: 28),

                  // Top Contacts list
                  if (stats.topContacts.isNotEmpty) ...[
                    const Text(
                      'TOP CONTACTS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.topContacts.length,
                      itemBuilder: (context, i) {
                        final contact = stats.topContacts[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D2939),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.contactName.isNotEmpty ? contact.contactName : contact.phoneNumber,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    contact.phoneNumber,
                                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.call_rounded, color: Colors.blueGrey.shade400, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${contact.totalCalls} calls',
                                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ).animate(delay: 400.ms).fadeIn(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1D2939),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
