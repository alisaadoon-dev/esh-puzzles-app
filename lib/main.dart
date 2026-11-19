import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const EshApp());
}

// ---------------- الألغاز ----------------

class Puzzle {
  final String q; // السؤال
  final String a; // الجواب الصحيح
  final List<String> w; // أجوبة خاطئة
  const Puzzle(this.q, this.a, this.w);
}

const List<Puzzle> allPuzzles = [
  // ألغاز
  Puzzle('ما الشيء الذي له أسنان ولا يعض؟', 'المشط', ['الأسد', 'الكرسي', 'الكتاب']),
  Puzzle('ما الشيء الذي يكتب ولا يقرأ؟', 'القلم', ['الكتاب', 'المعلم', 'الطاولة']),
  Puzzle('ما الشيء الذي كلما أخذت منه كبر؟', 'الحفرة', ['البالون', 'الشجرة', 'الكعكة']),
  Puzzle('ما الشيء الذي له عين ولا يرى؟', 'الإبرة', ['القطة', 'النظارة', 'الشمس']),
  Puzzle('ما الشيء الذي يمشي بلا أرجل ويبكي بلا عيون؟', 'السحاب', ['السمكة', 'الحجر', 'الكرسي']),
  Puzzle('شيء كلما زاد نقص، ما هو؟', 'العمر', ['المال', 'الطعام', 'الماء']),
  Puzzle('ما الشيء الذي له رأس ولا عيون له؟', 'الدبوس', ['السمكة', 'القطة', 'الولد']),
  Puzzle('ما الشيء الذي تراه في الليل ثلاث مرات وفي النهار مرة واحدة؟', 'حرف اللام', ['القمر', 'النجم', 'الشمس']),
  Puzzle('ما الذي يتكلم جميع اللغات ولا يتعلم أي لغة؟', 'الصدى', ['الببغاء', 'الكتاب', 'المعلم']),
  Puzzle('له أوراق وليس شجرة، وله جلد وليس حيواناً، ما هو؟', 'الكتاب', ['الحذاء', 'الحقيبة', 'الطاولة']),
  Puzzle('حرف يوجد في "القرن" مرة، وفي "الدقيقة" مرتين، ولا يوجد في "الساعة"؟', 'حرف القاف', ['حرف الدال', 'حرف النون', 'حرف الراء']),
  Puzzle('بيت ليس له أبواب ولا نوافذ، ما هو؟', 'البيضة', ['الخيمة', 'القفص', 'العش']),
  Puzzle('ما الشيء الذي تقطعه فتبكي عليه؟', 'البصل', ['الخبز', 'التفاح', 'الطماطم']),
  Puzzle('ما الشيء الذي يسمع بلا أذن ويتكلم بلا لسان؟', 'الهاتف', ['الكرسي', 'الشجرة', 'الحجر']),
  Puzzle('له رقبة وليس له رأس، ما هو؟', 'الزجاجة', ['الزرافة', 'البطة', 'الشمعة']),
  Puzzle('ما الشيء الذي يجري ولا يمشي؟', 'الماء', ['الحجر', 'الجبل', 'الشجرة']),
  Puzzle('ما الشيء الذي يقرصك ولا تراه؟', 'الجوع', ['القطة', 'الوردة', 'الكرسي']),
  Puzzle('ما الشيء الذي يحملك وتحمله؟', 'الحذاء', ['الكرسي', 'السيارة', 'السرير']),
  Puzzle('أيهما أثقل: كيلو قطن أم كيلو حديد؟', 'متساويان', ['كيلو الحديد', 'كيلو القطن', 'لا يمكن معرفة ذلك']),

  // حيوانات
  Puzzle('ما أكبر حيوان يعيش على اليابسة؟', 'الفيل', ['الزرافة', 'الأسد', 'الحصان']),
  Puzzle('ما أطول حيوان في العالم؟', 'الزرافة', ['الفيل', 'الجمل', 'الحصان']),
  Puzzle('أي حيوان يسمى سفينة الصحراء؟', 'الجمل', ['الحصان', 'الفيل', 'الأسد']),
  Puzzle('من هو ملك الغابة؟', 'الأسد', ['النمر', 'الفيل', 'الذئب']),
  Puzzle('كم رجلاً للعنكبوت؟', '8', ['6', '4', '10']),
  Puzzle('كم رجلاً للحشرة؟', '6', ['8', '4', '2']),
  Puzzle('كم رجلاً للدجاجة؟', '2', ['4', '3', '6']),
  Puzzle('ماذا تأكل البقرة؟', 'العشب', ['اللحم', 'السمك', 'الحلوى']),
  Puzzle('ما اسم صغير الدجاجة؟', 'الكتكوت', ['الجرو', 'الشبل', 'الحمل']),
  Puzzle('ما اسم صغير الأسد؟', 'الشبل', ['الجرو', 'المهر', 'الكتكوت']),
  Puzzle('ما اسم صغير الكلب؟', 'الجرو', ['الشبل', 'العجل', 'الحمل']),
  Puzzle('ما اسم صغير الحصان؟', 'المهر', ['الحمل', 'العجل', 'الشبل']),
  Puzzle('أي حيوان يعطينا الصوف؟', 'الخروف', ['البقرة', 'الدجاجة', 'الحصان']),
  Puzzle('أي طائر لا يستطيع الطيران؟', 'النعامة', ['الحمامة', 'العصفور', 'النسر']),
  Puzzle('أي حيوان يحمل بيته على ظهره؟', 'السلحفاة', ['الأرنب', 'القطة', 'الفأر']),
  Puzzle('ما أسرع حيوان يعيش على اليابسة؟', 'الفهد', ['الحصان', 'الأرنب', 'الأسد']),
  Puzzle('أي حيوان يغيّر لونه؟', 'الحرباء', ['الضفدع', 'الأرنب', 'الفأر']),
  Puzzle('أي حيوان ينام طوال الشتاء؟', 'الدب', ['الحصان', 'البقرة', 'الجمل']),
  Puzzle('أي حيوان يعيش في الماء ويتنفس بالخياشيم؟', 'السمكة', ['الحوت', 'البطة', 'القطة']),
  Puzzle('ماذا يصنع النحل؟', 'العسل', ['الحليب', 'الخبز', 'الجبن']),
  Puzzle('من أين نحصل على الحليب؟', 'البقرة', ['الدجاجة', 'السمكة', 'العصفور']),
  Puzzle('أي حيوان صوته "مواء"؟', 'القطة', ['الكلب', 'البقرة', 'الخروف']),
  Puzzle('ما اسم صوت الأسد؟', 'الزئير', ['النباح', 'الخوار', 'الصهيل']),
  Puzzle('ما اسم صوت الحصان؟', 'الصهيل', ['الزئير', 'النقيق', 'المواء']),
  Puzzle('ما اسم صوت الضفدع؟', 'النقيق', ['الصهيل', 'النباح', 'الخوار']),
  Puzzle('ما اسم صوت البقرة؟', 'الخوار', ['النباح', 'الزئير', 'الصهيل']),

  // علوم وطبيعة
  Puzzle('ما لون السماء في يوم صافٍ؟', 'أزرق', ['أحمر', 'أخضر', 'أصفر']),
  Puzzle('كم يوماً في الأسبوع؟', '7', ['5', '6', '10']),
  Puzzle('كم شهراً في السنة؟', '12', ['10', '11', '13']),
  Puzzle('كم فصلاً في السنة؟', '4', ['2', '3', '5']),
  Puzzle('في أي فصل تتساقط أوراق الشجر؟', 'الخريف', ['الربيع', 'الصيف', 'الشتاء']),
  Puzzle('في أي فصل يكون الجو أحرّ؟', 'الصيف', ['الشتاء', 'الخريف', 'الربيع']),
  Puzzle('من أي جهة تشرق الشمس؟', 'الشرق', ['الغرب', 'الشمال', 'الجنوب']),
  Puzzle('ما اسم الكوكب الذي نعيش عليه؟', 'الأرض', ['المريخ', 'زحل', 'المشتري']),
  Puzzle('ما لون الموز الناضج؟', 'أصفر', ['أزرق', 'بنفسجي', 'أسود']),
  Puzzle('كم إصبعاً في اليد الواحدة؟', '5', ['4', '6', '10']),
  Puzzle('بماذا نشم الروائح؟', 'الأنف', ['الأذن', 'العين', 'اليد']),
  Puzzle('بماذا نسمع الأصوات؟', 'الأذن', ['الأنف', 'الفم', 'القدم']),
  Puzzle('ما الذي يعطينا الضوء في النهار؟', 'الشمس', ['القمر', 'النجوم', 'المصباح']),
  Puzzle('إذا خلطنا اللون الأزرق مع الأصفر، ماذا نحصل؟', 'الأخضر', ['البرتقالي', 'البنفسجي', 'الأحمر']),
  Puzzle('إذا خلطنا اللون الأحمر مع الأصفر، ماذا نحصل؟', 'البرتقالي', ['الأخضر', 'الأزرق', 'البنفسجي']),
  Puzzle('الماء إذا تجمّد يصبح...', 'ثلجاً', ['بخاراً', 'رملاً', 'عصيراً']),
  Puzzle('كم لوناً في قوس قزح؟', '7', ['5', '6', '8']),
  Puzzle('أي فاكهة حمراء وعلى سطحها بذور صغيرة؟', 'الفراولة', ['الموز', 'البرتقال', 'العنب']),

  // حساب
  Puzzle('2 + 3 = ؟', '5', ['4', '6', '7']),
  Puzzle('7 + 2 = ؟', '9', ['8', '10', '11']),
  Puzzle('10 − 4 = ؟', '6', ['5', '7', '4']),
  Puzzle('3 × 3 = ؟', '9', ['6', '12', '8']),
  Puzzle('5 × 2 = ؟', '10', ['7', '12', '15']),
  Puzzle('12 − 5 = ؟', '7', ['6', '8', '5']),
  Puzzle('4 + 4 + 4 = ؟', '12', ['8', '10', '14']),
  Puzzle('20 ÷ 4 = ؟', '5', ['4', '6', '8']),
  Puzzle('6 × 7 = ؟', '42', ['36', '48', '49']),
  Puzzle('100 − 1 = ؟', '99', ['90', '101', '98']),
  Puzzle('ما العدد الذي يأتي بعد 19؟', '20', ['18', '21', '29']),
  Puzzle('أي عدد هو الأكبر؟', '31', ['13', '21', '30']),
  Puzzle('كم يساوي نصف العدد 10؟', '5', ['2', '4', '6']),
  Puzzle('عندك 3 تفاحات وأخذت تفاحتين، كم تفاحة صار عندك؟', '5', ['4', '6', '3']),
  Puzzle('كم ضلعاً للمثلث؟', '3', ['4', '5', '6']),
  Puzzle('كم ضلعاً للمربع؟', '4', ['3', '5', '6']),
  Puzzle('ما الشكل الذي ليس له أضلاع ولا زوايا؟', 'الدائرة', ['المربع', 'المثلث', 'المستطيل']),

  // ذكاء وكلمات
  Puzzle('ما عكس كلمة "كبير"؟', 'صغير', ['طويل', 'سريع', 'جميل']),
  Puzzle('ما عكس كلمة "ليل"؟', 'نهار', ['نجم', 'قمر', 'نوم']),
  Puzzle('ما عكس كلمة "حار"؟', 'بارد', ['كبير', 'سريع', 'أحمر']),
  Puzzle('ما الحرف الأول في كلمة "قمر"؟', 'ق', ['م', 'ر', 'ب']),
  Puzzle('ما الشهر الذي يأتي بعد يناير؟', 'فبراير', ['مارس', 'ديسمبر', 'أبريل']),
  Puzzle('ما اليوم الذي يأتي بعد الجمعة؟', 'السبت', ['الخميس', 'الأحد', 'الاثنين']),
  Puzzle('ما اليوم الذي يأتي قبل الأربعاء؟', 'الثلاثاء', ['الخميس', 'الاثنين', 'الأحد']),
  Puzzle('إذا كان أمس هو السبت، فما هو اليوم؟', 'الأحد', ['الجمعة', 'الاثنين', 'السبت']),
  Puzzle('أي كلمة لا تنتمي للمجموعة: تفاح، موز، جزر، عنب؟', 'جزر', ['تفاح', 'موز', 'عنب']),
  Puzzle('أي كلمة لا تنتمي للمجموعة: قطة، كلب، سيارة، أرنب؟', 'سيارة', ['قطة', 'كلب', 'أرنب']),
  Puzzle('أكمل: 2، 4، 6، ...', '8', ['7', '9', '10']),
  Puzzle('أكمل: 5، 10، 15، ...', '20', ['16', '25', '18']),
  Puzzle('أكمل: 1، 3، 5، 7، ...', '9', ['8', '10', '11']),
  Puzzle('أكمل: 10، 9، 8، ...', '7', ['6', '11', '5']),
];

// ---------------- الحفظ: لا تتكرر الأسئلة ----------------

class Store {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    Sfx.on = prefs.getBool('sound') ?? true;
  }

  static List<Puzzle> pick(int n) {
    final used = (prefs.getStringList('used') ?? []).map(int.tryParse).whereType<int>().toSet();
    var free = [for (var i = 0; i < allPuzzles.length; i++) if (!used.contains(i)) i];
    if (free.length < n) {
      used.clear();
      free = List.generate(allPuzzles.length, (i) => i);
    }
    free.shuffle();
    final chosen = free.take(n).toList();
    used.addAll(chosen);
    prefs.setStringList('used', used.map((e) => '$e').toList());
    return chosen.map((i) => allPuzzles[i]).toList();
  }

  static void setSound(bool v) {
    Sfx.on = v;
    prefs.setBool('sound', v);
  }
}

// ---------------- الأصوات (تُولَّد داخل التطبيق، بدون ملفات) ----------------

class Sfx {
  static bool on = true;
  static final AudioPlayer _player = AudioPlayer();

  static final Uint8List correct = _wav([[784, 0.09], [1047, 0.09], [1319, 0.18]]);
  static final Uint8List wrong = _wav([[330, 0.16], [247, 0.32]]);
  static final Uint8List win = _wav([[523, 0.12], [659, 0.12], [784, 0.12], [1047, 0.35]]);
  static final Uint8List tap = _wav([[880, 0.05]], vol: 0.25);

  static Future<void> play(Uint8List sound) async {
    if (!on) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(sound));
    } catch (_) {}
  }

  static Uint8List _wav(List<List<double>> notes, {double vol = 0.35}) {
    const sr = 22050;
    final samples = <int>[];
    for (final note in notes) {
      final f = note[0];
      final len = (sr * note[1]).round();
      for (var j = 0; j < len; j++) {
        final attack = min(1.0, j / 150);
        final release = 1 - j / len;
        final t = j / sr;
        final v = (sin(2 * pi * f * t) + 0.3 * sin(4 * pi * f * t)) / 1.3 * attack * release * vol;
        samples.add((v * 32767).round().clamp(-32768, 32767));
      }
    }
    final data = ByteData(44 + samples.length * 2);
    void str(int o, String s) {
      for (var k = 0; k < s.length; k++) {
        data.setUint8(o + k, s.codeUnitAt(k));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + samples.length * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sr, Endian.little);
    data.setUint32(28, sr * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, samples.length * 2, Endian.little);
    for (var k = 0; k < samples.length; k++) {
      data.setInt16(44 + k * 2, samples[k], Endian.little);
    }
    return data.buffer.asUint8List();
  }
}

// ---------------- التطبيق ----------------

const _bg = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
  ),
);
const _brown = Color(0xFF5D4037);

class EshApp extends StatelessWidget {
  const EshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عش الألغاز',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeScreen(),
    );
  }
}

// ---------------- الشاشة الرئيسية ----------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _bg,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  iconSize: 34,
                  color: _brown,
                  icon: Icon(Sfx.on ? Icons.volume_up : Icons.volume_off),
                  onPressed: () {
                    setState(() => Store.setSound(!Sfx.on));
                    Sfx.play(Sfx.tap);
                  },
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🧩', style: TextStyle(fontSize: 100)),
                      const SizedBox(height: 12),
                      const Text(
                        'عش الألغاز',
                        style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: _brown),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أكثر من ${allPuzzles.length} لغزاً ممتعاً للأطفال الأذكياء',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, color: Color(0xFF6D4C41)),
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
                          onPressed: () {
                            Sfx.play(Sfx.tap);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()))
                                .then((_) => setState(() {}));
                          },
                          child: const Text('ابدأ اللعب ▶'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
  static const int perGame = 10;

  late final List<Puzzle> _qs;
  late List<String> _opts;
  int _i = 0;
  int _score = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _qs = Store.pick(perGame);
    _prepare();
  }

  void _prepare() {
    _opts = [_qs[_i].a, ..._qs[_i].w]..shuffle();
    _picked = null;
  }

  Future<void> _choose(int k) async {
    if (_picked != null) return;
    final ok = _opts[k] == _qs[_i].a;
    setState(() {
      _picked = k;
      if (ok) _score++;
    });
    Sfx.play(ok ? Sfx.correct : Sfx.wrong);
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    if (_i + 1 < _qs.length) {
      setState(() {
        _i++;
        _prepare();
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(score: _score, total: _qs.length)),
      );
    }
  }

  Color _color(int k) {
    if (_picked == null) return Colors.white;
    if (_opts[k] == _qs[_i].a) return const Color(0xFF66BB6A);
    if (k == _picked) return const Color(0xFFEF5350);
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final p = _qs[_i];
    return Scaffold(
      body: Container(
        decoration: _bg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('سؤال ${_i + 1} من ${_qs.length}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _brown)),
                    const Spacer(),
                    Text('⭐ $_score', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _brown)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_i + 1) / _qs.length,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF43A047),
                  backgroundColor: Colors.white54,
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Text(
                    p.q,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _brown, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
                for (var k = 0; k < _opts.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 62,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color(k),
                          foregroundColor: _brown,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => _choose(k),
                        child: Text(_opts[k]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- شاشة النتيجة ----------------

class ResultScreen extends StatefulWidget {
  final int score;
  final int total;
  const ResultScreen({super.key, required this.score, required this.total});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    Sfx.play(widget.score * 2 >= widget.total ? Sfx.win : Sfx.wrong);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.score;
    final stars = s >= 9 ? 3 : (s >= 6 ? 2 : (s >= 3 ? 1 : 0));
    final msg = stars == 3
        ? 'رائع! أنت عبقري 🎉'
        : stars == 2
            ? 'أحسنت! أداء جميل 👏'
            : stars == 1
                ? 'جيد، حاول مرة أخرى 💪'
                : 'لا بأس، جرّب من جديد 🙂';
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var k = 0; k < 3; k++)
                        Icon(Icons.star_rounded, size: 72, color: k < stars ? Colors.amber : Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('$s من ${widget.total}',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _brown)),
                  const SizedBox(height: 8),
                  Text(msg, style: const TextStyle(fontSize: 26, color: _brown)),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Sfx.play(Sfx.tap);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const QuizScreen()));
                      },
                      child: const Text('العب مرة أخرى 🔄'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('الرئيسية', style: TextStyle(fontSize: 22, color: _brown)),
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
