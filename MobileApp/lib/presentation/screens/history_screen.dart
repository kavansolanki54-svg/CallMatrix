import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
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
        if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
          source = UrlSource(fullUrl);
        } else if (File(url).existsSync()) {
          source = DeviceFileSource(url);
        } else {
          source = UrlSource(fullUrl);
        }

        await _audioPlayer.play(source);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing recording: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search calls...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => ref.read(historyProvider.notifier).search(v),
              )
            : const Text('Call History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D2939),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: 'Filter by date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: history.selectedDate ?? DateTime.now(),
                firstDate: DateTime(2025),
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
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
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
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: const Color(0xFF0070F3),
          indicatorWeight: 3,
          labelColor: const Color(0xFF0070F3),
          unselectedLabelColor: Colors.blueGrey.shade300,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          if (history.selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFF1D2939),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF0070F3)),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${history.selectedDate!.year}-${history.selectedDate!.month.toString().padLeft(2, '0')}-${history.selectedDate!.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.read(historyProvider.notifier).setDate(null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    ),
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
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0070F3).withOpacity(0.15),
                  foregroundColor: const Color(0xFF0070F3),
                  child: Text(initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                          style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group.items.length} ${group.items.length == 1 ? "call" : "calls"}',
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:${group.phoneNumber}')),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.call, color: Colors.green, size: 16),
                  ),
                ),
              ],
            ),
          ),
          
          // List of calls inside the group
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: group.items.map((call) {
                final typeColor = call.callType.toLowerCase() == 'incoming'
                    ? Colors.blue
                    : call.callType.toLowerCase() == 'outgoing'
                        ? const Color(0xFF0070F3)
                        : call.callType.toLowerCase() == 'missed'
                            ? Colors.redAccent
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
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.02)),
                    ),
                    child: Row(
                      children: [
                        Icon(typeIcon, size: 14, color: typeColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.time(call.startTime),
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 10, color: Colors.blueGrey.shade400),
                                  const SizedBox(width: 3),
                                  Text(
                                    Formatters.duration(call.duration),
                                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 9),
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isThisPlaying 
                                    ? const Color(0xFF0070F3) 
                                    : const Color(0xFF0070F3).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: isThisLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2, 
                                        color: Color(0xFF0070F3),
                                      ),
                                    )
                                  : Icon(
                                      isThisPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      size: 14,
                                      color: isThisPlaying ? Colors.white : const Color(0xFF0070F3),
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
