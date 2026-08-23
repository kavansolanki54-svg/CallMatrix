import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/home_provider.dart';
import '../providers/history_provider.dart';
import '../../core/utils/formatters.dart';
import '../../services/permission_guard_service.dart';
import '../../services/native_call_sync_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;
  const DashboardScreen({super.key, required this.onLogout});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isSyncing = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Run auto permission check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionGuardService.ensurePermissionsOrShowModal(context);
    });

    // Register listener for native sync completed events
    const MethodChannel('com.dallytasksheet.dally_task_sheet/calls')
        .setMethodCallHandler((call) async {
      if (call.method == 'onSyncComplete') {
        if (mounted) {
          // Trigger Home Stats data reload
          ref.read(homeProvider.notifier).loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Data synchronization complete')),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    // Ensure notification permission is granted (required for progress notification on Android 13+)
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      final result = await Permission.notification.request();
      if (!result.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.notifications_off, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(child: Text('Notification permission required to show sync progress')),
              ],
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSyncing = true);

    // Launch the foreground service (shows notification with progress bar)
    await NativeCallSyncService.startBackgroundSyncService();

    // Reload dashboard data after a short delay to let sync start
    await Future.delayed(const Duration(seconds: 2));
    await ref.read(homeProvider.notifier).loadData();

    setState(() => _isSyncing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.sync_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Sync started — check notification for progress')),
            ],
          ),
          backgroundColor: const Color(0xFF0070F3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0070F3),
              onPrimary: Colors.white,
              surface: Color(0xFF1D2939),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // In real app, we might reload data for the selected date.
      // Keeping original BLL logic, but updating local UI state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C111D),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: Colors.blueGrey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.blueGrey.shade400,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _isSyncing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF0070F3),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.sync_rounded, color: Colors.white),
                  tooltip: 'Sync Now',
                  onPressed: _triggerSync,
                ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: stats.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0070F3)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Executive Gradient Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0070F3), Color(0xFF7A5AF8), Color(0xFF9333EA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0070F3).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
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
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Approved',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Background call recording & sync enabled',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
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
                          icon: Icons.phone_in_talk_rounded,
                          value: stats.totalCalls.toString(),
                          label: 'Total Calls',
                          subtitle: 'All synced items',
                          iconColor: const Color(0xFF0070F3),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.timer_rounded,
                          value: Formatters.duration(stats.totalDuration),
                          label: 'Total Duration',
                          subtitle: 'Talking telemetry',
                          iconColor: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.check_circle_outline_rounded,
                          value: '${stats.answerRate.toStringAsFixed(1)}%',
                          label: 'Answer Rate',
                          subtitle: 'Call efficiency',
                          iconColor: const Color(0xFFEAB308),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.call_missed_rounded,
                          value: stats.missedCalls.toString(),
                          label: 'Today Missed',
                          subtitle: 'Awaiting callback',
                          iconColor: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // Trend Line Chart
                  _buildTrendChart(stats.recentCalls),

                  const SizedBox(height: 24),

                  // Donut Chart
                  _buildDonutChart(stats.recentCalls),

                  const SizedBox(height: 24),

                  // Sync Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _triggerSync,
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(
                        _isSyncing ? 'Syncing Logs...' : 'Sync Call Logs Now',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0070F3),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF0070F3).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ).animate(delay: 300.ms).fadeIn().scale(),

                  const SizedBox(height: 28),

                  // Top Contacts list
                  if (stats.topContacts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOP CONTACTS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'by calls volume',
                          style: TextStyle(
                            color: Colors.blueGrey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stats.topContacts.length,
                      itemBuilder: (context, i) {
                        final contact = stats.topContacts[i];
                        final maxCalls = stats.topContacts.first.totalCalls;
                        final ratio = maxCalls > 0 ? contact.totalCalls / maxCalls : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D2939),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF334155).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFF0070F3).withOpacity(0.15),
                                    child: Text(
                                      contact.contactName.isNotEmpty
                                          ? contact.contactName[0].toUpperCase()
                                          : '#',
                                      style: const TextStyle(
                                        color: Color(0xFF38bdf8),
                                        fontWeight: FontWeight.bold,
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
                                          contact.contactName.isNotEmpty
                                              ? contact.contactName
                                              : contact.phoneNumber,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          contact.phoneNumber,
                                          style: TextStyle(
                                            color: Colors.blueGrey.shade400,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_rounded,
                                        color: Color(0xFF10B981),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${contact.totalCalls} calls',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Custom horizontal progress indicator matching design bars
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFF0C111D),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0070F3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).animate(delay: 400.ms).fadeIn(),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF334155).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Icon(
                Icons.arrow_upward_rounded,
                color: Colors.blueGrey.shade600,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<CallLogItem> calls) {
    // Generate dynamic chart data based on hourly call volume
    final hourlyCounts = List<int>.filled(12, 0); // 12 buckets: 2 hours each starting from 00:00 to 24:00
    for (final call in calls) {
      final hour = call.startTime.hour;
      final bucket = (hour / 2).floor();
      if (bucket >= 0 && bucket < 12) {
        hourlyCounts[bucket]++;
      }
    }

    final chartSpots = <FlSpot>[];
    for (int i = 0; i < hourlyCounts.length; i++) {
      chartSpots.add(FlSpot(i.toDouble(), hourlyCounts[i].toDouble()));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF334155).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calls Trend',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Hourly calling volume distribution',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0070F3).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    color: Color(0xFF38bdf8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: const Color(0xFF334155).withOpacity(0.15),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.blueGrey.shade400,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        const labels = ['12A', '4A', '8A', '12P', '4P', '8P'];
                        final idx = (value / 2).floor();
                        if (value % 2 == 0 && idx >= 0 && idx < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[idx],
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartSpots.isEmpty
                        ? [
                            const FlSpot(0, 1),
                            const FlSpot(2, 3),
                            const FlSpot(4, 2),
                            const FlSpot(6, 4),
                            const FlSpot(8, 3),
                            const FlSpot(10, 5)
                          ]
                        : chartSpots,
                    isCurved: true,
                    color: const Color(0xFF0070F3),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0070F3).withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonutChart(List<CallLogItem> calls) {
    int incoming = 0;
    int outgoing = 0;
    int missed = 0;

    for (final call in calls) {
      switch (call.callType.toLowerCase()) {
        case 'incoming':
          incoming++;
          break;
        case 'outgoing':
          outgoing++;
          break;
        case 'missed':
          missed++;
          break;
      }
    }

    final total = incoming + outgoing + missed;
    final incomingPct = total > 0 ? (incoming / total) * 100 : 0.0;
    final outgoingPct = total > 0 ? (outgoing / total) * 100 : 0.0;
    final missedPct = total > 0 ? (missed / total) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF334155).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Call Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          color: const Color(0xFF0070F3),
                          value: outgoing > 0 ? outgoing.toDouble() : 1,
                          title: '',
                          radius: 18,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFF10B981),
                          value: incoming > 0 ? incoming.toDouble() : 1,
                          title: '',
                          radius: 18,
                        ),
                        PieChartSectionData(
                          color: const Color(0xFFEF4444),
                          value: missed > 0 ? missed.toDouble() : 1,
                          title: '',
                          radius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      color: const Color(0xFF0070F3),
                      label: 'Outgoing',
                      percent: '${outgoingPct.toStringAsFixed(1)}%',
                      count: outgoing,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendItem(
                      color: const Color(0xFF10B981),
                      label: 'Incoming',
                      percent: '${incomingPct.toStringAsFixed(1)}%',
                      count: incoming,
                    ),
                    const SizedBox(height: 10),
                    _buildLegendItem(
                      color: const Color(0xFFEF4444),
                      label: 'Missed',
                      percent: '${missedPct.toStringAsFixed(1)}%',
                      count: missed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String percent,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          percent,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: TextStyle(
            color: Colors.blueGrey.shade400,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
