// lib/pet.dart
// نظام الحيوان الأليف للعبة «عش الألغاز»
// بيضة تفقس بالفوز بالمراحل، ثم يكبر الحيوان بالأكل الذي يشتريه الطفل بالعملات.
// نوع الأكل يحدد شكله النهائي (غابة / بحر / سحر)، وهو تفاعلي باللمس.
//
// يحتاج في pubspec.yaml:  shared_preferences: ^2.2.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────────────────── الإعدادات (غيّرها براحتك) ─────────────────────────

/// نقاط الخبرة المطلوبة لكل مرحلة: بيضة، صغير، يافع، كبير، أسطوري
const kStageXp = [0, 30, 100, 220, 400];

/// أقصى عدد وجبات في اليوم (حتى لا يلعب الطفل ساعات)
const kDailyFeedLimit = 10;

enum PetForm { none, forest, sea, magic }

enum FoodType { fruit, fish, sweet, golden }

enum Mood {
  idle, happy, giggle, purr, hug, dizzy, hungry, eating, yuck,
  sleeping, playing, held, flying, evolving,
}

class Food {
  final FoodType type;
  final String emoji;
  final int price;
  final int xp;
  const Food(this.type, this.emoji, this.price, this.xp);
}

const kFoods = [
  Food(FoodType.fruit, '🍎', 5, 10),
  Food(FoodType.fish, '🐟', 5, 10),
  Food(FoodType.sweet, '🍭', 5, 10),
  Food(FoodType.golden, '🌟', 0, 50), // الثمرة الذهبية: تُكسب من الزعيم فقط
];

/// الأكل المفضل لكل شكل (يرقص ويأخذ خبرة إضافية)
const kFavorite = {
  PetForm.forest: FoodType.fruit,
  PetForm.sea: FoodType.fish,
  PetForm.magic: FoodType.sweet,
};

/// الأكل الذي يرفضه كل شكل
const kDislike = {
  PetForm.forest: FoodType.fish,
  PetForm.sea: FoodType.sweet,
  PetForm.magic: FoodType.fruit,
};

const _strings = {
  'ar': {
    's0': 'بيضة', 's1': 'صغير', 's2': 'يافع', 's3': 'كبير', 's4': 'أسطوري',
    'feeds': 'وجبات اليوم',
    'noCoins': 'ما عندك عملات كافية!',
    'full': 'شبعَ اليوم! عُد غداً 😴',
    'egg': 'البيضة لا تأكل… اربح المراحل لتفقس!',
    'yuck': 'لا يحب هذا الأكل!',
    'noGolden': 'اهزم الزعيم لتربح الثمرة الذهبية',
    'evolved': 'تطوّر! 🎉',
    'nameTitle': 'سمِّ صديقك الجديد',
    'ok': 'تم',
    'defaultName': 'بندق',
  },
  'en': {
    's0': 'Egg', 's1': 'Baby', 's2': 'Young', 's3': 'Grown', 's4': 'Legendary',
    'feeds': 'Meals today',
    'noCoins': 'Not enough coins!',
    'full': 'Full for today! Come back tomorrow 😴',
    'egg': 'Eggs don\'t eat… win levels to hatch it!',
    'yuck': 'It doesn\'t like that!',
    'noGolden': 'Beat the boss to win a golden treat',
    'evolved': 'Evolved! 🎉',
    'nameTitle': 'Name your new friend',
    'ok': 'OK',
    'defaultName': 'Peanut',
  },
  'fr': {
    's0': 'Œuf', 's1': 'Bébé', 's2': 'Jeune', 's3': 'Grand', 's4': 'Légendaire',
    'feeds': 'Repas du jour',
    'noCoins': 'Pas assez de pièces !',
    'full': 'Rassasié ! Reviens demain 😴',
    'egg': 'Un œuf ne mange pas… gagne des niveaux pour l\'éclore !',
    'yuck': 'Il n\'aime pas ça !',
    'noGolden': 'Bats le boss pour gagner un trésor doré',
    'evolved': 'Évolution ! 🎉',
    'nameTitle': 'Nomme ton nouvel ami',
    'ok': 'OK',
    'defaultName': 'Noisette',
  },
};

// ───────────────────────── حفظ بيانات الحيوان ─────────────────────────

class PetStore {
  int xp = 0, fruit = 0, fish = 0, sweet = 0, golden = 0, feedsToday = 0;
  String name = '', feedDay = '';
  PetForm form = PetForm.none;

  int get stage {
    var s = 0;
    for (var i = 0; i < kStageXp.length; i++) {
      if (xp >= kStageXp[i]) s = i;
    }
    return s;
  }

  /// نسبة التقدم نحو المرحلة التالية (0..1)
  double get progress {
    final s = stage;
    if (s >= kStageXp.length - 1) return 1;
    return (xp - kStageXp[s]) / (kStageXp[s + 1] - kStageXp[s]);
  }

  // قدرات الحيوان داخل الألغاز — استعملها في شاشة اللعب
  bool get freeHint => stage >= 2; // تلميح مجاني يومياً
  bool get extraTime => stage >= 3; // ثوانٍ إضافية في مراحل الوقت
  bool get doubleCoins => stage >= 4; // مضاعفة العملات

  static String _today() => DateTime.now().toIso8601String().substring(0, 10);

  void resetDayIfNeeded() {
    if (feedDay != _today()) {
      feedDay = _today();
      feedsToday = 0;
    }
  }

  /// يحدد الشكل النهائي حسب أكثر أكل أكله
  void decideForm() {
    if (form != PetForm.none || stage < 2) return;
    if (fish > fruit && fish >= sweet) {
      form = PetForm.sea;
    } else if (sweet > fruit && sweet > fish) {
      form = PetForm.magic;
    } else {
      form = PetForm.forest;
    }
  }

  static Future<PetStore> load() async {
    final sp = await SharedPreferences.getInstance();
    final p = PetStore()
      ..xp = sp.getInt('pet_xp') ?? 0
      ..fruit = sp.getInt('pet_fruit') ?? 0
      ..fish = sp.getInt('pet_fish') ?? 0
      ..sweet = sp.getInt('pet_sweet') ?? 0
      ..golden = sp.getInt('pet_golden') ?? 0
      ..feedsToday = sp.getInt('pet_feeds') ?? 0
      ..feedDay = sp.getString('pet_day') ?? ''
      ..name = sp.getString('pet_name') ?? ''
      ..form = PetForm.values[sp.getInt('pet_form') ?? 0];
    return p;
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('pet_xp', xp);
    await sp.setInt('pet_fruit', fruit);
    await sp.setInt('pet_fish', fish);
    await sp.setInt('pet_sweet', sweet);
    await sp.setInt('pet_golden', golden);
    await sp.setInt('pet_feeds', feedsToday);
    await sp.setString('pet_day', feedDay);
    await sp.setString('pet_name', name);
    await sp.setInt('pet_form', form.index);
  }

  /// استدعها من شاشة اللعب عند الفوز بمرحلة.
  /// قبل الفقس كل مرحلة تدفّئ البيضة (+10)، وبعده تعطي خبرة قليلة (+2).
  /// الفوز على الزعيم يعطي ثمرة ذهبية.
  static Future<void> onLevelWon({bool boss = false}) async {
    final p = await load();
    p.xp += p.stage == 0 ? 10 : 2;
    if (boss) p.golden++;
    p.decideForm();
    await p.save();
  }
}

// ───────────────────────── شاشة الحيوان الأليف ─────────────────────────

class PetScreen extends StatefulWidget {
  final int coins;
  final ValueChanged<int> onCoinsChanged;

  /// اختياري: اربطه بمشغّل الأصوات في لعبتك. أسماء الأصوات:
  /// boop, giggle, purr, hug, whoosh, bounce, dizzy, eat, yum, yuck, evolve, hatch, egg_tap, no
  final void Function(String sound)? playSound;
  final String lang; // ar / en / fr

  const PetScreen({
    super.key,
    required this.coins,
    required this.onCoinsChanged,
    this.playSound,
    this.lang = 'ar',
  });

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _Particle {
  final String e;
  Offset p, v;
  final double born, life, size;
  _Particle(this.e, this.p, this.v, this.born, this.life, this.size);
}

class _PetScreenState extends State<PetScreen> with SingleTickerProviderStateMixin {
  PetStore? pet;
  late int coins;
  late final Ticker _ticker;
  final rnd = Random();

  double t = 0, _last = 0;
  Mood mood = Mood.idle;
  double moodStart = 0, moodEnd = 0;

  Offset petPos = Offset.zero, vel = Offset.zero;
  Offset _startPos = Offset.zero, _panStart = Offset.zero;
  bool dragging = false, flying = false, lifted = false;
  double pathLen = 0, lastTouch = 0;
  final List<double> taps = [];
  final List<_Particle> parts = [];
  Size area = Size.zero;
  String toast = '';
  double toastEnd = 0;
  String toy = '⚽';

  @override
  void initState() {
    super.initState();
    coins = widget.coins;
    _ticker = createTicker(_onTick)..start();
    PetStore.load().then((p) {
      if (!mounted) return;
      p.resetDayIfNeeded();
      setState(() => pet = p);
      if (p.stage >= 1 && p.name.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _hatch());
      }
    });
  }

  @override
  void didUpdateWidget(covariant PetScreen old) {
    super.didUpdateWidget(old);
    if (old.coins != widget.coins) coins = widget.coins;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // ───── أدوات مساعدة ─────
  String tr(String k) => (_strings[widget.lang] ?? _strings['ar']!)[k] ?? k;
  bool get isNight {
    final h = DateTime.now().hour;
    return h >= 21 || h < 6;
  }

  Mood get restMood => isNight ? Mood.sleeping : Mood.idle;
  void _setMood(Mood m, double secs) {
    mood = m;
    moodStart = t;
    moodEnd = t + secs;
  }

  void _sound(String s) => widget.playSound?.call(s);
  void _say(String key) {
    toast = tr(key);
    toastEnd = t + 2.5;
  }

  void _touch() => lastTouch = t;
  Offset get _center => Offset(area.width / 2, area.height / 2) + petPos;

  void _burst(String e, int n, {double speed = 120, double up = -80}) {
    for (var i = 0; i < n; i++) {
      final a = rnd.nextDouble() * 2 * pi;
      final s = speed * (0.5 + rnd.nextDouble());
      parts.add(_Particle(e, _center, Offset(cos(a) * s, sin(a) * s + up), t,
          1.0 + rnd.nextDouble(), 18 + rnd.nextDouble() * 16));
    }
  }

  // ───── كل إطار ─────
  void _onTick(Duration d) {
    final now = d.inMicroseconds / 1e6;
    final dt = (now - _last).clamp(0.0, 0.05).toDouble();
    _last = now;
    t = now;

    // حركة الرمي والرجوع للمكان
    if (!dragging && petPos != Offset.zero) {
      if (flying) {
        petPos += vel * dt;
        vel = vel * pow(0.15, dt).toDouble();
        final hx = area.width / 2 - 60, hy = area.height / 2 - 60;
        if (petPos.dx.abs() > hx) {
          petPos = Offset(petPos.dx.sign * hx, petPos.dy);
          vel = Offset(-vel.dx * 0.7, vel.dy);
          _sound('bounce');
          HapticFeedback.lightImpact();
        }
        if (petPos.dy.abs() > hy) {
          petPos = Offset(petPos.dx, petPos.dy.sign * hy);
          vel = Offset(vel.dx, -vel.dy * 0.7);
          _sound('bounce');
          HapticFeedback.lightImpact();
        }
        if (vel.distance < 80) {
          flying = false;
          _setMood(Mood.dizzy, 2.5);
          _sound('dizzy');
        }
      } else {
        petPos = Offset.lerp(petPos, Offset.zero, (dt * 6).clamp(0.0, 1.0).toDouble())!;
        if (petPos.distance < 0.5) petPos = Offset.zero;
      }
    }

    // الجزيئات (قلوب، نجوم، نوتات...)
    for (final p in parts) {
      p.p += p.v * dt;
      p.v = Offset(p.v.dx * 0.97, p.v.dy + 60 * dt);
    }
    parts.removeWhere((p) => t - p.born > p.life);

    // انتهاء الحالة المزاجية
    if (moodEnd == 0 || t > moodEnd) {
      if (!flying) {
        mood = restMood;
        moodEnd = 0;
      }
    }

    // يلعب وحده إذا تركه الطفل
    if (mood == Mood.idle && pet != null && pet!.stage > 0 &&
        t - lastTouch > 8 && rnd.nextDouble() < dt * 0.3) {
      toy = rnd.nextBool() ? '⚽' : '🦋';
      _setMood(Mood.playing, 4);
    }

    if (mounted) setState(() {});
  }

  // ───── اللمس ─────
  void _onTap() {
    _touch();
    taps.add(t);
    taps.removeWhere((x) => t - x > 1.0);
    if (pet!.stage == 0) {
      _setMood(Mood.happy, 0.6);
      _sound('egg_tap');
      HapticFeedback.selectionClick();
      return;
    }
    if (taps.length >= 4) {
      // دغدغة: لمسات سريعة
      _setMood(Mood.giggle, 1.5);
      _sound('giggle');
      HapticFeedback.mediumImpact();
      _burst('😂', 2);
    } else {
      _setMood(Mood.happy, 0.7);
      _sound('boop');
      HapticFeedback.lightImpact();
      _burst('⭐', 3);
    }
  }

  void _onLongPress() {
    _touch();
    _setMood(Mood.hug, 2);
    _sound('hug');
    HapticFeedback.mediumImpact();
    _burst('💖', 7, speed: 80, up: -120);
  }

  void _onPanStart(DragStartDetails d) {
    _touch();
    dragging = true;
    lifted = false;
    flying = false;
    pathLen = 0;
    _panStart = d.globalPosition;
    _startPos = petPos;
    vel = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _touch();
    pathLen += d.delta.distance;
    final net = d.globalPosition - _panStart;
    if (lifted || net.distance > 70) {
      // رفعه وسحبه
      if (!lifted) {
        lifted = true;
        _setMood(Mood.held, 60);
      }
      petPos = _startPos + net;
    } else if (pathLen > 220 && pet!.stage > 0) {
      // مسح ذهاباً وإياباً = تمسيد
      if (mood != Mood.purr) {
        _setMood(Mood.purr, 2);
        _sound('purr');
        HapticFeedback.lightImpact();
        _burst('🎵', 2, speed: 60);
      } else {
        moodEnd = t + 1.2;
      }
    }
  }

  void _onPanEnd(DragEndDetails d) {
    dragging = false;
    if (!lifted) return;
    final v = d.velocity.pixelsPerSecond;
    if (v.distance > 900) {
      vel = v;
      flying = true;
      _setMood(Mood.flying, 10);
      _sound('whoosh');
      HapticFeedback.heavyImpact();
    } else {
      _setMood(Mood.happy, 0.6);
    }
  }

  // ───── الأكل ─────
  void _feed(Food f) {
    final p = pet!;
    _touch();
    p.resetDayIfNeeded();

    if (p.stage == 0) {
      _say('egg');
      _sound('no');
      _setMood(Mood.happy, 0.6);
      return;
    }
    if (p.feedsToday >= kDailyFeedLimit) {
      _say('full');
      _sound('no');
      _setMood(Mood.purr, 1.5);
      return;
    }
    if (f.type == FoodType.golden) {
      if (p.golden <= 0) {
        _say('noGolden');
        _sound('no');
        return;
      }
      p.golden--;
    } else {
      if (p.form != PetForm.none && kDislike[p.form] == f.type) {
        _say('yuck');
        _sound('yuck');
        HapticFeedback.vibrate();
        _setMood(Mood.yuck, 1.5);
        return;
      }
      if (coins < f.price) {
        _say('noCoins');
        _sound('no');
        return;
      }
      coins -= f.price;
      widget.onCoinsChanged(coins);
      if (f.type == FoodType.fruit) p.fruit++;
      if (f.type == FoodType.fish) p.fish++;
      if (f.type == FoodType.sweet) p.sweet++;
    }

    final fav = p.form != PetForm.none && kFavorite[p.form] == f.type;
    final before = p.stage;
    p.feedsToday++;
    p.xp += f.xp + (fav ? 5 : 0);
    p.decideForm();
    p.save();

    _sound(fav ? 'yum' : 'eat');
    HapticFeedback.lightImpact();
    _setMood(Mood.eating, 1.2);
    _burst(fav ? '🎶' : '✨', fav ? 5 : 3, speed: 70);

    if (p.stage > before) {
      Future.delayed(const Duration(milliseconds: 1200), _evolve);
    }
  }

  void _evolve() {
    if (!mounted) return;
    _setMood(Mood.evolving, 2.5);
    _sound('evolve');
    HapticFeedback.heavyImpact();
    _burst('🎉', 12, speed: 260);
    _burst('✨', 15, speed: 200);
    toast = '${tr('evolved')}  ${tr('s${pet!.stage}')}';
    toastEnd = t + 3;
  }

  Future<void> _hatch() async {
    _setMood(Mood.evolving, 2.5);
    _sound('hatch');
    HapticFeedback.heavyImpact();
    _burst('🎉', 15, speed: 260);
    _burst('🥚', 4, speed: 150);
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    final c = TextEditingController(text: tr('defaultName'));
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(tr('nameTitle')),
        content: TextField(controller: c, maxLength: 12, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: Text(tr('ok')),
          ),
        ],
      ),
    );
    pet!.name = (name == null || name.isEmpty) ? tr('defaultName') : name;
    await pet!.save();
  }

  // ───── الرسم ─────
  String _emoji() {
    final p = pet!;
    if (p.stage == 0) return '🥚';
    if (p.stage == 1) return '🐣';
    final i = p.stage - 2;
    switch (p.form) {
      case PetForm.forest:
        return ['🦎', '🐊', '🐉'][i];
      case PetForm.sea:
        return ['🐠', '🐬', '🐋'][i];
      case PetForm.magic:
        return '🦄';
      case PetForm.none:
        return '🐥';
    }
  }

  /// يحاول صورة الحالة أولاً (مثل forest_3_happy.png)، ثم الصورة العادية،
  /// وإذا لم توجد صور يعرض إيموجي. هكذا تشتغل الشاشة قبل توليد الصور.
  Widget _petImage(double size) {
    final p = pet!;
    final base = p.stage == 0 ? 'egg' : '${p.form.name}_${p.stage}';
    Widget fallback() => Text(_emoji(), style: TextStyle(fontSize: size * 0.8));
    return Image.asset(
      'assets/pet/${base}_${mood.name}.png',
      width: size,
      height: size,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/pet/$base.png',
        width: size,
        height: size,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  static const _bubbles = {
    Mood.purr: '😌',
    Mood.hug: '🥰',
    Mood.hungry: '😋',
    Mood.eating: '😋',
    Mood.yuck: '🤢',
    Mood.sleeping: '💤',
    Mood.giggle: '😆',
    Mood.held: '😮',
  };

  Widget _petView(double size) {
    final p = pet!;
    final ph = moodEnd > moodStart
        ? ((t - moodStart) / (moodEnd - moodStart)).clamp(0.0, 1.0).toDouble()
        : 0.0;
    double dx = 0, dy = 0, rot = 0, sx = 1, sy = 1;
    final breath = sin(t * 2 * pi * (mood == Mood.sleeping ? 0.3 : 0.8));
    sy += 0.03 * breath;
    sx -= 0.015 * breath;

    switch (mood) {
      case Mood.happy:
        dy = -45 * sin(ph * pi);
        break;
      case Mood.giggle:
        rot = 0.18 * sin(t * 40);
        dy = -8 * sin(t * 20).abs();
        break;
      case Mood.purr:
        rot = 0.06 * sin(t * 5);
        sx *= 1.05;
        break;
      case Mood.hug:
        sx *= 1.15;
        sy *= 1.15;
        break;
      case Mood.dizzy:
        rot = 0.25 * sin(t * 7);
        break;
      case Mood.hungry:
        sy *= 1.06;
        dy = -6 * sin(t * 10).abs();
        break;
      case Mood.eating:
        sy *= 1 + 0.1 * sin(t * 25);
        sx *= 1 - 0.05 * sin(t * 25);
        break;
      case Mood.yuck:
        dx = 10 * sin(t * 50);
        break;
      case Mood.playing:
        dx = 70 * sin((t - moodStart) * 2);
        dy = -20 * sin((t - moodStart) * 4).abs();
        break;
      case Mood.held:
        rot = 0.15 * sin(t * 12);
        break;
      case Mood.flying:
        rot = t * 12;
        break;
      case Mood.evolving:
        final s = 1 + 0.4 * sin(ph * pi);
        sx *= s;
        sy *= s;
        rot = ph * 4 * pi;
        break;
      default:
        break;
    }

    final bubble = _bubbles[mood];
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // وهج التطور
        if (mood == Mood.evolving)
          Container(
            width: size * 1.6,
            height: size * 1.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.yellow.withOpacity(0.8 * sin(ph * pi)),
                Colors.transparent,
              ]),
            ),
          ),
        Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rot,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(sx, sy, 1),
              child: _petImage(size),
            ),
          ),
        ),
        if (p.stage == 4)
          Transform.translate(
            offset: Offset(dx, dy - size / 2 - 10),
            child: const Text('👑', style: TextStyle(fontSize: 30)),
          ),
        if (bubble != null)
          Transform.translate(
            offset: Offset(dx + size / 2, dy - size / 2),
            child: Text(bubble, style: const TextStyle(fontSize: 34)),
          ),
        // نجوم الدوخة
        if (mood == Mood.dizzy)
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(cos(t * 5 + i * 2.09) * 40,
                  -size / 2 - 5 + sin(t * 5 + i * 2.09) * 10),
              child: const Text('💫', style: TextStyle(fontSize: 22)),
            ),
        // لعبته وهو يلعب وحده
        if (mood == Mood.playing)
          Transform.translate(
            offset: toy == '⚽'
                ? Offset(dx + 55, size / 2 - 15 - 40 * sin(t * 6).abs())
                : Offset(dx + 50 * cos(t * 3), -size / 2 + 20 * sin(t * 6)),
            child: Text(toy, style: const TextStyle(fontSize: 30)),
          ),
      ],
    );
  }

  Widget _foodChip(Food f) {
    final p = pet!;
    final label = f.type == FoodType.golden ? '×${p.golden}' : '🪙${f.price}';
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(f.emoji, style: const TextStyle(fontSize: 36)),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
    return Draggable<Food>(
      data: f,
      feedback: Material(
        color: Colors.transparent,
        child: Text(f.emoji, style: const TextStyle(fontSize: 56)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: chip),
      child: chip,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = pet;
    if (p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final night = isNight;
    final size = 110.0 + p.stage * 22;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: night
                ? const [Color(0xFF0B1A4A), Color(0xFF2C3E8F)]
                : const [Color(0xFF7FD8FF), Color(0xFF8EE07A)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // الشريط العلوي
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.maybePop(context),
                ),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      '${p.name.isEmpty ? '?' : p.name} • ${tr('s${p.stage}')}',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: p.progress,
                        minHeight: 12,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation(Colors.amber),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tr('feeds')}: ${p.feedsToday}/$kDailyFeedLimit',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Text('🪙 $coins',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),

            // منطقة الحيوان
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                area = Size(c.maxWidth, c.maxHeight);
                final center = _center;
                final w = size + 120, h = size + 120;
                return Stack(clipBehavior: Clip.none, children: [
                  if (night)
                    const Positioned(top: 10, right: 20, child: Text('🌙', style: TextStyle(fontSize: 40))),
                  Positioned(
                    left: center.dx - w / 2,
                    top: center.dy - h / 2,
                    width: w,
                    height: h,
                    child: DragTarget<Food>(
                      onWillAcceptWithDetails: (_) {
                        _touch();
                        if (p.stage > 0) _setMood(Mood.hungry, 30);
                        return true;
                      },
                      onLeave: (_) {
                        if (mood == Mood.hungry) moodEnd = t;
                      },
                      onAcceptWithDetails: (d) => _feed(d.data),
                      builder: (context, _, __) => GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _onTap,
                        onLongPress: _onLongPress,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Center(child: _petView(size)),
                      ),
                    ),
                  ),
                  for (final q in parts)
                    Positioned(
                      left: q.p.dx - q.size / 2,
                      top: q.p.dy - q.size / 2,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (1 - (t - q.born) / q.life).clamp(0.0, 1.0).toDouble(),
                          child: Text(q.e, style: TextStyle(fontSize: q.size)),
                        ),
                      ),
                    ),
                  if (t < toastEnd)
                    Positioned(
                      top: 10,
                      left: 20,
                      right: 20,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(toast,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ),
                    ),
                ]);
              }),
            ),

            // صينية الأكل: يسحب الطفل الأكل إلى فم الحيوان
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: Colors.black12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [for (final f in kFoods) _foodChip(f)],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
