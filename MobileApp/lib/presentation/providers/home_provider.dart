import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../services/native_call_sync_service.dart';
import 'history_provider.dart';

class TopContact {
  final String phoneNumber;
  final String contactName;
  final int totalCalls;
  final int totalDuration;
  final int rank;

  TopContact({
    required this.phoneNumber,
    required this.contactName,
    required this.totalCalls,
    required this.totalDuration,
    required this.rank,
  });

  factory TopContact.fromJson(Map<String, dynamic> json) {
    return TopContact(
      phoneNumber: json['phoneNumber'] ?? '',
      contactName: json['contactName'] ?? '',
      totalCalls: json['totalCalls'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }
}

class HomeStats {
  final int totalCalls;
  final int totalDuration;
  final int uniqueContacts;
  final double answerRate;
  final int todayCalls;
  final int missedCalls;
  final bool isLoading;
  final List<CallLogItem> recentCalls;
  final List<TopContact> topContacts;

  const HomeStats({
    this.totalCalls = 0,
    this.totalDuration = 0,
    this.uniqueContacts = 0,
    this.answerRate = 0,
    this.todayCalls = 0,
    this.missedCalls = 0,
    this.isLoading = true,
    this.recentCalls = const [],
    this.topContacts = const [],
  });
}

class HomeNotifier extends StateNotifier<HomeStats> {
  HomeNotifier() : super(const HomeStats()) {
    loadData();
  }

  Future<void> loadData() async {
    state = const HomeStats(isLoading: true);
    try {
      final dio = ApiClient.instance.dio;

      int totalCalls = 0, totalDuration = 0, uniqueContacts = 0, missedCalls = 0;
      double answerRate = 0;
      try {
        final summaryRes = await dio.get(ApiConstants.analyticsSummary);
        final success = summaryRes.data['success'] ?? summaryRes.data['isSuccess'] ?? false;
        if (success == true) {
          final d = summaryRes.data['data'];
          totalCalls = d['totalCalls'] ?? 0;
          totalDuration = d['totalDuration'] ?? 0;
          uniqueContacts = d['uniqueContacts'] ?? 0;
          answerRate = (d['answerRate'] ?? 0).toDouble();
        }
      } catch (_) {}

      List<CallLogItem> recentCalls = [];
      try {
        final logsRes = await dio.get(ApiConstants.callLogsList, queryParameters: {'page': 1, 'pageSize': 50});
        final success = logsRes.data['success'] ?? logsRes.data['isSuccess'] ?? false;
        if (success == true) {
          final data = logsRes.data['data'];
          final items = (data['items'] as List? ?? data as List? ?? []);
          recentCalls = items.map((e) => CallLogItem.fromJson(e as Map<String, dynamic>)).toList();
          final today = DateTime.now();
          for (final c in recentCalls) {
            if (c.startTime.year == today.year && c.startTime.month == today.month && c.startTime.day == today.day) {
              if (c.callType.toLowerCase() == 'missed') missedCalls++;
            }
          }
        }
      } catch (_) {}

      List<TopContact> topContacts = [];
      try {
        final Map<String, ({String name, int count, int duration})> contactCounts = {};
        for (final c in recentCalls) {
          final phone = c.phoneNumber;
          final current = contactCounts[phone] ?? (name: c.contactName, count: 0, duration: 0);
          contactCounts[phone] = (
            name: current.name.isNotEmpty ? current.name : c.contactName,
            count: current.count + 1,
            duration: current.duration + c.duration,
          );
        }

        final sorted = contactCounts.entries.toList()
          ..sort((a, b) => b.value.count.compareTo(a.value.count));

        int rank = 1;
        topContacts = sorted.take(5).map((e) => TopContact(
          phoneNumber: e.key,
          contactName: e.value.name,
          totalCalls: e.value.count,
          totalDuration: e.value.duration,
          rank: rank++,
        )).toList();
      } catch (_) {}

      state = HomeStats(
        totalCalls: totalCalls,
        totalDuration: totalDuration,
        uniqueContacts: uniqueContacts,
        answerRate: answerRate,
        todayCalls: recentCalls.where((c) {
          final today = DateTime.now();
          return c.startTime.year == today.year && c.startTime.month == today.month && c.startTime.day == today.day;
        }).length,
        missedCalls: missedCalls,
        isLoading: false,
        recentCalls: recentCalls,
        topContacts: topContacts,
      );
    } catch (_) {
      state = const HomeStats(isLoading: false);
    }
  }

  Future<int> syncAndReload() async {
    final synced = await NativeCallSyncService.runSync();
    await loadData();
    return synced;
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeStats>((ref) {
  return HomeNotifier();
});
