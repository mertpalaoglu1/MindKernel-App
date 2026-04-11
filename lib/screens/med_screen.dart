import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedScreen extends StatefulWidget {
  const MedScreen({super.key});

  @override
  State<MedScreen> createState() => _MedScreenState();
}

class _MedScreenState extends State<MedScreen> {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isActive = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _meditationStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Hafızadan seri bilgisini çekme
  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _meditationStreak = prefs.getInt('meditationStreak') ?? 0;
    });
  }

  // Zamanlayıcıyı başlatma
  void _startTimer(int minutes) {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = minutes * 60;
      _isActive = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onFinished();
      }
    });
  }

  // Süre bittiğinde yapılacaklar
  void _onFinished() async {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _secondsRemaining = 0;
    });
    
    // Bitiş sesi (assets/sounds/bell.mp3 dosyasını eklemeyi unutma)
    try {
      await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
    } catch (e) {
      debugPrint("Ses dosyası bulunamadı, sessiz devam ediliyor.");
    }
    
    // Seri güncelleme
    final prefs = await SharedPreferences.getInstance();
    int newStreak = _meditationStreak + 1;
    await prefs.setInt('meditationStreak', newStreak);
    setState(() {
      _meditationStreak = newStreak;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session complete. Stay mindful.')),
      );
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _secondsRemaining = 0;
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'MEDITATION STREAK',
              style: TextStyle(fontSize: 14, letterSpacing: 2, color: Colors.grey),
            ),
            Text(
              '$_meditationStreak DAYS',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            
            // Minimalist Daire Zamanlayıcı
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Center(
                child: Text(
                  _formatTime(_secondsRemaining),
                  style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w200),
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            
            if (!_isActive) ...[
              const Text('Select Duration:'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _timeButton(5),
                  const SizedBox(width: 15),
                  _timeButton(10),
                  const SizedBox(width: 15),
                  _timeButton(15),
                ],
              ),
            ] else 
              OutlinedButton(
                onPressed: _stopTimer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                ),
                child: const Text('CANCEL SESSION'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeButton(int mins) {
    return ElevatedButton(
      onPressed: () => _startTimer(mins),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text('$mins MIN'),
    );
  }
}