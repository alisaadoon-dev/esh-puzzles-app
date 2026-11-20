// عش الألغاز - النسخة الأولى
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================
// الألوان والثوابت
// ============================================================
const Color kInk = Color(0xFF0D0A26);
const Color kGold = Color(0xFFFFC83D);
const Color kGoldDark = Color(0xFFE08A00);
const Color kPurpleTop = Color(0xFF3B1E8C);
const Color kPurpleBottom = Color(0xFF140A3A);
const Color kGreenTop = Color(0xFF4ADE80);
const Color kGreenBottom = Color(0xFF15803D);
const Color kVioletTop = Color(0xFF8C7BFF);
const Color kVioletBottom = Color(0xFF5B45E0);
const Color kOrangeTop = Color(0xFFFFA94D);
const Color kOrangeBottom = Color(0xFFE8590C);
const Color kGreyTop = Color(0xFF8A8FA3);
const Color kGreyBottom = Color(0xFF4B5063);

const int kLevels = 12; // مراحل عالم الغابة
const int kQuestions = 5; // أسئلة كل مرحلة
const int kHintCost = 10; // سعر التلميح
const int kSwitchCost = 50; // سعر تبديل الصديق
const int kStartCoins = 30;

// الأكواد السرية التي تنشرها في فيديوهات القناة
const Map<String, int> kSecretCodes = {
  'ESH50': 50,
  'BOOMA100': 100,
  'FOREST30': 30,
};

const String kChannelUrl = 'https://www.youtube.com/@esh.puzzles';

const List<String> kAllFrames = [
  'assets/characters/owl_normal.webp',
  'assets/characters/owl_blink.webp',
  'assets/characters/owl_wings.webp',
  'assets/characters/owl_happy.webp',
  'assets/characters/owl_sad.webp',
  'assets/characters/fox_normal.webp',
  'assets/characters/fox_blink.webp',
  'assets/characters/fox_happy.webp',
  'assets/characters/fox_sad.webp',
];

// ============================================================
// النصوص باللغات الثلاث
// ============================================================
const Map<String, Map<String, String>> kStrings = {
  'ar': {
    'appTitle': 'عش الألغاز',
    'play': 'العب',
    'chooseBuddy': 'اختر صديقك',
    'secretCode': 'الكود السري',
    'challenge': 'تحدَّ صديقك',
    'forest': 'عالم الغابة',
    'desert': 'الصحراء',
    'sea': 'البحر',
    'castle': 'القلعة',
    'space': 'الفضاء',
    'soon': 'قريباً',
    'level': 'المرحلة {n}',
    'qDiff': 'وين المختلف؟',
    'qLetter': 'وين الحرف المختلف؟',
    'qCount': 'كم {e} تشوف؟',
    'hint': 'تلميح',
    'win': 'أحسنت يا بطل!',
    'lose': 'ولا يهمك، جرّب مرة ثانية!',
    'next': 'التالي',
    'retry': 'إعادة',
    'map': 'الخريطة',
    'buddyCheer': 'أنا معك يا بطل!',
    'rivalTaunt': 'أراهن إنك ما تحلّها!',
    'buddyHappy': 'رائع!',
    'rivalSad': 'مو معقولة!',
    'buddySad': 'لا بأس، ركّز!',
    'rivalHappy': 'هاها! قلت لك!',
    'owl': 'البومة',
    'fox': 'الثعلب',
    'free': 'الاختيار الأول مجاني',
    'switchCost': 'التبديل بـ {n} عملة',
    'noCoins': 'عملاتك ما تكفي',
    'enterCode': 'اكتب الكود من فيديو القناة',
    'ok': 'تم',
    'cancel': 'إلغاء',
    'codeOk': 'مبروك! حصلت على {n} عملة',
    'codeBad': 'الكود غير صحيح',
    'codeUsed': 'استخدمت هذا الكود من قبل',
    'shareText': 'جرّب لعبة عش الألغاز وتحدّاني! وصلت المرحلة {n} 🦉',
    'copied': 'نسخنا الرسالة، الصقها لصديقك',
    'coinsEarned': '+{n}',
  },
  'en': {
    'appTitle': 'Puzzle Nest',
    'play': 'Play',
    'chooseBuddy': 'Choose your buddy',
    'secretCode': 'Secret code',
    'challenge': 'Challenge a friend',
    'forest': 'Forest World',
    'desert': 'Desert',
    'sea': 'Sea',
    'castle': 'Castle',
    'space': 'Space',
    'soon': 'Coming soon',
    'level': 'Level {n}',
    'qDiff': 'Find the odd one!',
    'qLetter': 'Find the different letter!',
    'qCount': 'How many {e} do you see?',
    'hint': 'Hint',
    'win': 'Well done, champ!',
    'lose': "Don't worry, try again!",
    'next': 'Next',
    'retry': 'Retry',
    'map': 'Map',
    'buddyCheer': "I'm with you, champ!",
    'rivalTaunt': "Bet you can't solve it!",
    'buddyHappy': 'Awesome!',
    'rivalSad': 'No way!',
    'buddySad': "It's ok, focus!",
    'rivalHappy': 'Haha! Told you!',
    'owl': 'Owl',
    'fox': 'Fox',
    'free': 'First pick is free',
    'switchCost': 'Switch for {n} coins',
    'noCoins': 'Not enough coins',
    'enterCode': 'Type the code from our video',
    'ok': 'OK',
    'cancel': 'Cancel',
    'codeOk': 'Yay! You got {n} coins',
    'codeBad': 'Wrong code',
    'codeUsed': 'Code already used',
    'shareText': 'Try Puzzle Nest and challenge me! I reached level {n} 🦉',
    'copied': 'Message copied, paste it to your friend',
    'coinsEarned': '+{n}',
  },
  'fr': {
    'appTitle': 'Le Nid des Énigmes',
    'play': 'Jouer',
    'chooseBuddy': 'Choisis ton ami',
    'secretCode': 'Code secret',
    'challenge': 'Défie un ami',
    'forest': 'La Forêt',
    'desert': 'Désert',
    'sea': 'Mer',
    'castle': 'Château',
    'space': 'Espace',
    'soon': 'Bientôt',
    'level': 'Niveau {n}',
    'qDiff': "Trouve l'intrus !",
    'qLetter': 'Trouve la lettre différente !',
    'qCount': 'Combien de {e} vois-tu ?',
    'hint': 'Indice',
    'win': 'Bravo, champion !',
    'lose': 'Pas grave, réessaie !',
    'next': 'Suivant',
    'retry': 'Rejouer',
    'map': 'Carte',
    'buddyCheer': 'Je suis avec toi !',
    'rivalTaunt': "Je parie que tu n'y arriveras pas !",
    'buddyHappy': 'Génial !',
    'rivalSad': 'Pas possible !',
    'buddySad': 'Pas grave, concentre-toi !',
    'rivalHappy': 'Haha ! Je te l’avais dit !',
    'owl': 'Hibou',
    'fox': 'Renard',
    'free': 'Le premier choix est gratuit',
    'switchCost': 'Changer pour {n} pièces',
    'noCoins': 'Pas assez de pièces',
    'enterCode': 'Tape le code de la vidéo',
    'ok': 'OK',
    'cancel': 'Annuler',
    'codeOk': 'Bravo ! Tu as gagné {n} pièces',
    'codeBad': 'Code incorrect',
    'codeUsed': 'Code déjà utilisé',
    'shareText': "Essaie Le Nid des Énigmes et défie-moi ! J'ai atteint le niveau {n} 🦉",
    'copied': 'Message copié, colle-le pour ton ami',
    'coinsEarned': '+{n}',
  },
};

const Map<String, String> kWorldEmoji = {
  'desert': '🐪',
  'sea': '🐙',
  'castle': '🏰',
  'space': '🚀',
};

// ============================================================
// بيانات الألغاز
// ============================================================
const List<List<String>> kEmojiPairs = [
  ['🐶', '🐱'],
  ['🍎', '🍅'],
  ['🌲', '🌳'],
  ['😀', '😃'],
  ['🐸', '🐢'],
  ['⭐', '🌟'],
  ['🍊', '🍑'],
  ['🐝', '🐞'],
  ['🌙', '⭐'],
  ['🐵', '🙈'],
  ['🚗', '🚕'],
  ['🍪', '🍩'],
  ['🐔', '🐤'],
  ['🍌', '🌽'],
  ['🎈', '🎀'],
  ['🐟', '🐠'],
];

const Map<String, List<List<String>>> kLetterPairs = {
  'ar': [
    ['ب', 'ت'],
    ['ج', 'خ'],
    ['د', 'ذ'],
    ['ر', 'ز'],
    ['س', 'ش'],
    ['ص', 'ض'],
    ['ط', 'ظ'],
    ['ع', 'غ'],
    ['ف', 'ق'],
    ['6', '9'],
    ['3', '8'],
  ],
  'en': [
    ['b', 'd'],
    ['p', 'q'],
    ['m', 'n'],
    ['O', 'Q'],
    ['E', 'F'],
    ['u', 'v'],
    ['6', '9'],
    ['3', '8'],
  ],
  'fr': [
    ['b', 'd'],
    ['p', 'q'],
    ['m', 'n'],
    ['O', 'Q'],
    ['E', 'F'],
    ['é', 'è'],
    ['6', '9'],
    ['3', '8'],
  ],
};

const List<String> kCountEmojis = [
  '🍎', '🌟', '🐞', '🍓', '🦋', '🐟', '🌸', '🍄', '🐤', '🎈',
];

// ============================================================
// التخزين: العملات والنجوم واللغة والصديق
// ============================================================
class Store extends ChangeNotifier {
  Store(this._p);
  final SharedPreferences _p;

  int get coins => _p.getInt('coins') ?? kStartCoins;
  String get lang => _p.getString('lang') ?? 'ar';
  String get buddy => _p.getString('buddy') ?? 'owl';
  String get rival => buddy == 'owl' ? 'fox' : 'owl';
  bool get buddyChosen => _p.getBool('buddyChosen') ?? false;

  int stars(int level) => _p.getInt('stars_$level') ?? 0;
  bool unlocked(int level) => level == 1 || stars(level - 1) > 0;

  int get maxLevel {
    var m = 1;
    for (var i = 1; i <= kLevels; i++) {
      if (unlocked(i)) m = i;
    }
    return m;
  }

  String t(String key) =>
      kStrings[lang]?[key] ?? kStrings['ar']![key] ?? key;

  Future<void> addCoins(int n) async {
    await _p.setInt('coins', max(0, coins + n));
    notifyListeners();
  }

  Future<bool> spend(int n) async {
    if (coins < n) return false;
    await _p.setInt('coins', coins - n);
    notifyListeners();
    return true;
  }

  Future<void> setLang(String l) async {
    await _p.setString('lang', l);
    notifyListeners();
  }

  Future<void> setBuddy(String b) async {
    await _p.setString('buddy', b);
    await _p.setBool('buddyChosen', true);
    notifyListeners();
  }

  Future<void> saveStars(int level, int s) async {
    if (s > stars(level)) {
      await _p.setInt('stars_$level', s);
    }
    notifyListeners();
  }

  bool codeUsed(String c) => (_p.getStringList('codes') ?? const []).contains(c);

  Future<void> markCode(String c) async {
    final list = List<String>.from(_p.getStringList('codes') ?? const []);
    list.add(c);
    await _p.setStringList('codes', list);
  }
}

class StoreScope extends InheritedNotifier<Store> {
  const StoreScope({super.key, required Store store, required super.child})
      : super(notifier: store);

  static Store of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static Store read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

// ============================================================
// التشغيل
// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  runApp(EshApp(store: Store(prefs)));
}

class EshApp extends StatelessWidget {
  const EshApp({super.key, required this.store});
  final Store store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Esh Puzzles',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: kVioletBottom,
          ),
          builder: (context, child) => Directionality(
            textDirection:
                store.lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

// ============================================================
// عناصر الواجهة المشتركة
// ============================================================
class GameBackground extends StatelessWidget {
  const GameBackground({
    super.key,
    required this.child,
    this.colors = const [kPurpleTop, kPurpleBottom],
  });
  final Widget child;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}

/// زر بشكل ثلاثي الأبعاد ينضغط عند اللمس
class Btn3D extends StatefulWidget {
  const Btn3D({
    super.key,
    required this.child,
    required this.onTap,
    required this.width,
    this.height = 64,
    this.top = kGreenTop,
    this.bottom = kGreenBottom,
    this.radius = 22,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final Color top;
  final Color bottom;
  final double radius;

  @override
  State<Btn3D> createState() => _Btn3DState();
}

class _Btn3DState extends State<Btn3D> {
  static const double _depth = 6;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        if (widget.onTap != null) {
          HapticFeedback.lightImpact();
          widget.onTap!();
        }
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height + _depth,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.height,
              child: Container(
                decoration: BoxDecoration(
                  color: kInk,
                  borderRadius: BorderRadius.circular(widget.radius),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              left: 0,
              right: 0,
              top: _down ? _depth : 0,
              height: widget.height,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.top, widget.bottom],
                  ),
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: Border.all(color: kInk, width: 3),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: kInk, offset: Offset(0, 2))],
                  ),
                  child: FittedBox(fit: BoxFit.scaleDown, child: widget.child),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عنوان ذهبي بارز
class GoldTitle extends StatelessWidget {
  const GoldTitle(this.text, {super.key, this.size = 44});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w900,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size / 6
                ..color = kInk,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w900,
              color: kGold,
              shadows: const [Shadow(color: kGoldDark, offset: Offset(0, 3))],
            ),
          ),
        ],
      ),
    );
  }
}

/// عملة عليها صورة البومة
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(colors: [Color(0xFFFFE27A), kGoldDark]),
        border: Border.all(color: kInk, width: 2),
      ),
      child: Text('🦉', style: TextStyle(fontSize: size * 0.55)),
    );
  }
}

class CoinCounter extends StatelessWidget {
  const CoinCounter({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kGold, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 28),
          const SizedBox(width: 6),
          Text(
            '${s.coins}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.maxWidth = 150});
  final String text;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kInk, width: 2.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kInk,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// الشخصيات المتحركة: رمش، رفرفة، قفز
// ============================================================
enum Mood { normal, happy, sad }

class Critter extends StatefulWidget {
  const Critter({
    super.key,
    required this.kind,
    this.mood = Mood.normal,
    this.height = 150,
    this.bubble,
    this.bubbleWidth = 150,
  });
  final String kind; // owl أو fox
  final Mood mood;
  final double height;
  final String? bubble;
  final double bubbleWidth;

  @override
  State<Critter> createState() => _CritterState();
}

class _CritterState extends State<Critter> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);
  final Random _rnd = Random();
  Timer? _timer;
  String _frame = 'normal';

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: 1800 + _rnd.nextInt(2200)), () async {
      if (!mounted) return;
      if (widget.mood == Mood.normal) {
        final flap = widget.kind == 'owl' && _rnd.nextInt(3) == 0;
        setState(() => _frame = flap ? 'wings' : 'blink');
        await Future<void>.delayed(Duration(milliseconds: flap ? 380 : 160));
        if (!mounted) return;
        setState(() => _frame = 'normal');
      }
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String img = _frame;
    double amp = 5;
    if (widget.mood == Mood.happy) {
      img = 'happy';
      amp = 16;
    } else if (widget.mood == Mood.sad) {
      img = 'sad';
      amp = 2;
    }
    if (img == 'wings' && widget.kind != 'owl') img = 'normal';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.bubble != null)
          SpeechBubble(text: widget.bubble!, maxWidth: widget.bubbleWidth),
        AnimatedBuilder(
          animation: _bob,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -amp * Curves.easeInOut.transform(_bob.value)),
            child: child,
          ),
          child: Image.asset(
            'assets/characters/${widget.kind}_$img.webp',
            height: widget.height,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ],
    );
  }
}

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontSize: 16)),
      duration: const Duration(seconds: 2),
    ));
}

// ============================================================
// الشاشة الرئيسية
// ============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_cached) {
      _cached = true;
      for (final f in kAllFrames) {
        precacheImage(AssetImage(f), context);
      }
    }
  }

  Future<bool> _chooseBuddy() async {
    final s = StoreScope.read(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => const BuddyDialog(),
    );
    if (!mounted || picked == null) return false;
    if (picked == s.buddy) {
      if (!s.buddyChosen) await s.setBuddy(picked);
      return true;
    }
    if (s.buddyChosen) {
      final ok = await s.spend(kSwitchCost);
      if (!ok) {
        if (mounted) showSnack(context, s.t('noCoins'));
        return false;
      }
    }
    await s.setBuddy(picked);
    return true;
  }

  Future<void> _play() async {
    final s = StoreScope.read(context);
    if (!s.buddyChosen) {
      final ok = await _chooseBuddy();
      if (!ok || !mounted) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MapScreen()),
    );
  }

  Future<void> _secretCode() async {
    final s = StoreScope.read(context);
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPurpleTop,
        title: Text(s.t('secretCode'),
            style: const TextStyle(color: kGold, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, fontSize: 22),
          decoration: InputDecoration(hintText: s.t('enterCode')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(s.t('ok')),
          ),
        ],
      ),
    );
    if (!mounted || code == null) return;
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return;
    final reward = kSecretCodes[c];
    if (reward == null) {
      showSnack(context, s.t('codeBad'));
      return;
    }
    if (s.codeUsed(c)) {
      showSnack(context, s.t('codeUsed'));
      return;
    }
    await s.markCode(c);
    await s.addCoins(reward);
    if (mounted) {
      showSnack(context, s.t('codeOk').replaceAll('{n}', '$reward'));
    }
  }

  Future<void> _challenge() async {
    final s = StoreScope.read(context);
    final text =
        '${s.t('shareText').replaceAll('{n}', '${s.maxLevel}')}\n$kChannelUrl';
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) showSnack(context, s.t('copied'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Scaffold(
      body: GameBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              const Row(
                children: [
                  CoinCounter(),
                  Spacer(),
                  LangButton(),
                ],
              ),
              const SizedBox(height: 12),
              GoldTitle(s.t('appTitle'), size: 46),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Critter(
                      kind: s.buddy,
                      height: 150,
                      bubble: s.t('buddyCheer'),
                      bubbleWidth: 140,
                    ),
                  ),
                  Expanded(
                    child: Critter(
                      kind: s.rival,
                      height: 140,
                      bubble: s.t('rivalTaunt'),
                      bubbleWidth: 140,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Btn3D(
                width: 260,
                height: 70,
                onTap: _play,
                child: Text('▶  ${s.t('play')}',
                    style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 14),
              Btn3D(
                width: 260,
                top: kVioletTop,
                bottom: kVioletBottom,
                onTap: _chooseBuddy,
                child: Text('🦉🦊  ${s.t('chooseBuddy')}'),
              ),
              const SizedBox(height: 14),
              Btn3D(
                width: 260,
                top: kOrangeTop,
                bottom: kOrangeBottom,
                onTap: _secretCode,
                child: Text('🔑  ${s.t('secretCode')}'),
              ),
              const SizedBox(height: 14),
              Btn3D(
                width: 260,
                top: const Color(0xFF25D366),
                bottom: const Color(0xFF128C4A),
                onTap: _challenge,
                child: Text('💬  ${s.t('challenge')}'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class LangButton extends StatelessWidget {
  const LangButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white, size: 32),
      onSelected: (v) => s.setLang(v),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'ar', child: Text('العربية')),
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'fr', child: Text('Français')),
      ],
    );
  }
}

class BuddyDialog extends StatelessWidget {
  const BuddyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    Widget option(String kind) {
      final selected = s.buddyChosen && s.buddy == kind;
      return Expanded(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(kind),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected ? const Color(0x33FFC83D) : const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? kGold : Colors.white24, width: 3),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/characters/${kind}_normal.webp', height: 100),
                const SizedBox(height: 6),
                Text(
                  s.t(kind),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: kPurpleTop,
      title: Text(
        s.t('chooseBuddy'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: kGold, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              option('owl'),
              const SizedBox(width: 10),
              option('fox'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (s.buddyChosen) const CoinIcon(size: 22),
              if (s.buddyChosen) const SizedBox(width: 6),
              Flexible(
                child: Text(
                  s.buddyChosen
                      ? s.t('switchCost').replaceAll('{n}', '$kSwitchCost')
                      : s.t('free'),
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// خريطة عالم الغابة
// ============================================================
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: Center(child: GoldTitle(title, size: 28))),
          const CoinCounter(),
        ],
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  static const List<double> _xs = [-0.55, 0.0, 0.55, 0.0];

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Scaffold(
      body: GameBackground(
        colors: const [Color(0xFF1F7A4D), Color(0xFF0A2A1C)],
        child: Column(
          children: [
            TopBar(title: '🌲 ${s.t('forest')}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  for (var i = 1; i <= kLevels; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Align(
                        alignment: Alignment(_xs[(i - 1) % 4], 0),
                        child: LevelNode(level: i),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final w in const ['desert', 'sea', 'castle', 'space'])
                          LockedWorld(name: s.t(w), emoji: kWorldEmoji[w]!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LevelNode extends StatelessWidget {
  const LevelNode({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final open = s.unlocked(level);
    final st = s.stars(level);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Btn3D(
          width: 86,
          height: 76,
          radius: 38,
          top: open ? const Color(0xFFFFD95A) : kGreyTop,
          bottom: open ? kGoldDark : kGreyBottom,
          onTap: open
              ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => PlayScreen(level: level)),
                  )
              : null,
          child: Text(
            open ? '$level' : '🔒',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(Icons.star_rounded,
                  size: 22, color: i < st ? kGold : Colors.white24),
          ],
        ),
      ],
    );
  }
}

class LockedWorld extends StatelessWidget {
  const LockedWorld({super.key, required this.name, required this.emoji});
  final String name;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x44000000),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Column(
        children: [
          Text('$emoji 🔒', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
          Text(s.t('soon'),
              style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }
}

// ============================================================
// توليد الألغاز
// ============================================================
enum PType { diff, letter, count }

class Puzzle {
  Puzzle({
    required this.type,
    required this.cells,
    required this.cols,
    required this.answer,
    this.options = const [],
    this.target = '',
  });
  final PType type;
  final List<String> cells; // خانات الشبكة ('' = خانة فارغة)
  final int cols;
  final int answer; // رقم الخانة المختلفة، أو العدد الصحيح
  final List<int> options; // خيارات العدّ
  final String target; // الشكل المطلوب عدّه
}

class PuzzleGen {
  PuzzleGen(this.level, this.lang);
  final int level;
  final String lang;
  final Random _r = Random();

  int get _cols => level <= 3 ? 3 : (level <= 8 ? 4 : 5);

  static const List<PType> _order = [
    PType.diff,
    PType.count,
    PType.letter,
    PType.diff,
    PType.count,
  ];

  Puzzle make(int index) {
    final t = _order[index % _order.length];
    return switch (t) {
      PType.diff => _diff(kEmojiPairs, PType.diff),
      PType.letter => _diff(kLetterPairs[lang] ?? kLetterPairs['ar']!, PType.letter),
      PType.count => _count(),
    };
  }

  Puzzle _diff(List<List<String>> pairs, PType type) {
    final pair = pairs[_r.nextInt(pairs.length)];
    final swap = _r.nextBool();
    final common = swap ? pair[1] : pair[0];
    final odd = swap ? pair[0] : pair[1];
    final cols = _cols;
    final n = cols * cols;
    final ans = _r.nextInt(n);
    final cells = List<String>.generate(n, (i) => i == ans ? odd : common);
    return Puzzle(type: type, cells: cells, cols: cols, answer: ans);
  }

  Puzzle _count() {
    final target = kCountEmojis[_r.nextInt(kCountEmojis.length)];
    var other = target;
    while (other == target) {
      other = kCountEmojis[_r.nextInt(kCountEmojis.length)];
    }
    const cols = 4;
    const total = cols * cols;
    final count = 2 + _r.nextInt(min(3 + level, 9)); // من 2 إلى 10
    final others = min(_r.nextInt(3 + level ~/ 3), total - count);
    final cells = List<String>.filled(total, '');
    final idx = List<int>.generate(total, (i) => i)..shuffle(_r);
    for (var i = 0; i < count; i++) {
      cells[idx[i]] = target;
    }
    for (var i = count; i < count + others; i++) {
      cells[idx[i]] = other;
    }
    final opts = <int>{count};
    while (opts.length < 3) {
      final d = count + _r.nextInt(5) - 2;
      if (d > 0) opts.add(d);
    }
    final options = opts.toList()..shuffle(_r);
    return Puzzle(
      type: PType.count,
      cells: cells,
      cols: cols,
      answer: count,
      options: options,
      target: target,
    );
  }
}

// ============================================================
// شاشة اللعب
// ============================================================
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.level});
  final int level;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late PuzzleGen _gen;
  late Puzzle _puzzle;
  int _q = 0;
  int _hearts = 3;
  int _mistakes = 0;
  int _correct = 0;
  bool _busy = false;
  int? _okCell;
  int? _okOption;
  final Set<int> _wrong = {};
  final Set<int> _wrongOpts = {};
  final Set<int> _hidden = {};
  Mood _buddyMood = Mood.normal;
  Mood _rivalMood = Mood.normal;
  String? _buddyLine;
  String? _rivalLine;
  Timer? _moodTimer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _gen = PuzzleGen(widget.level, StoreScope.read(context).lang);
      _newPuzzle();
    }
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    super.dispose();
  }

  void _newPuzzle() {
    _puzzle = _gen.make(_q);
    _wrong.clear();
    _wrongOpts.clear();
    _hidden.clear();
    _okCell = null;
    _okOption = null;
    _busy = false;
    _resetMoods();
  }

  void _resetMoods() {
    _buddyMood = Mood.normal;
    _rivalMood = Mood.normal;
    _buddyLine = null;
    _rivalLine = null;
  }

  Future<void> _answer(bool ok, {int? cell, int? option}) async {
    if (_busy) return;
    final s = StoreScope.read(context);
    _moodTimer?.cancel();
    if (ok) {
      HapticFeedback.mediumImpact();
      setState(() {
        _busy = true;
        _correct++;
        _okCell = cell;
        _okOption = option;
        _buddyMood = Mood.happy;
        _rivalMood = Mood.sad;
        _buddyLine = s.t('buddyHappy');
        _rivalLine = s.t('rivalSad');
      });
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      if (_q + 1 >= kQuestions) {
        await _finish(true);
      } else {
        setState(() {
          _q++;
          _newPuzzle();
        });
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hearts--;
        _mistakes++;
        if (cell != null) _wrong.add(cell);
        if (option != null) _wrongOpts.add(option);
        _buddyMood = Mood.sad;
        _rivalMood = Mood.happy;
        _buddyLine = s.t('buddySad');
        _rivalLine = s.t('rivalHappy');
      });
      if (_hearts <= 0) {
        setState(() => _busy = true);
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        await _finish(false);
        return;
      }
      _moodTimer = Timer(const Duration(milliseconds: 1300), () {
        if (mounted) setState(_resetMoods);
      });
    }
  }

  Future<void> _finish(bool won) async {
    final s = StoreScope.read(context);
    final nav = Navigator.of(context);
    final int stars = won ? max(1, min(3, 3 - _mistakes)) : 0;
    final coins = won ? _correct * 2 + stars * 10 : _correct * 2;
    await s.saveStars(widget.level, stars);
    await s.addCoins(coins);
    if (!mounted) return;
    nav.pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ResultScreen(
        level: widget.level,
        stars: stars,
        coins: coins,
        won: won,
      ),
    ));
  }

  Future<void> _hint() async {
    if (_busy) return;
    final s = StoreScope.read(context);
    if (_puzzle.type == PType.count) {
      final wrongLeft = _puzzle.options
          .where((o) => o != _puzzle.answer && !_wrongOpts.contains(o))
          .toList();
      if (wrongLeft.isEmpty) return;
      if (!await s.spend(kHintCost)) {
        if (mounted) showSnack(context, s.t('noCoins'));
        return;
      }
      if (!mounted) return;
      setState(() => _wrongOpts.add(wrongLeft.first));
    } else {
      final candidates = <int>[
        for (var i = 0; i < _puzzle.cells.length; i++)
          if (i != _puzzle.answer && !_hidden.contains(i) && !_wrong.contains(i)) i,
      ]..shuffle();
      if (candidates.length <= 1) return;
      if (!await s.spend(kHintCost)) {
        if (mounted) showSnack(context, s.t('noCoins'));
        return;
      }
      if (!mounted) return;
      setState(() => _hidden.addAll(candidates.take(candidates.length ~/ 2 + 1)));
    }
  }

  String _question(Store s) {
    return switch (_puzzle.type) {
      PType.diff => s.t('qDiff'),
      PType.letter => s.t('qLetter'),
      PType.count => s.t('qCount').replaceAll('{e}', _puzzle.target),
    };
  }

  Widget _tile(String v, List<Color> colors, double fontSize) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInk, width: 3),
        boxShadow: const [BoxShadow(color: kInk, offset: Offset(0, 4))],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            v,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: kInk,
            ),
          ),
        ),
      ),
    );
  }

  static const List<Color> _normalTile = [Colors.white, Color(0xFFE6E0FF)];
  static const List<Color> _okTile = [Color(0xFF86EFAC), Color(0xFF16A34A)];
  static const List<Color> _badTile = [Color(0xFFFCA5A5), Color(0xFFDC2626)];

  Widget _diffGrid() {
    final p = _puzzle;
    final fs = p.cols == 3 ? 46.0 : (p.cols == 4 ? 36.0 : 28.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: p.cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            padding: const EdgeInsets.all(12),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < p.cells.length; i++)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _hidden.contains(i) ? 0.12 : 1,
                  child: GestureDetector(
                    onTap: (_busy || _hidden.contains(i) || _wrong.contains(i))
                        ? null
                        : () => _answer(i == p.answer, cell: i),
                    child: _tile(
                      p.cells[i],
                      _okCell == i
                          ? _okTile
                          : (_wrong.contains(i) ? _badTile : _normalTile),
                      fs,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countArea() {
    final p = _puzzle;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: GridView.count(
                    crossAxisCount: p.cols,
                    padding: const EdgeInsets.all(8),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (final c in p.cells)
                        Center(
                          child: c.isEmpty
                              ? const SizedBox.shrink()
                              : FittedBox(
                                  child: Text(c, style: const TextStyle(fontSize: 38)),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 14,
          alignment: WrapAlignment.center,
          children: [
            for (final o in p.options)
              Btn3D(
                width: 88,
                height: 64,
                top: _okOption == o
                    ? const Color(0xFFFFD95A)
                    : (_wrongOpts.contains(o) ? kGreyTop : kVioletTop),
                bottom: _okOption == o
                    ? kGoldDark
                    : (_wrongOpts.contains(o) ? kGreyBottom : kVioletBottom),
                onTap: (_busy || _wrongOpts.contains(o))
                    ? null
                    : () => _answer(o == p.answer, option: o),
                child: Text('$o', style: const TextStyle(fontSize: 32)),
              ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            // الشريط العلوي
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text(
                    s.t('level').replaceAll('{n}', '${widget.level}'),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  for (var i = 0; i < 3; i++)
                    Text(i < _hearts ? '❤️' : '🤍', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  const CoinCounter(),
                ],
              ),
            ),
            // تقدّم الأسئلة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < kQuestions; i++)
                  Container(
                    width: 26,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i < _q ? kGold : (i == _q ? Colors.white : Colors.white24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // السؤال
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _question(s),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: kInk, offset: Offset(0, 3))],
                  ),
                ),
              ),
            ),
            // اللغز
            Expanded(
              child: _puzzle.type == PType.count ? _countArea() : _diffGrid(),
            ),
            // الشخصيات وزر التلميح
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Critter(
                      kind: s.buddy,
                      mood: _buddyMood,
                      height: 100,
                      bubble: _buddyLine,
                      bubbleWidth: 120,
                    ),
                  ),
                  Btn3D(
                    width: 120,
                    height: 56,
                    top: kVioletTop,
                    bottom: kVioletBottom,
                    onTap: _busy ? null : _hint,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('💡 ${s.t('hint')}', style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        const CoinIcon(size: 20),
                        const Text('$kHintCost', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Critter(
                      kind: s.rival,
                      mood: _rivalMood,
                      height: 95,
                      bubble: _rivalLine,
                      bubbleWidth: 120,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// شاشة النتيجة
// ============================================================
class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.level,
    required this.stars,
    required this.coins,
    required this.won,
  });
  final int level;
  final int stars;
  final int coins;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final nav = Navigator.of(context);
    return Scaffold(
      body: GameBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: CoinCounter(),
              ),
              const SizedBox(height: 8),
              GoldTitle(s.t(won ? 'win' : 'lose'), size: 34),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == 1 ? 18 : 0),
                      child: Icon(
                        Icons.star_rounded,
                        size: i == 1 ? 84 : 66,
                        color: i < stars ? kGold : Colors.white24,
                        shadows: const [Shadow(color: kInk, offset: Offset(0, 4))],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CoinIcon(size: 34),
                  const SizedBox(width: 8),
                  Text(
                    s.t('coinsEarned').replaceAll('{n}', '$coins'),
                    style: const TextStyle(
                        color: kGold, fontSize: 30, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Critter(
                      kind: s.buddy,
                      mood: won ? Mood.happy : Mood.sad,
                      height: 140,
                      bubble: s.t(won ? 'buddyHappy' : 'buddySad'),
                      bubbleWidth: 140,
                    ),
                  ),
                  Expanded(
                    child: Critter(
                      kind: s.rival,
                      mood: won ? Mood.sad : Mood.happy,
                      height: 130,
                      bubble: s.t(won ? 'rivalSad' : 'rivalHappy'),
                      bubbleWidth: 140,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (won && level < kLevels) ...[
                Btn3D(
                  width: 260,
                  height: 66,
                  onTap: () => nav.pushReplacement(MaterialPageRoute<void>(
                    builder: (_) => PlayScreen(level: level + 1),
                  )),
                  child: Text('${s.t('next')}  ▶', style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 14),
              ],
              Btn3D(
                width: 260,
                top: kOrangeTop,
                bottom: kOrangeBottom,
                onTap: () => nav.pushReplacement(MaterialPageRoute<void>(
                  builder: (_) => PlayScreen(level: level),
                )),
                child: Text('↻  ${s.t('retry')}'),
              ),
              const SizedBox(height: 14),
              Btn3D(
                width: 260,
                top: kVioletTop,
                bottom: kVioletBottom,
                onTap: () => nav.maybePop(),
                child: Text('🗺  ${s.t('map')}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
