import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/api_constants.dart';
import 'ai_summary_screen.dart';

class CallDetailScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String contactName;
  final String callType;
  final DateTime startTime;
  final int duration;
  final int? callLogId;
  final bool hasRecording;
  final String? recordingPath;

  const CallDetailScreen({
    super.key,
    required this.phoneNumber,
    required this.contactName,
    required this.callType,
    required this.startTime,
    required this.duration,
    this.callLogId,
    this.hasRecording = false,
    this.recordingPath,
  });

  @override
  ConsumerState<CallDetailScreen> createState() => _CallDetailScreenState();
}

class _CallDetailScreenState extends ConsumerState<CallDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isLoadingRecording = false;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playRecording() async {
    final path = widget.recordingPath;
    if (path == null || path.isEmpty) return;

    setState(() => _isLoadingRecording = true);
    try {
      if (_isPlaying) {
        await _player.pause();
        setState(() => _isPlaying = false);
      } else {
        if (_currentPosition.inSeconds > 0) {
          await _player.resume();
        } else {
          Source source;
          if (path.startsWith('http://') || path.startsWith('https://')) {
            source = UrlSource(path);
          } else if (File(path).existsSync()) {
            source = DeviceFileSource(path);
          } else {
            final cleanPath = path.startsWith('/') ? path : '/$path';
            final url = '${ApiConstants.baseUrl}$cleanPath';
            source = UrlSource(url);
          }
          await _player.play(source);
        }
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing recording: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingRecording = false);
    }
  }

  Future<void> _seekTo(double value) async {
    await _player.seek(Duration(milliseconds: value.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.contactName.isNotEmpty ? widget.contactName : widget.phoneNumber;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final isMissed = widget.callType.toLowerCase() == 'missed';
    final statusText = isMissed ? 'Missed' : 'Answered';
    final statusColor = isMissed ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C111D),
        title: const Text(
          'Call Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Identity Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2939),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF0070F3).withOpacity(0.15),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFF38bdf8),
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.phoneNumber,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (widget.contactName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.contactName,
                            style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Call info key-value card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2939),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Time', Formatters.dateTime(widget.startTime)),
                  Divider(color: const Color(0xFF334155).withOpacity(0.2), height: 24),
                  _buildDetailRow('Duration', Formatters.duration(widget.duration)),
                  Divider(color: const Color(0xFF334155).withOpacity(0.2), height: 24),
                  _buildDetailRow('Source', 'Mumbai, India'),
                  Divider(color: const Color(0xFF334155).withOpacity(0.2), height: 24),
                  _buildDetailRow('Assigned To', 'Sales Team'),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Audio Player Section
            if (widget.hasRecording && widget.recordingPath != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D2939),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isLoadingRecording ? null : _playRecording,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0070F3),
                          shape: BoxShape.circle,
                        ),
                        child: _isLoadingRecording
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              activeTrackColor: const Color(0xFF0070F3),
                              inactiveTrackColor: const Color(0xFF334155),
                              thumbColor: const Color(0xFF0070F3),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                            ),
                            child: Slider(
                              value: _currentPosition.inMilliseconds.toDouble(),
                              max: _totalDuration.inMilliseconds.toDouble().clamp(1, double.infinity),
                              onChanged: _seekTo,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  Formatters.timerDuration(_currentPosition.inSeconds),
                                  style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  Formatters.timerDuration(_totalDuration.inSeconds),
                                  style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade400, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.05),
              const SizedBox(height: 16),
            ],

            // Add Tags Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2939),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Tags',
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPillTag('Follow up'),
                      const SizedBox(width: 8),
                      _buildPillTag('Interested'),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 16),

            // Add Notes Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1D2939),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Notes',
                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Call went well. Will follow up tomorrow.',
                    style: TextStyle(color: Colors.blueGrey.shade200, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 24),

            // Action Items bottom row
            Row(
              children: [
                Expanded(
                  child: _buildBottomActionButton(Icons.phone_rounded, 'Call', () {
                    launchUrl(Uri.parse('tel:${widget.phoneNumber}'));
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBottomActionButton(Icons.message_rounded, 'Message', () {
                    launchUrl(Uri.parse('sms:${widget.phoneNumber}'));
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBottomActionButton(Icons.edit_note_rounded, 'Add Note', () {}),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildBottomActionButton(Icons.auto_awesome_rounded, 'AI Summary', () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AiSummaryScreen(
                          contactName: name,
                          phoneNumber: widget.phoneNumber,
                          transcript: 'Call duration ${widget.duration} seconds on ${widget.startTime}.',
                          callId: widget.callLogId,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPillTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0C111D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBottomActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2939),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF38bdf8), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
