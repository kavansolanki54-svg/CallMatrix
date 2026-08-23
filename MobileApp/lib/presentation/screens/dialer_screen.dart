import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  String _number = '';

  void _addDigit(String digit) {
    setState(() => _number += digit);
  }

  void _backspace() {
    if (_number.isNotEmpty) {
      setState(() => _number = _number.substring(0, _number.length - 1));
    }
  }

  void _makeCall() {
    if (_number.isNotEmpty) {
      launchUrl(Uri.parse('tel:$_number'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C111D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0C111D),
        title: const Text(
          'Dialer',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          const Spacer(flex: 2),

          // Number display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _number.isEmpty ? 'Enter phone number' : _number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _number.length > 12 ? 26 : 34,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: _number.isEmpty
                          ? Colors.blueGrey.shade400.withOpacity(0.4)
                          : Colors.white,
                    ),
                  ),
                ),
                if (_number.isNotEmpty)
                  GestureDetector(
                    onTap: _backspace,
                    onLongPress: () => setState(() => _number = ''),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D2939),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF334155).withOpacity(0.3)),
                      ),
                      child: Icon(
                        Icons.backspace_outlined,
                        color: Colors.blueGrey.shade300,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          const Spacer(),

          // Keypad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                const SizedBox(height: 18),
                _buildRow(['4', '5', '6']),
                const SizedBox(height: 18),
                _buildRow(['7', '8', '9']),
                const SizedBox(height: 18),
                _buildRow(['*', '0', '#']),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05),

          const SizedBox(height: 36),

          // Call button
          GestureDetector(
            onTap: _makeCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0070F3), Color(0xFF7A5AF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0070F3).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.phone_rounded, color: Colors.white, size: 30),
            ),
          ).animate(delay: 300.ms).scale(duration: 400.ms, curve: Curves.easeOutBack),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _DialButton(
        digit: d,
        subtitle: _getSubtitle(d),
        onTap: () => _addDigit(d),
      )).toList(),
    );
  }

  String? _getSubtitle(String digit) {
    const subs = {
      '2': 'ABC', '3': 'DEF', '4': 'GHI', '5': 'JKL',
      '6': 'MNO', '7': 'PQRS', '8': 'TUV', '9': 'WXYZ',
      '0': '+',
    };
    return subs[digit];
  }
}

class _DialButton extends StatelessWidget {
  final String digit;
  final String? subtitle;
  final VoidCallback onTap;

  const _DialButton({required this.digit, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFF1D2939),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF334155).withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              digit,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Colors.blueGrey.shade400,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
