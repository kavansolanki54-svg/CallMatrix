import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class CallLogItem {
  final int? callLogId;
  final String phoneNumber;
  final String contactName;
  final String callType;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration;
  final String? simId;
  final bool hasRecording;
  final String? recordingPath;

  CallLogItem({
    this.callLogId,
    required this.phoneNumber,
    required this.contactName,
    required this.callType,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.simId,
    this.hasRecording = false,
    this.recordingPath,
  });

  factory CallLogItem.fromJson(Map<String, dynamic> json) {
    return CallLogItem(
      callLogId: json['callLogId'] ?? json['callId'],
      phoneNumber: json['phoneNumber'] ?? '',
      contactName: json['contactName'] ?? '',
      callType: json['callType'] ?? 'Unknown',
      startTime: DateTime.tryParse(json['callDateTime'] ?? json['startTime'] ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      duration: json['duration'] ?? 0,
      simId: json['simId'],
      hasRecording: json['hasRecording'] ?? json['isRecordingAvailable'] ?? false,
      recordingPath: json['recordingUrl'] ?? json['recordingPath'],
    );
  }
}

class HistoryState {
  final List<CallLogItem> calls;
  final bool isLoading;
  final int totalCount;
  final int currentPage;
  final String? filter;
  final String? searchQuery;

  const HistoryState({
    this.calls = const [],
    this.isLoading = true,
    this.totalCount = 0,
    this.currentPage = 1,
    this.filter,
    this.searchQuery,
  });

  HistoryState copyWith({
    List<CallLogItem>? calls,
    bool? isLoading,
    int? totalCount,
    int? currentPage,
    String? filter,
    String? searchQuery,
  }) {
    return HistoryState(
      calls: calls ?? this.calls,
      isLoading: isLoading ?? this.isLoading,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      filter: filter,
      searchQuery: searchQuery,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier() : super(const HistoryState()) {
    loadCalls();
  }

  Future<void> loadCalls({String? filter, int page = 1, String? search}) async {
    state = state.copyWith(isLoading: true, filter: filter, searchQuery: search);
    try {
      final dio = ApiClient.instance.dio;

      List<CallLogItem> allItems = [];

      try {
        final res = await dio.get(ApiConstants.callLogsList, queryParameters: {
          'page': page,
          'pageSize': 100,
          if (search != null && search.isNotEmpty) 'search': search,
        });

        if (res.data['success'] == true || res.data['isSuccess'] == true) {
          final data = res.data['data'];
          final items = (data['items'] as List? ?? data as List? ?? [])
              .map((e) => CallLogItem.fromJson(e as Map<String, dynamic>))
              .toList();
          allItems = items;
        }
      } catch (_) {
        try {
          final res2 = await dio.get(ApiConstants.callLogsList);
          if (res2.data['success'] == true || res2.data['isSuccess'] == true) {
            final items = (res2.data['data'] as List? ?? [])
                .map((e) => CallLogItem.fromJson(e as Map<String, dynamic>))
                .toList();
            allItems = items;
          }
        } catch (_) {}
      }

      final filtered = filter == null || filter.toLowerCase() == 'all'
          ? allItems
          : allItems.where((c) => c.callType.toLowerCase() == filter.toLowerCase()).toList();

      state = HistoryState(
        calls: filtered,
        isLoading: false,
        totalCount: allItems.length,
        currentPage: page,
        filter: filter,
        searchQuery: search,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setFilter(String? filter) {
    loadCalls(filter: filter, search: state.searchQuery);
  }

  void search(String query) {
    loadCalls(filter: state.filter, search: query);
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});
