import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

// Arka plandan dönmeyi dinlemek için WidgetsBindingObserver ekledik
class _MeditationScreenState extends State<MeditationScreen> with WidgetsBindingObserver {
  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isActive = false;
  DateTime? _endTime; // SÜREKLİ ZAMAN KONTROLÜ İÇİN BİTİŞ ZAMANI
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 3 Dakikalık seçenek eklendi
  final List<int> _durations = [3, 5, 10, 15, 20]; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Dinleyiciyi başlat
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this); // Dinleyiciyi kapat
    super.dispose();
  }

  // EKRAN KİLİDİ AÇILDIĞINDA VEYA UYGULAMAYA DÖNÜLDÜĞÜNDE TETİKLENİR
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isActive && _endTime != null) {
      _updateTimer(); // Uyandığı an süreyi gerçek zamana göre düzelt
    }
  }

  void _startTimer(int minutes) async {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = minutes * 60;
      _isActive = true;
      // BİTİŞ ZAMANINI ŞU ANKİ ZAMAN + SEÇİLEN DAKİKA OLARAK BELİRLE
      _endTime = DateTime.now().add(Duration(minutes: minutes));
    });

    // BAŞLANGIÇ SESİ
    try {
      await _audioPlayer.play(AssetSource('sounds/bell_sound.mp3'));
    } catch (e) {
      debugPrint("Başlangıç sesi çalınamadı: $e");
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimer();
    });
  }

  // ZAMANI GERÇEK SAATE GÖRE HESAPLAYAN FONKSİYON
  void _updateTimer() {
    if (_endTime == null) return;

    final now = DateTime.now();
    final difference = _endTime!.difference(now).inSeconds;

    if (difference > 0) {
      setState(() {
        _secondsRemaining = difference;
      });
    } else {
      // Süre bitti (Eğer telefon uykudayken bittiyse uyandığında burası direkt çalışır)
      _onFinished();
    }
  }

  void _onFinished() async {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _secondsRemaining = 0;
      _endTime = null;
    });

    // BİTİŞ SESİ VE TİTREŞİM
    try {
      await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
      HapticFeedback.heavyImpact(); 
    } catch (e) {
      debugPrint("Sonda ses hatası: $e");
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _secondsRemaining = 0;
      _endTime = null;
    });
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black;
    Color boxColor = isDark ? Colors.grey[900]! : Colors.white;

    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            
            // SAYAÇ EKRANI
            Text(
              _formattedTime,
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 40),

            // BUTONLAR
            if (!_isActive) ...[
              Wrap(
                spacing: 15,
                runSpacing: 15,
                alignment: WrapAlignment.center,
                children: _durations.map((mins) {
                  return OutlinedButton(
                    onPressed: () => _startTimer(mins),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: textColor, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      '$mins MIN',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              OutlinedButton(
                onPressed: _stopTimer,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
            
            const SizedBox(height: 40),
            Text(
              _isActive ? "Focus on your breath." : "Select duration to begin.",
              style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            )
          ],
        ),
      ),
    );
  }
}