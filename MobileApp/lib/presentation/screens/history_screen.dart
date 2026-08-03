import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/formatters.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
          indicatorColor: const Color(0xFF465FFF),
          indicatorWeight: 3,
          labelColor: const Color(0xFF465FFF),
          unselectedLabelColor: Colors.blueGrey.shade300,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(historyProvider.notifier).loadCalls(filter: history.filter, search: history.searchQuery),
        color: const Color(0xFF465FFF),
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
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: history.calls.length,
                    itemBuilder: (context, i) {
                      final call = history.calls[i];
                      return _CallTile(call: call)
                          .animate(delay: (i * 20).ms)
                          .fadeIn(duration: 200.ms);
                    },
                  ),
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  final CallLogItem call;

  const _CallTile({required this.call});

  @override
  Widget build(BuildContext context) {
    final name = call.contactName.isNotEmpty ? call.contactName : call.phoneNumber;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final typeColor = call.callType.toLowerCase() == 'incoming'
        ? Colors.blue
        : call.callType.toLowerCase() == 'outgoing'
            ? const Color(0xFF465FFF)
            : call.callType.toLowerCase() == 'missed'
                ? Colors.redAccent
                : Colors.orange;

    final typeIcon = call.callType.toLowerCase() == 'incoming'
        ? Icons.call_received_rounded
        : call.callType.toLowerCase() == 'outgoing'
            ? Icons.call_made_rounded
            : Icons.call_missed_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => CallDetailScreen(
                phoneNumber: call.phoneNumber,
                contactName: call.contactName,
                callType: call.callType,
                startTime: call.startTime,
                duration: call.duration,
                callLogId: call.callLogId,
                hasRecording: call.hasRecording,
                recordingPath: call.recordingPath,
              ),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: typeColor.withOpacity(0.12),
                  child: Text(initials, style: TextStyle(color: typeColor, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (call.hasRecording)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF465FFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic_rounded, size: 10, color: Color(0xFF465FFF)),
                                  SizedBox(width: 2),
                                  Text('REC', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF465FFF))),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(typeIcon, size: 13, color: typeColor),
                          const SizedBox(width: 4),
                          Text(
                            '${call.callType} • ${Formatters.duration(call.duration)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.time(call.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade300,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.date(call.startTime),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey.shade300.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:${call.phoneNumber}')),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.call, color: Colors.green, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
