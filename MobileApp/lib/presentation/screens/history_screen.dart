import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/api_constants.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../providers/history_provider.dart';
import 'call_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = const ['All', 'Incoming', 'Outgoing', 'Missed'];
  final _searchController = TextEditingController();
  bool _showSearch = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingUrl;
  bool _isAudioPlaying = false;
  bool _isAudioLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final filter = _tabController.index == 0 ? null : _tabs[_tabController.index];
        ref.read(historyProvider.notifier).setFilter(filter);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((pState) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = pState == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
          _playingUrl = null;
        });
      }
    });

    // Register listener for native sync completed events
    const MethodChannel('com.dallytasksheet.dally_task_sheet/calls')
        .setMethodCallHandler((call) async {
      if (call.method == 'onSyncComplete') {
        if (mounted) {
          // Trigger History data reload
          ref.read(historyProvider.notifier).loadCalls(page: 1);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(String url) async {
    final cleanPath = url.startsWith('/') ? url : '/$url';
    final fullUrl = url.startsWith('http://') || url.startsWith('https://') 
        ? url 
        : '${ApiConstants.baseUrl}$cleanPath';

    try {
      if (_playingUrl == fullUrl) {
        if (_isAudioPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.resume();
        }
      } else {
        setState(() {
          _isAudioLoading = true;
          _playingUrl = fullUrl;
        });
        
        Source source;
        if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/api/')) {
          source = UrlSource(fullUrl);
        } else {
          source = DeviceFileSource(url);
        }

        await _audioPlayer.play(source);
        setState(() {
          _isAudioLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _isAudioLoading = false;
        _playingUrl = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to play recording'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);

    // Compute dynamic stats summary based on loaded list
    final totalCount = history.calls.length;
    final incomingCount = history.calls.where((c) => c.callType.toLowerCase() == 'incoming').length;
    final outgoingCount = history.calls.where((c) => c.callType.toLowerCase() == 'outgoing').length;
    final missedCount = history.calls.where((c) => c.callType.toLowerCase() == 'missed').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C111D),
        title: _showSearch
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D2939),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search contacts or phone numbers...',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: Color(0xFF0070F3), size: 18),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => ref.read(historyProvider.notifier).search(v),
                ),
              )
            : const Text(
                'Call History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
              ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today_rounded,
              color: history.selectedDate != null ? const Color(0xFF0070F3) : Colors.white,
            ),
            tooltip: 'Filter by date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: history.selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
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
              if (picked != null) {
                ref.read(historyProvider.notifier).setDate(picked);
              }
            },
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  ref.read(historyProvider.notifier).search('');
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Pill segmented TabBar container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1D2939),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: const Color(0xFF0070F3),
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.blueGrey.shade400,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // Dynamic Overview Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                _buildQuickStatCard('All', totalCount.toString(), const Color(0xFF0070F3)),
                const SizedBox(width: 8),
                _buildQuickStatCard('In', incomingCount.toString(), const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildQuickStatCard('Out', outgoingCount.toString(), const Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                _buildQuickStatCard('Missed', missedCount.toString(), const Color(0xFFEF4444)),
              ],
            ),
          ).animate().fadeIn(),

          if (history.selectedDate != null)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0070F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0070F3).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF38bdf8)),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(history.selectedDate!)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.read(historyProvider.notifier).setDate(null),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(historyProvider.notifier).loadCalls(
                    filter: history.filter,
                    search: history.searchQuery,
                    date: history.selectedDate,
                  ),
              color: const Color(0xFF0070F3),
              child: history.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: ShimmerList(itemCount: 8, itemHeight: 72),
                    )
                  : history.calls.isEmpty
                      ? const EmptyState(
                          icon: Icons.history_rounded,
                          title: 'No calls found',
                          subtitle: 'Your call history will appear here',
                        )
                      : () {
                          // Group calls by phone number
                          final Map<String, List<CallLogItem>> groups = {};
                          for (final call in history.calls) {
                            final key = call.phoneNumber.isNotEmpty ? call.phoneNumber : 'Unknown';
                            groups.putIfAbsent(key, () => []).add(call);
                          }
                          final groupedCalls = groups.entries.map((e) {
                            final firstCall = e.value.first;
                            return _GroupedCall(
                              phoneNumber: e.key,
                              contactName: firstCall.contactName,
                              items: e.value,
                            );
                          }).toList();

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                            itemCount: groupedCalls.length,
                            itemBuilder: (context, i) {
                              final group = groupedCalls[i];
                              return _GroupedCallCard(
                                group: group,
                                playingUrl: _playingUrl,
                                isPlaying: _isAudioPlaying,
                                isLoading: _isAudioLoading,
                                onPlayToggle: _togglePlayback,
                              )
                                  .animate(delay: (i * 20).ms)
                                  .fadeIn(duration: 200.ms);
                            },
                          );
                        }(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2939),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedCall {
  final String phoneNumber;
  final String contactName;
  final List<CallLogItem> items;
  _GroupedCall({required this.phoneNumber, required this.contactName, required this.items});
}

class _GroupedCallCard extends StatelessWidget {
  final _GroupedCall group;
  final String? playingUrl;
  final bool isPlaying;
  final bool isLoading;
  final Function(String) onPlayToggle;

  const _GroupedCallCard({
    required this.group,
    required this.playingUrl,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayToggle,
  });

  @override
  Widget build(BuildContext context) {
    final name = group.contactName.isNotEmpty ? group.contactName : group.phoneNumber;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0070F3).withOpacity(0.15),
                  child: Text(
                    initials,
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
                        group.phoneNumber,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (group.contactName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          group.contactName,
                          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C111D),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
                  ),
                  child: Text(
                    '${group.items.length} ${group.items.length == 1 ? "call" : "calls"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:${group.phoneNumber}')),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 15),
                  ),
                ),
              ],
            ),
          ),
          
          // List of calls inside the group
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: group.items.map((call) {
                final typeColor = call.callType.toLowerCase() == 'incoming'
                    ? const Color(0xFF10B981)
                    : call.callType.toLowerCase() == 'outgoing'
                        ? const Color(0xFF0070F3)
                        : call.callType.toLowerCase() == 'missed'
                            ? const Color(0xFFEF4444)
                            : Colors.orange;

                final typeIcon = call.callType.toLowerCase() == 'incoming'
                    ? Icons.call_received_rounded
                    : call.callType.toLowerCase() == 'outgoing'
                        ? Icons.call_made_rounded
                        : Icons.call_missed_rounded;

                // Playback status check for this item
                final cleanPath = call.recordingPath != null 
                    ? (call.recordingPath!.startsWith('/') ? call.recordingPath! : '/${call.recordingPath!}') 
                    : '';
                final itemFullUrl = call.recordingPath != null 
                    ? (call.recordingPath!.startsWith('http') 
                        ? call.recordingPath! 
                        : '${ApiConstants.baseUrl}$cleanPath')
                    : '';
                final isCurrent = playingUrl == itemFullUrl && itemFullUrl.isNotEmpty;
                final isThisPlaying = isCurrent && isPlaying;
                final isThisLoading = isCurrent && isLoading;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CallDetailScreen(
                          phoneNumber: call.phoneNumber,
                          contactName: call.contactName,
                          callType: call.callType,
                          startTime: call.startTime,
                          duration: call.duration,
                          callLogId: call.callLogId,
                          hasRecording: call.hasRecording,
                          recordingPath: call.recordingPath,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C111D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(typeIcon, size: 12, color: typeColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.time(call.startTime),
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: Colors.blueGrey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    Formatters.duration(call.duration),
                                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (call.hasRecording && call.recordingPath != null)
                          GestureDetector(
                            onTap: () => onPlayToggle(call.recordingPath!),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isThisPlaying 
                                    ? const Color(0xFF0070F3) 
                                    : const Color(0xFF0070F3).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: isThisLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0, 
                                        color: Color(0xFF38bdf8),
                                      ),
                                    )
                                  : Icon(
                                      isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      size: 14,
                                      color: isThisPlaying ? Colors.white : const Color(0xFF38bdf8),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
