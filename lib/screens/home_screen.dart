import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // To-Do listesi için değişkenler
  List<String> _todos = [];
  List<bool> _todoStates = [];
  final TextEditingController _todoController = TextEditingController();

  // Alışkanlıklar için değişkenler
  final Map<String, bool> _habits = {
    'Gym': false,
    'Meditation': false,
    'Reading': false,
    'Journal': false,
  };

  @override
  void initState() {
    super.initState();
    _loadData(); // Uygulama açıldığında verileri yükle
  }

  // SharedPreferences'tan verileri okuma
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _todos = prefs.getStringList('todos') ?? [];
      _todoStates = (prefs.getStringList('todoStates') ?? [])
          .map((e) => e == 'true')
          .toList();

      for (var key in _habits.keys) {
        _habits[key] = prefs.getBool('habit_$key') ?? false;
      }
    });
  }

  // To-Do verilerini kaydetme
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('todos', _todos);
    await prefs.setStringList(
        'todoStates', _todoStates.map((e) => e.toString()).toList());
  }

  // Alışkanlık verisini kaydetme
  Future<void> _saveHabit(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('habit_$key', value);
  }

  // Yeni görev ekleme (Maksimum 5)
  void _addTodo() {
    if (_todoController.text.isNotEmpty && _todos.length < 5) {
      setState(() {
        _todos.add(_todoController.text);
        _todoStates.add(false);
        _todoController.clear();
      });
      _saveTodos();
    }
  }

  // Görev silme
  void _deleteTodo(int index) {
    setState(() {
      _todos.removeAt(index);
      _todoStates.removeAt(index);
    });
    _saveTodos();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TO-DO BÖLÜMÜ ---
            const Text(
              'DAILY FOCUS',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // Görev Ekleme Alanı
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: const InputDecoration(
                      hintText: 'Add a task...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _todos.length < 5 ? _addTodo : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.add),
                )
              ],
            ),
            const SizedBox(height: 10),
            
            // Görev Listesi
            Expanded(
              child: ListView.builder(
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: _todoStates[index],
                      activeColor: Colors.black,
                      onChanged: (bool? value) {
                        setState(() {
                          _todoStates[index] = value!;
                        });
                        _saveTodos();
                      },
                    ),
                    title: Text(
                      _todos[index],
                      style: TextStyle(
                        decoration: _todoStates[index]
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => _deleteTodo(index),
                    ),
                  );
                },
              ),
            ),

            // --- HABITS (ALIŞKANLIKLAR) BÖLÜMÜ ---
            const Divider(thickness: 2),
            const SizedBox(height: 10),
            const Text(
              'HABITS',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            // 4'lü Alışkanlık Grid'i
// 4'lü Alışkanlık Grid'i
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _habits.keys.map((String key) {
                bool isDone = _habits[key]!;
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _habits[key] = !isDone;
                    });
                    _saveHabit(key, !isDone);
                  },
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 50) / 2,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.black : Colors.white,
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        key,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ); // <--- InkWell burada düzgünce kapanıyor
                
              }).toList(), // <--- map fonksiyonu kapanıp listeye çevriliyor
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}