import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

// WidgetsBindingObserver ekledik: Arka plandan uyanmayı dinler
class _PrayerScreenState extends State<PrayerScreen> with WidgetsBindingObserver {
  final Map<String, bool> _dailyPrayers = {
    'Fajr (Sabah)': false, 'Dhuhr (Öğle)': false, 'Asr (İkindi)': false,
    'Maghrib (Akşam)': false, 'Isha (Yatsı)': false,
  };

  final Map<String, int> _qazaPrayers = {
    'Fajr (Sabah)': 0, 'Dhuhr (Öğle)': 0, 'Asr (İkindi)': 0,
    'Maghrib (Akşam)': 0, 'Isha (Yatsı)': 0,
  };

  int _totalPerfectDays = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Dinleyiciyi başlat
    _loadPrayerData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Dinleyiciyi kapat
    super.dispose();
  }

  // UYGULAMA ARKA PLANDAN GELDİĞİNDE TETİKLENİR!
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPrayerData(); // Tarihi tekrar kontrol et
    }
  }

  Future<void> _loadPrayerData() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime logicalNow = DateTime.now().subtract(const Duration(hours: 4));
    final String today = logicalNow.toIso8601String().substring(0, 10);
    final String lastSavedDate = prefs.getString('lastPrayerDate') ?? today;

    setState(() {
      _totalPerfectDays = prefs.getInt('perfectPrayerDays') ?? 0;

      // Tüm qaza (kaza) verilerini baştan çek
      for (var key in _dailyPrayers.keys) {
        _qazaPrayers[key] = prefs.getInt('qaza_$key') ?? 0;
      }

      if (lastSavedDate != today) {
        // GÜN DEĞİŞMİŞ! Kaza hesaplaması yap
        DateTime lastDate = DateTime.parse(lastSavedDate);
        DateTime currentDate = DateTime.parse(today);
        int missedDays = currentDate.difference(lastDate).inDays;

        if (missedDays > 0) {
          for (var key in _dailyPrayers.keys) {
            // 1. Dünün (ilk kaçırılan günün) durumunu kontrol et
            bool wasDone = prefs.getBool('prayer_$key') ?? false;
            if (!wasDone) {
              _qazaPrayers[key] = _qazaPrayers[key]! + 1;
            }
            // 2. Eğer 1 günden fazla girilmediyse, aradaki günlerin hepsi kaza sayılır
            if (missedDays > 1) {
              _qazaPrayers[key] = _qazaPrayers[key]! + (missedDays - 1);
            }
            // Yeni kaza değerini kaydet
            prefs.setInt('qaza_$key', _qazaPrayers[key]!);
            
            // Bugünü sıfırla
            _dailyPrayers[key] = false;
            prefs.setBool('prayer_$key', false);
          }
        }
        prefs.setString('lastPrayerDate', today);
        prefs.setBool('wasPerfectToday', false);
      } else {
        // Gün değişmediyse bugünün işaretlerini çek
        for (var key in _dailyPrayers.keys) {
          _dailyPrayers[key] = prefs.getBool('prayer_$key') ?? false;
        }
      }
    });
  }

  Future<void> _toggleDailyPrayer(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _dailyPrayers[key] = value);
    await prefs.setBool('prayer_$key', value);

    bool allCompleted = _dailyPrayers.values.every((v) => v == true);
    bool wasCompleted = prefs.getBool('wasPerfectToday') ?? false;

    if (allCompleted && !wasCompleted) {
      setState(() => _totalPerfectDays++);
      await prefs.setInt('perfectPrayerDays', _totalPerfectDays);
      await prefs.setBool('wasPerfectToday', true);
    } else if (!allCompleted && wasCompleted) {
      setState(() => _totalPerfectDays--);
      await prefs.setInt('perfectPrayerDays', _totalPerfectDays);
      await prefs.setBool('wasPerfectToday', false);
    }
  }

  Future<void> _updateQaza(String key, int change) async {
    final prefs = await SharedPreferences.getInstance();
    int newValue = (_qazaPrayers[key] ?? 0) + change;
    if (newValue < 0) return;
    setState(() => _qazaPrayers[key] = newValue);
    await prefs.setInt('qaza_$key', newValue);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color iconColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.mosque, size: 48, color: iconColor),
            const SizedBox(height: 10),
            const Text(
              '"Allah ibadetin az da olsa devamlı olanını sever."',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                const Text('PERFECT DAYS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2.0, color: Colors.grey)),
                Text('$_totalPerfectDays', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('DAILY PRAYERS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(thickness: 2, color: Colors.grey),
            ..._dailyPrayers.keys.map((String key) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: iconColor,
                checkColor: isDark ? Colors.black : Colors.white,
                title: Text(key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, decoration: _dailyPrayers[key]! ? TextDecoration.lineThrough : null)),
                value: _dailyPrayers[key],
                onChanged: (bool? value) {
                  if (value != null) _toggleDailyPrayer(key, value);
                },
              );
            }),
            const SizedBox(height: 30),
            const Align(alignment: Alignment.centerLeft, child: Text('QAZA (MISSED)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            const Divider(thickness: 2, color: Colors.grey),
            ..._qazaPrayers.keys.map((String key) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateQaza(key, -1)),
                        SizedBox(width: 30, child: Text('${_qazaPrayers[key]}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _updateQaza(key, 1)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}