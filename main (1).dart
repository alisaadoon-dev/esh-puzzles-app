import 'package:flutter/material.dart';

void main() => runApp(const EshApp());

class EshApp extends StatelessWidget {
  const EshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عش الألغاز',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF9800)),
        useMaterial3: true,
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeScreen(),
    );
  }
}

// ---------------- الألغاز ----------------

class Puzzle {
  final String emoji;
  final String question;
  final List<String> options;
  final int answer; // رقم الجواب الصحيح داخل options
  const Puzzle(this.emoji, this.question, this.options, this.answer);
}

const List<Puzzle> allPuzzles = [
  Puzzle('🍎🍎🍎 + 🍎🍎', 'كم تفاحة صار المجموع؟', ['5', '4', '6', '3'], 0),
  Puzzle('🐶 🐱 🐭 🚗', 'أيّها ليس حيواناً؟', ['🚗', '🐶', '🐱', '🐭'], 0),
  Puzzle('🦷', 'ما الشيء الذي له أسنان ولا يعض؟', ['المشط', 'القلم', 'الكتاب', 'الكرسي'], 0),
  Puzzle('2 ، 4 ، 6 ، ؟', 'ما الرقم التالي؟', ['8', '7', '9', '10'], 0),
  Puzzle('🕷️', 'كم رِجلاً للعنكبوت؟', ['8', '6', '4', '10'], 0),
  Puzzle('🍌', 'ما لون الموز الناضج؟', ['أصفر', 'أزرق', 'أحمر', 'بنفسجي'], 0),
  Puzzle('🕳️', 'شيء كلما أخذت منه كَبُر، ما هو؟', ['الحفرة', 'البحر', 'الشجرة', 'الجبل'], 0),
  Puzzle('📅', 'كم يوماً في الأسبوع؟', ['7', '5', '6', '8'], 0),
  Puzzle('🔺', 'كم ضلعاً للمثلث؟', ['3', '4', '2', '5'], 0),
  Puzzle('🏜️', 'أيّ حيوان يُسمّى سفينة الصحراء؟', ['الجمل', 'الحصان', 'الأسد', 'الفيل'], 0),
  Puzzle('☁️', 'يمشي بلا أرجل، ويبكي بلا عيون. ما هو؟', ['السحاب', 'النهر', 'الريح', 'القمر'], 0),
  Puzzle('🐟🐟🐟🐟 − 🐟', 'كم سمكة بقيت؟', ['3', '4', '2', '5'], 0),
  Puzzle('🧵', 'ما الشيء الذي له عين ولا يرى؟', ['الإبرة', 'الباب', 'الساعة', 'الكرة'], 0),
  Puzzle('🍓', 'أيّ فاكهة لونها أحمر؟', ['الفراولة', 'الموز', 'الليمون', 'الكيوي'], 0),
  Puzzle('🌙', 'متى يظهر القمر غالباً؟', ['في الليل', 'في الظهر', 'في الصباح', 'لا يظهر أبداً'], 0),
  Puzzle('🐝', 'ماذا تصنع النحلة؟', ['العسل', 'الحليب', 'الخبز', 'العصير'], 0),
  Puzzle('✋', 'كم إصبعاً في اليد الواحدة؟', ['5', '4', '6', '10'], 0),
  Puzzle('10 − 3', 'كم الناتج؟', ['7', '6', '8', '13'], 0),
];

// ---------------- الشاشة الرئيسية ----------------

const _bg = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFE082), Color(0xFFFFB74D)],
  ),
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _bg,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🧩', style: TextStyle(fontSize: 100)),
                  const SizedBox(height: 12),
                  const Text(
                    'عش الألغاز',
                    style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ألغاز ممتعة للأطفال الأذكياء',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, color: Color(0xFF6D4C41)),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                      ),
                      child: const Text('ابدأ اللعب ▶'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- شاشة الأسئلة ----------------

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int questionsPerGame = 10;

  late final List<Puzzle> _questions;
  late List<String> _options;
  int _index = 0;
  int _score = 0;
  int? _selected;

  Puzzle get _current => _questions[_index];
  String get _correct => _current.options[_current.answer];

  @override
  void initState() {
    super.initState();
    final shuffled = List<Puzzle>.from(allPuzzles)..shuffle();
    _questions = shuffled.take(questionsPerGame).toList();
    _prepare();
  }

  void _prepare() {
    _options = List<String>.from(_current.options)..shuffle();
    _selected = null;
  }

  void _choose(int i) {
    if (_selected != null) return;
    setState(() {
      _selected = i;
      if (_options[i] == _correct) _score++;
    });
  }

  void _next() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _prepare();
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(score: _score, total: _questions.length),
        ),
      );
    }
  }

  Color _optionColor(int i) {
    if (_selected == null) return Colors.white;
    if (_options[i] == _correct) return const Color(0xFFA5D6A7);
    if (i == _selected) return const Color(0xFFEF9A9A);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final answered = _selected != null;
    final wasRight = answered && _options[_selected!] == _correct;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE082),
        title: Text('سؤال ${_index + 1} من ${_questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text('⭐ $_score', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: _bg,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: (_index + 1) / _questions.length,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 24),
                Text(_current.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  _current.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
                ),
                const SizedBox(height: 24),
                for (int i = 0; i < _options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _optionColor(i),
                          foregroundColor: Colors.black87,
                          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _choose(i),
                        child: Text(_options[i]),
                      ),
                    ),
                  ),
                if (answered) ...[
                  const SizedBox(height: 8),
                  Text(
                    wasRight ? '🎉 أحسنت!' : '😅 الجواب الصحيح: $_correct',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: wasRight ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _next,
                      child: Text(_index < _questions.length - 1 ? 'السؤال التالي ⬅' : 'النتيجة 🏆'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- شاشة النتيجة ----------------

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  const ResultScreen({super.key, required this.score, required this.total});

  int get _stars {
    final ratio = score / total;
    if (ratio >= 0.9) return 3;
    if (ratio >= 0.6) return 2;
    if (ratio >= 0.3) return 1;
    return 0;
  }

  String get _message {
    switch (_stars) {
      case 3:
        return 'ممتاز! أنت عبقري صغير 🤩';
      case 2:
        return 'رائع! أنت ذكي جداً 😄';
      case 1:
        return 'جيد! جرّب مرة أخرى 💪';
      default:
        return 'لا بأس، المحاولة القادمة أفضل 🌱';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _bg,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 90)),
                  const SizedBox(height: 8),
                  Text(
                    '⭐' * _stars + '☆' * (3 - _stars),
                    style: const TextStyle(fontSize: 48, color: Color(0xFFF57F17)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نتيجتك: $score من $total',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
                  ),
                  const SizedBox(height: 8),
                  Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                      ),
                      child: const Text('العب مرة أخرى 🔄'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Text('الرئيسية 🏠', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
