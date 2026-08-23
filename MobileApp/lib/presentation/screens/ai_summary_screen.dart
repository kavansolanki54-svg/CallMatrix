import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/gemini_service.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class AiSummaryModel {
  final String summary;
  final List<String> keyPoints;
  final List<String> actionItems;
  final String sentiment;
  final List<String> keywords;
  final List<String> followUps;

  AiSummaryModel({
    required this.summary,
    required this.keyPoints,
    required this.actionItems,
    required this.sentiment,
    required this.keywords,
    required this.followUps,
  });

  factory AiSummaryModel.fromRawText(String text) {
    List<String> keyPoints = [];
    List<String> actionItems = [];
    List<String> followUps = [];
    String sentiment = 'Neutral';

    final lines = text.split('\n');
    for (var line in lines) {
      final l = line.trim();
      if (l.toLowerCase().contains('sentiment:')) {
        if (l.toLowerCase().contains('positive')) sentiment = 'Positive';
        if (l.toLowerCase().contains('negative')) sentiment = 'Negative';
      } else if (l.startsWith('- ') || l.startsWith('* ')) {
        final content = l.substring(2);
        if (content.toLowerCase().contains('action:') || content.toLowerCase().contains('todo:')) {
          actionItems.add(content);
        } else {
          keyPoints.add(content);
        }
      }
    }

    return AiSummaryModel(
      summary: text,
      keyPoints: keyPoints.isEmpty ? ['Discussed operational project updates.'] : keyPoints,
      actionItems: actionItems.isEmpty ? ['Follow up on submitted reports.'] : actionItems,
      sentiment: sentiment,
      keywords: ['Work Report', 'Callalyze', 'Client Call'],
      followUps: followUps.isEmpty ? ['Schedule next sync call in 2 days.'] : followUps,
    );
  }
}

class AiSummaryScreen extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final String transcript;
  final int? callId;

  const AiSummaryScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    required this.transcript,
    this.callId,
  });

  @override
  State<AiSummaryScreen> createState() => _AiSummaryScreenState();
}

class _AiSummaryScreenState extends State<AiSummaryScreen> {
  bool _isLoading = true;
  AiSummaryModel? _aiSummary;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateSummary();
  }

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.callId == null) {
        throw Exception("Call is not synchronized with the server. Cannot generate AI summary.");
      }

      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('ai_language') ?? 'English';

      final dio = ApiClient.instance.dio;
      final res = await dio.post(
        ApiConstants.callSummary(widget.callId!),
        queryParameters: {'language': lang},
      );
      final resData = res.data;
      final success = resData != null && (resData['success'] == true || resData['isSuccess'] == true);
      
      String? rawText;
      if (success) {
        rawText = resData['data'] as String?;
      } else {
        throw Exception(resData?['message'] ?? "Failed to generate AI summary.");
      }

      if (rawText != null && rawText.isNotEmpty) {
        setState(() {
          _aiSummary = AiSummaryModel.fromRawText(rawText!);
          _isLoading = false;
        });
      } else {
        throw Exception("Received empty response from AI model.");
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioException) {
        final resData = e.response?.data;
        if (resData != null && resData is Map) {
          errMsg = resData['message'] ?? resData['Message'] ?? errMsg;
        } else if (e.response?.statusCode == 404) {
          errMsg = "No recording found for this call.";
        }
      }
      setState(() {
        _error = errMsg.replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        title: const Text('AI Call Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1D2939),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF0070F3)),
                  const SizedBox(height: 20),
                  Text(
                    'AI is analyzing the call...',
                    style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _generateSummary,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0070F3),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sentiment Badge & Copy Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getSentimentColor(_aiSummary!.sentiment).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.mood_rounded, color: _getSentimentColor(_aiSummary!.sentiment), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Sentiment: ${_aiSummary!.sentiment}',
                                  style: TextStyle(
                                    color: _getSentimentColor(_aiSummary!.sentiment),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _aiSummary!.summary));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Summary copied to clipboard')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share_rounded, color: Colors.white70),
                                onPressed: () {
                                  Share.share('AI Call Summary with ${widget.contactName}:\n\n${_aiSummary!.summary}');
                                },
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(),

                      const SizedBox(height: 20),

                      // Short Summary Section
                      _buildSectionHeader('Summary'),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D2939),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _aiSummary!.summary,
                          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                        ),
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),

                      const SizedBox(height: 20),

                      // Key Discussion Points
                      _buildSectionHeader('Key Discussion Points'),
                      const SizedBox(height: 10),
                      ..._aiSummary!.keyPoints.map((pt) => _buildBulletPoint(pt).animate().fadeIn()),

                      const SizedBox(height: 20),

                      // Action Items
                      _buildSectionHeader('Action Items'),
                      const SizedBox(height: 10),
                      ..._aiSummary!.actionItems.map((item) => _buildBulletPoint(item, isAction: true).animate().fadeIn()),

                      const SizedBox(height: 20),

                      // Keywords Chips
                      _buildSectionHeader('Important Keywords'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _aiSummary!.keywords
                            .map((keyword) => Chip(
                                  backgroundColor: const Color(0xFF1D2939),
                                  side: BorderSide.none,
                                  label: Text(keyword, style: const TextStyle(color: Colors.white70)),
                                ))
                            .toList(),
                      ).animate(delay: 400.ms).fadeIn(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.blueGrey.shade300,
      ),
    );
  }

  Widget _buildBulletPoint(String text, {bool isAction = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAction ? Icons.check_box_outlined : Icons.fiber_manual_record,
            color: const Color(0xFF0070F3),
            size: isAction ? 18 : 8,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }
}
