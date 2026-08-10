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

    final typeColor = widget.callType.toLowerCase() == 'incoming'
        ? Colors.blue
        : widget.callType.toLowerCase() == 'outgoing'
            ? const Color(0xFF0070F3)
            : Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF1D2939),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1D2939),
                      Color(0xFF0C111D),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [typeColor, typeColor.withOpacity(0.6)]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: typeColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                          ],
                        ),
                        child: Center(
                          child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.phoneNumber,
                        style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade300),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InfoCard(children: [
                  _InfoRow(label: 'Type', value: widget.callType, icon: Icons.call_rounded, color: typeColor),
                  const Divider(height: 20, color: Colors.white10),
                  _InfoRow(label: 'Date', value: Formatters.dateTime(widget.startTime), icon: Icons.calendar_today_rounded, color: Colors.blue),
                  const Divider(height: 20, color: Colors.white10),
                  _InfoRow(label: 'Duration', value: Formatters.duration(widget.duration), icon: Icons.timer_rounded, color: Colors.teal),
                ]).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.call_rounded,
                        label: 'Call',
                        color: Colors.green,
                        onTap: () => launchUrl(Uri.parse('tel:${widget.phoneNumber}')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.message_rounded,
                        label: 'Message',
                        color: Colors.blue,
                        onTap: () => launchUrl(Uri.parse('sms:${widget.phoneNumber}')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.auto_awesome_rounded,
                        label: 'AI Summary',
                        color: const Color(0xFF0070F3),
                        onTap: () {
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
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        color: const Color(0xFF7A5AF8),
                        onTap: () => Share.share('Call with $name\n${widget.phoneNumber}\n${Formatters.dateTime(widget.startTime)}\nDuration: ${Formatters.duration(widget.duration)}'),
                      ),
                    ),
                  ],
                ).animate(delay: 200.ms).fadeIn(),

                const SizedBox(height: 20),

                if (widget.hasRecording && widget.recordingPath != null) ...[
                  Text(
                    'RECORDING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.blueGrey.shade300,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _isLoadingRecording ? null : _playRecording,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF0070F3), Color(0xFF7A5AF8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
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
                                    size: 28,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: const Color(0xFF0070F3),
                                  inactiveTrackColor: const Color(0xFF0070F3).withOpacity(0.15),
                                  thumbColor: const Color(0xFF0070F3),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
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
                                      style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade300),
                                    ),
                                    Text(
                                      Formatters.timerDuration(_totalDuration.inSeconds),
                                      style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade300),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recording path: ${widget.recordingPath}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]).animate(delay: 300.ms).fadeIn().slideY(begin: 0.05),
                ] else ...[
                  _InfoCard(children: [
                    Row(
                      children: [
                        Icon(Icons.mic_off_rounded, color: Colors.blueGrey.shade400, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'No recording available',
                          style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade300),
                        ),
                      ],
                    ),
                  ]).animate(delay: 300.ms).fadeIn(),
                ],

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _InfoRow({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade300)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
