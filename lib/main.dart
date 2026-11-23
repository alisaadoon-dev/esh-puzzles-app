// عش الألغاز - النسخة الأولى
import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pet.dart';

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

/// مجموعات لغز "أيها لا ينتمي"
const kGroups = <List<String>>[
  ['🍎', '🍌', '🍇', '🍓', '🍉', '🍒', '🍊', '🍍'], // فواكه
  ['🐶', '🐱', '🐰', '🦁', '🐯', '🐮', '🐷', '🐵'], // حيوانات
  ['🚗', '🚕', '🚌', '🚑', '🚒', '🚓', '🚜', '🏎'], // سيارات
  ['🐟', '🐠', '🐙', '🦀', '🐬', '🐳', '🦑', '🐡'], // بحر
  ['⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🎱', '🏓'], // كرات
  ['🥕', '🥦', '🌽', '🍆', '🥒', '🧅', '🥔', '🥬'], // خضار
  ['☀️', '🌧', '⛄', '🌈', '⛅', '🌪', '❄️', '⚡'], // طقس
  ['🎸', '🎹', '🥁', '🎺', '🎻', '🎷', '🪕'], // آلات موسيقية
  ['👕', '👖', '👗', '🧦', '🧢', '👟', '🧤', '🧣'], // ملابس
  ['🐞', '🐝', '🦋', '🐜', '🐛', '🦗', '🕷', '🐌'], // حشرات
];

/// مجموعات كائنات حية لا نخلطها معاً (حيوانات، بحر، حشرات)
const kLivingGroups = {1, 3, 9};

const int kWorldSize = 30; // مراحل كل عالم
const List<String> kWorlds = ['forest', 'desert', 'sea', 'castle', 'space'];
const int kLevels = kWorldSize * 5; // كل المراحل في العوالم الخمسة

int worldOf(int level) => min(max(0, (level - 1) ~/ kWorldSize), kWorlds.length - 1);
bool isBoss(int level) => level % kWorldSize == 0;

/// صعوبة المرحلة: الغابة تبدأ سهلة، وكل عالم بعدها يبدأ متوسطاً ويصل للأصعب
int diffLevel(int level) {
  final w = worldOf(level);
  if (w == 0) return level;
  final local = (level - 1) % kWorldSize;
  return min(30, 10 + w + (local * 20) ~/ (kWorldSize - 1));
}

/// ألوان وأشكال كل عالم
const Map<String, List<Color>> kWorldColors = {
  'forest': [Color(0xFF1F7A4D), Color(0xFF0A2A1C)],
  'desert': [Color(0xFFE8A23A), Color(0xFF7A3E0C)],
  'sea': [Color(0xFF1E88E5), Color(0xFF0A2547)],
  'castle': [Color(0xFF8E44AD), Color(0xFF2C0F3D)],
  'space': [Color(0xFF1A1A4E), Color(0xFF02020F)],
};
const Map<String, String> kWorldIcon = {
  'forest': '🌲', 'desert': '🐪', 'sea': '🐙', 'castle': '🏰', 'space': '🚀',
};
const Map<String, List<String>> kWorldItems = {
  'forest': ['🌲', '🍄', '🐿', '🦉', '🍂', '🌰', '🦔', '🐻'],
  'desert': ['🐪', '🌵', '🦂', '🌴', '☀️', '🏜', '🦎', '🐫'],
  'sea': ['🐙', '🐠', '🐳', '🦀', '🐚', '🐬', '🦑', '🐢'],
  'castle': ['🏰', '👑', '🗝', '🛡', '🐉', '💎', '🧙', '🦄'],
  'space': ['🚀', '🪐', '⭐', '🌙', '👽', '🛸', '☄️', '🌍'],
};

/// عدد الأسئلة يزيد مع المراحل
int questionsFor(int level) {
  final d = diffLevel(level);
  final n = d < 10 ? 5 : (d < 20 ? 6 : 7);
  return isBoss(level) ? n + 3 : n; // مرحلة الزعيم أطول
}

/// من المرحلة 11 يصير لكل سؤال وقت محدد (بالثواني)
int secondsFor(int level) {
  final d = diffLevel(level);
  return d < 11 ? 0 : max(8, 25 - (d - 11));
}
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
    'cat': "مشمش",
    'bunny': "قطن",
    'penguin': "ثلج",
    'dragon': "شرارة",
    'falcon': "برق",
    'gazelle': "ريم",
    'newBuddies': "أصدقاء جدد بالعملات",
    'myOwl': "بومتي تكبر",
    'vsMode': "تحدي العائلة",
    'p1': "لاعب 1",
    'p2': "لاعب 2",
    'wins': "فاز!",
    'playAgain': "مرة ثانية",
    'passport': "جواز السفر",
    'newStamp': "ختم جديد!",
    'catchIt': "امسكه!",
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
    'qSeq': 'شنو يجي بعدها؟',
    'parentsOnly': 'للكبار فقط 🔒',
    'parentAsk': 'اطلب من بابا أو ماما حل هذا السؤال:',
    'parents': 'ركن الأهل',
    'privacy': 'سياسة الخصوصية',
    'musicOpt': 'الموسيقى',
    'levelsDone': 'المراحل المكتملة',
    'starsTotal': 'مجموع النجوم',
    'channel': 'قناة عش الألغاز',
    'tapHere': 'اضغط هنا!',
    'privacyText': 'لعبة عش الألغاز لا تجمع أي معلومات شخصية عن طفلك. لا تسجيل دخول، ولا أسماء، ولا صور، ولا موقع. كل التقدم (المراحل والعملات) محفوظ على الهاتف فقط، ويُحذف عند حذف اللعبة. اللعبة تعمل بدون إنترنت، وتستخدمه فقط لتحميل الخط أول مرة. أي رابط يخرج من اللعبة محمي بسؤال للكبار. إذا أضيفت إعلانات مستقبلاً، فستكون من Google AdMob بإعدادات الأطفال، بدون إعلانات مخصصة.',
    'daily': 'لغز اليوم',
    'dailyDone': 'رجع باچر!',
    'qTF': 'صح لو غلط؟',
    'worlds': "العوالم",
    'boss': "الزعيم",
    'finishPrev': "أكمل العالم السابق أولاً",
    'qOdd': "منو الغريب بينهم؟",
    'qNumSeq': "شنو الرقم الناقص؟",
    'breakTitle': 'وقت الراحة!',
    'breakText': 'لعبت كثير اليوم يا بطل، البومة تعبانة وتريد تنام 😴 نكمل باچر!',
    'limit': 'وقت اللعب اليومي',
    'off': 'بلا حد',
    'min': 'دقيقة',
    'playedToday': 'لعب اليوم',
    'combo': 'رائع!',
    'shop': 'المتجر',
    'wear': 'البس',
    'takeOff': 'اخلع',
    'dailyGift': 'هدية اليوم!',
    'chestTitle': 'صندوق الكنز!',
    'tapOpen': 'اضغط حتى تفتحها',
    'collect': 'خذها',
    'qMath': 'احسبها!',
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
    'cat': "Kitty",
    'bunny': "Cotton",
    'penguin': "Snowy",
    'dragon': "Sparky",
    'falcon': "Flash",
    'gazelle': "Rima",
    'newBuddies': "New buddies for coins",
    'myOwl': "My owl grows",
    'vsMode': "Family battle",
    'p1': "Player 1",
    'p2': "Player 2",
    'wins': "wins!",
    'playAgain': "Play again",
    'passport': "Passport",
    'newStamp': "New stamp!",
    'catchIt': "Catch it!",
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
    'qSeq': 'What comes next?',
    'parentsOnly': 'Grown-ups only 🔒',
    'parentAsk': 'Ask a parent to answer this:',
    'parents': 'Parents corner',
    'privacy': 'Privacy policy',
    'musicOpt': 'Music',
    'levelsDone': 'Levels completed',
    'starsTotal': 'Total stars',
    'channel': 'Puzzle Nest channel',
    'tapHere': 'Tap here!',
    'privacyText': 'Puzzle Nest does not collect any personal information about your child. No sign-in, names, photos or location. All progress (levels and coins) is stored only on this device and is deleted when the game is removed. The game works offline and only uses the internet to download its font the first time. Any link leaving the game is protected by a grown-up question. If ads are added in the future, they will come from Google AdMob with child-directed settings and no personalized ads.',
    'daily': 'Daily puzzle',
    'dailyDone': 'Come back tomorrow!',
    'qTF': 'True or false?',
    'worlds': "Worlds",
    'boss': "Boss",
    'finishPrev': "Finish the previous world first",
    'qOdd': "Which one doesn't belong?",
    'qNumSeq': "Which number is missing?",
    'breakTitle': 'Break time!',
    'breakText': "You played a lot today, champ! Your buddy is sleepy 😴 See you tomorrow!",
    'limit': 'Daily play time',
    'off': 'No limit',
    'min': 'min',
    'playedToday': 'Played today',
    'combo': 'Awesome!',
    'shop': 'Shop',
    'wear': 'Wear',
    'takeOff': 'Remove',
    'dailyGift': 'Daily gift!',
    'chestTitle': 'Treasure chest!',
    'tapOpen': 'Tap to open',
    'collect': 'Collect',
    'qMath': 'Solve it!',
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
    'cat': "Minou",
    'bunny': "Coton",
    'penguin': "Flocon",
    'dragon': "Étincelle",
    'falcon': "Éclair",
    'gazelle': "Rima",
    'newBuddies': "Nouveaux amis contre des pièces",
    'myOwl': "Mon hibou grandit",
    'vsMode': "Duel en famille",
    'p1': "Joueur 1",
    'p2': "Joueur 2",
    'wins': "gagne !",
    'playAgain': "Rejouer",
    'passport': "Passeport",
    'newStamp': "Nouveau tampon !",
    'catchIt': "Attrape-le !",
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
    'qSeq': 'Quelle est la suite ?',
    'parentsOnly': 'Réservé aux adultes 🔒',
    'parentAsk': 'Demande à un parent de répondre :',
    'parents': 'Coin des parents',
    'privacy': 'Confidentialité',
    'musicOpt': 'Musique',
    'levelsDone': 'Niveaux terminés',
    'starsTotal': 'Total des étoiles',
    'channel': 'Chaîne Le Nid des Énigmes',
    'tapHere': 'Touche ici !',
    'privacyText': "Le Nid des Énigmes ne collecte aucune information personnelle sur votre enfant. Pas de connexion, de nom, de photo ni de position. Toute la progression (niveaux et pièces) est enregistrée uniquement sur cet appareil et supprimée avec le jeu. Le jeu fonctionne hors ligne et n'utilise internet que pour télécharger sa police la première fois. Tout lien sortant est protégé par une question pour adultes. Si des publicités sont ajoutées, elles viendront de Google AdMob, configuré pour les enfants, sans publicité personnalisée.",
    'daily': 'Énigme du jour',
    'dailyDone': 'Reviens demain !',
    'qTF': 'Vrai ou faux ?',
    'worlds': "Mondes",
    'boss': "Le boss",
    'finishPrev': "Termine d'abord le monde précédent",
    'qOdd': "Lequel n'est pas de la famille ?",
    'qNumSeq': "Quel nombre manque ?",
    'breakTitle': "C'est la pause !",
    'breakText': "Tu as beaucoup joué aujourd'hui ! Ton ami a sommeil 😴 À demain !",
    'limit': 'Temps de jeu par jour',
    'off': 'Sans limite',
    'min': 'min',
    'playedToday': "Joué aujourd'hui",
    'combo': 'Super !',
    'shop': 'Boutique',
    'wear': 'Porter',
    'takeOff': 'Enlever',
    'dailyGift': 'Cadeau du jour !',
    'chestTitle': 'Coffre au trésor !',
    'tapOpen': 'Touche pour ouvrir',
    'collect': 'Prendre',
    'qMath': 'Calcule !',
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
  'es': {
    'cat': "Michi",
    'bunny': "Algodón",
    'penguin': "Copito",
    'dragon': "Chispa",
    'falcon': "Rayo",
    'gazelle': "Rima",
    'newBuddies': "Nuevos amigos con monedas",
    'myOwl': "Mi búho crece",
    'vsMode': "Duelo familiar",
    'p1': "Jugador 1",
    'p2': "Jugador 2",
    'wins': "¡gana!",
    'playAgain': "Otra vez",
    'passport': "Pasaporte",
    'newStamp': "¡Nuevo sello!",
    'catchIt': "¡Atrápalo!",
    'appTitle': "Nido de Acertijos",
    'play': "Jugar",
    'chooseBuddy': "Elige a tu amigo",
    'secretCode': "Código secreto",
    'challenge': "Reta a un amigo",
    'forest': "Mundo Bosque",
    'desert': "Desierto",
    'sea': "Mar",
    'castle': "Castillo",
    'space': "Espacio",
    'soon': "Muy pronto",
    'level': "Nivel {n}",
    'qDiff': "¡Encuentra el diferente!",
    'qLetter': "¡Encuentra la letra diferente!",
    'qCount': "¿Cuántos {e} ves?",
    'qSeq': "¿Qué sigue?",
    'parentsOnly': "Solo adultos 🔒",
    'parentAsk': "Pide a un adulto que responda:",
    'parents': "Rincón de padres",
    'privacy': "Privacidad",
    'musicOpt': "Música",
    'levelsDone': "Niveles completados",
    'starsTotal': "Estrellas",
    'channel': "Canal Nido de Acertijos",
    'tapHere': "¡Toca aquí!",
    'privacyText': "Nido de Acertijos no recoge ninguna información personal de tu hijo. Sin registro, nombres, fotos ni ubicación. Todo el progreso se guarda solo en este dispositivo y se borra al eliminar el juego. El juego funciona sin conexión y solo usa internet para descargar su fuente la primera vez. Cualquier enlace externo está protegido por una pregunta para adultos. Si se añaden anuncios, serán de Google AdMob con configuración para niños y sin anuncios personalizados.",
    'daily': "Acertijo del día",
    'dailyDone': "¡Vuelve mañana!",
    'qTF': "¿Verdadero o falso?",
    'worlds': "Mundos",
    'boss': "Jefe",
    'finishPrev': "Termina primero el mundo anterior",
    'qOdd': "¿Cuál no pertenece al grupo?",
    'qNumSeq': "¿Qué número falta?",
    'breakTitle': "¡Hora de descansar!",
    'breakText': "¡Hoy jugaste mucho, campeón! Tu amigo tiene sueño 😴 ¡Hasta mañana!",
    'limit': "Tiempo de juego diario",
    'off': "Sin límite",
    'min': "min",
    'playedToday': "Jugado hoy",
    'combo': "¡Genial!",
    'shop': "Tienda",
    'wear': "Poner",
    'takeOff': "Quitar",
    'dailyGift': "¡Regalo del día!",
    'chestTitle': "¡Cofre del tesoro!",
    'tapOpen': "Toca para abrir",
    'collect': "Recoger",
    'qMath': "¡Resuélvelo!",
    'hint': "Pista",
    'win': "¡Muy bien, campeón!",
    'lose': "¡No pasa nada, inténtalo otra vez!",
    'next': "Siguiente",
    'retry': "Repetir",
    'map': "Mapa",
    'buddyCheer': "¡Estoy contigo, campeón!",
    'rivalTaunt': "¡Apuesto a que no puedes!",
    'buddyHappy': "¡Genial!",
    'rivalSad': "¡No puede ser!",
    'buddySad': "¡Tranquilo, concéntrate!",
    'rivalHappy': "¡Jaja! ¡Te lo dije!",
    'owl': "Búho",
    'fox': "Zorro",
    'free': "La primera elección es gratis",
    'switchCost': "Cambiar por {n} monedas",
    'noCoins': "No tienes suficientes monedas",
    'enterCode': "Escribe el código del video",
    'ok': "OK",
    'cancel': "Cancelar",
    'codeOk': "¡Bien! Ganaste {n} monedas",
    'codeBad': "Código incorrecto",
    'codeUsed': "Código ya usado",
    'shareText': "¡Prueba Nido de Acertijos y rétame! Llegué al nivel {n} 🦉",
    'copied': "Mensaje copiado, pégalo a tu amigo",
    'coinsEarned': "+{n}",
  },
  'pt': {
    'cat': "Mimi",
    'bunny': "Algodão",
    'penguin': "Floquinho",
    'dragon': "Faísca",
    'falcon': "Raio",
    'gazelle': "Rima",
    'newBuddies': "Novos amigos com moedas",
    'myOwl': "Minha coruja cresce",
    'vsMode': "Duelo em família",
    'p1': "Jogador 1",
    'p2': "Jogador 2",
    'wins': "venceu!",
    'playAgain': "Jogar de novo",
    'passport': "Passaporte",
    'newStamp': "Novo carimbo!",
    'catchIt': "Pegue!",
    'appTitle': "Ninho dos Enigmas",
    'play': "Jogar",
    'chooseBuddy': "Escolha seu amigo",
    'secretCode': "Código secreto",
    'challenge': "Desafie um amigo",
    'forest': "Mundo Floresta",
    'desert': "Deserto",
    'sea': "Mar",
    'castle': "Castelo",
    'space': "Espaço",
    'soon': "Em breve",
    'level': "Fase {n}",
    'qDiff': "Ache o diferente!",
    'qLetter': "Ache a letra diferente!",
    'qCount': "Quantos {e} você vê?",
    'qSeq': "O que vem depois?",
    'parentsOnly': "Só para adultos 🔒",
    'parentAsk': "Peça a um adulto para responder:",
    'parents': "Cantinho dos pais",
    'privacy': "Privacidade",
    'musicOpt': "Música",
    'levelsDone': "Fases concluídas",
    'starsTotal': "Estrelas",
    'channel': "Canal Ninho dos Enigmas",
    'tapHere': "Toque aqui!",
    'privacyText': "Ninho dos Enigmas não coleta nenhuma informação pessoal da sua criança. Sem login, nomes, fotos ou localização. Todo o progresso fica salvo apenas neste aparelho e é apagado ao remover o jogo. O jogo funciona offline e só usa a internet para baixar a fonte na primeira vez. Qualquer link externo é protegido por uma pergunta para adultos. Se anúncios forem adicionados, virão do Google AdMob com configurações para crianças e sem anúncios personalizados.",
    'daily': "Enigma do dia",
    'dailyDone': "Volte amanhã!",
    'qTF': "Verdadeiro ou falso?",
    'worlds': "Mundos",
    'boss': "Chefão",
    'finishPrev': "Termine o mundo anterior primeiro",
    'qOdd': "Qual não pertence ao grupo?",
    'qNumSeq': "Qual número falta?",
    'breakTitle': "Hora de descansar!",
    'breakText': "Você jogou muito hoje, campeão! Seu amigo está com sono 😴 Até amanhã!",
    'limit': "Tempo de jogo por dia",
    'off': "Sem limite",
    'min': "min",
    'playedToday': "Jogado hoje",
    'combo': "Incrível!",
    'shop': "Loja",
    'wear': "Usar",
    'takeOff': "Tirar",
    'dailyGift': "Presente do dia!",
    'chestTitle': "Baú do tesouro!",
    'tapOpen': "Toque para abrir",
    'collect': "Pegar",
    'qMath': "Resolva!",
    'hint': "Dica",
    'win': "Muito bem, campeão!",
    'lose': "Tudo bem, tente de novo!",
    'next': "Próxima",
    'retry': "Repetir",
    'map': "Mapa",
    'buddyCheer': "Estou com você, campeão!",
    'rivalTaunt': "Aposto que você não consegue!",
    'buddyHappy': "Incrível!",
    'rivalSad': "Não acredito!",
    'buddySad': "Calma, concentre-se!",
    'rivalHappy': "Haha! Eu falei!",
    'owl': "Coruja",
    'fox': "Raposa",
    'free': "A primeira escolha é grátis",
    'switchCost': "Trocar por {n} moedas",
    'noCoins': "Moedas insuficientes",
    'enterCode': "Digite o código do vídeo",
    'ok': "OK",
    'cancel': "Cancelar",
    'codeOk': "Oba! Você ganhou {n} moedas",
    'codeBad': "Código errado",
    'codeUsed': "Código já usado",
    'shareText': "Jogue Ninho dos Enigmas e me desafie! Cheguei à fase {n} 🦉",
    'copied': "Mensagem copiada, cole para seu amigo",
    'coinsEarned': "+{n}",
  },
  'tr': {
    'cat': "Minnoş",
    'bunny': "Pamuk",
    'penguin': "Kartopu",
    'dragon': "Kıvılcım",
    'falcon': "Şimşek",
    'gazelle': "Rima",
    'newBuddies': "Jetonla yeni arkadaşlar",
    'myOwl': "Baykuşum büyüyor",
    'vsMode': "Aile düellosu",
    'p1': "Oyuncu 1",
    'p2': "Oyuncu 2",
    'wins': "kazandı!",
    'playAgain': "Tekrar oyna",
    'passport': "Pasaport",
    'newStamp': "Yeni damga!",
    'catchIt': "Yakala!",
    'appTitle': "Bilmece Yuvası",
    'play': "Oyna",
    'chooseBuddy': "Arkadaşını seç",
    'secretCode': "Gizli kod",
    'challenge': "Arkadaşına meydan oku",
    'forest': "Orman Dünyası",
    'desert': "Çöl",
    'sea': "Deniz",
    'castle': "Kale",
    'space': "Uzay",
    'soon': "Çok yakında",
    'level': "Bölüm {n}",
    'qDiff': "Farklı olanı bul!",
    'qLetter': "Farklı harfi bul!",
    'qCount': "Kaç tane {e} görüyorsun?",
    'qSeq': "Sırada ne var?",
    'parentsOnly': "Sadece yetişkinler 🔒",
    'parentAsk': "Bir yetişkinden bunu cevaplamasını iste:",
    'parents': "Ebeveyn köşesi",
    'privacy': "Gizlilik",
    'musicOpt': "Müzik",
    'levelsDone': "Biten bölümler",
    'starsTotal': "Yıldızlar",
    'channel': "Bilmece Yuvası kanalı",
    'tapHere': "Buraya dokun!",
    'privacyText': "Bilmece Yuvası çocuğunuz hakkında hiçbir kişisel bilgi toplamaz. Giriş, isim, fotoğraf veya konum yoktur. Tüm ilerleme yalnızca bu cihazda saklanır ve oyun silinince silinir. Oyun çevrimdışı çalışır ve interneti yalnızca ilk seferde yazı tipini indirmek için kullanır. Oyundan çıkan her bağlantı yetişkin sorusuyla korunur. Reklam eklenirse, çocuk ayarlarıyla ve kişiselleştirilmemiş olarak Google AdMob tarafından sunulur.",
    'daily': "Günün bilmecesi",
    'dailyDone': "Yarın gel!",
    'qTF': "Doğru mu yanlış mı?",
    'worlds': "Dünyalar",
    'boss': "Patron",
    'finishPrev': "Önce önceki dünyayı bitir",
    'qOdd': "Hangisi gruba ait değil?",
    'qNumSeq': "Hangi sayı eksik?",
    'breakTitle': "Mola zamanı!",
    'breakText': "Bugün çok oynadın şampiyon! Arkadaşının uykusu geldi 😴 Yarın görüşürüz!",
    'limit': "Günlük oyun süresi",
    'off': "Sınırsız",
    'min': "dk",
    'playedToday': "Bugün",
    'combo': "Harika!",
    'shop': "Mağaza",
    'wear': "Giy",
    'takeOff': "Çıkar",
    'dailyGift': "Günün hediyesi!",
    'chestTitle': "Hazine sandığı!",
    'tapOpen': "Açmak için dokun",
    'collect': "Al",
    'qMath': "Çöz bakalım!",
    'hint': "İpucu",
    'win': "Aferin şampiyon!",
    'lose': "Sorun yok, tekrar dene!",
    'next': "Sonraki",
    'retry': "Tekrar",
    'map': "Harita",
    'buddyCheer': "Yanındayım şampiyon!",
    'rivalTaunt': "Bahse girerim çözemezsin!",
    'buddyHappy': "Harika!",
    'rivalSad': "Olamaz!",
    'buddySad': "Sorun yok, odaklan!",
    'rivalHappy': "Haha! Demiştim!",
    'owl': "Baykuş",
    'fox': "Tilki",
    'free': "İlk seçim ücretsiz",
    'switchCost': "{n} jetona değiştir",
    'noCoins': "Yeterli jeton yok",
    'enterCode': "Videodaki kodu yaz",
    'ok': "Tamam",
    'cancel': "İptal",
    'codeOk': "Yaşasın! {n} jeton kazandın",
    'codeBad': "Yanlış kod",
    'codeUsed': "Kod zaten kullanıldı",
    'shareText': "Bilmece Yuvası oyna ve bana meydan oku! {n}. bölüme geldim 🦉",
    'copied': "Mesaj kopyalandı, arkadaşına yapıştır",
    'coinsEarned': "+{n}",
  },
  'id': {
    'cat': "Meong",
    'bunny': "Kapas",
    'penguin': "Salju",
    'dragon': "Percik",
    'falcon': "Kilat",
    'gazelle': "Rima",
    'newBuddies': "Teman baru dengan koin",
    'myOwl': "Burung hantuku tumbuh",
    'vsMode': "Duel keluarga",
    'p1': "Pemain 1",
    'p2': "Pemain 2",
    'wins': "menang!",
    'playAgain': "Main lagi",
    'passport': "Paspor",
    'newStamp': "Cap baru!",
    'catchIt': "Tangkap!",
    'appTitle': "Sarang Teka-Teki",
    'play': "Main",
    'chooseBuddy': "Pilih temanmu",
    'secretCode': "Kode rahasia",
    'challenge': "Tantang teman",
    'forest': "Dunia Hutan",
    'desert': "Gurun",
    'sea': "Laut",
    'castle': "Kastel",
    'space': "Luar angkasa",
    'soon': "Segera hadir",
    'level': "Level {n}",
    'qDiff': "Cari yang berbeda!",
    'qLetter': "Cari huruf yang berbeda!",
    'qCount': "Ada berapa {e}?",
    'qSeq': "Apa selanjutnya?",
    'parentsOnly': "Khusus orang dewasa 🔒",
    'parentAsk': "Minta orang tua menjawab ini:",
    'parents': "Pojok orang tua",
    'privacy': "Privasi",
    'musicOpt': "Musik",
    'levelsDone': "Level selesai",
    'starsTotal': "Bintang",
    'channel': "Kanal Sarang Teka-Teki",
    'tapHere': "Ketuk di sini!",
    'privacyText': "Sarang Teka-Teki tidak mengumpulkan informasi pribadi apa pun tentang anak Anda. Tanpa login, nama, foto, atau lokasi. Semua kemajuan hanya disimpan di perangkat ini dan terhapus saat game dihapus. Game ini berjalan offline dan hanya memakai internet untuk mengunduh font pertama kali. Setiap tautan keluar dilindungi pertanyaan untuk orang dewasa. Jika iklan ditambahkan, iklan berasal dari Google AdMob dengan pengaturan anak dan tanpa iklan yang dipersonalisasi.",
    'daily': "Teka-teki harian",
    'dailyDone': "Kembali besok!",
    'qTF': "Benar atau salah?",
    'worlds': "Dunia",
    'boss': "Bos",
    'finishPrev': "Selesaikan dunia sebelumnya dulu",
    'qOdd': "Mana yang bukan kelompoknya?",
    'qNumSeq': "Angka berapa yang hilang?",
    'breakTitle': "Waktunya istirahat!",
    'breakText': "Hari ini kamu sudah banyak bermain, juara! Temanmu mengantuk 😴 Sampai besok!",
    'limit': "Waktu main harian",
    'off': "Tanpa batas",
    'min': "mnt",
    'playedToday': "Hari ini",
    'combo': "Keren!",
    'shop': "Toko",
    'wear': "Pakai",
    'takeOff': "Lepas",
    'dailyGift': "Hadiah harian!",
    'chestTitle': "Peti harta karun!",
    'tapOpen': "Ketuk untuk membuka",
    'collect': "Ambil",
    'qMath': "Hitung!",
    'hint': "Petunjuk",
    'win': "Hebat, juara!",
    'lose': "Tidak apa-apa, coba lagi!",
    'next': "Lanjut",
    'retry': "Ulangi",
    'map': "Peta",
    'buddyCheer': "Aku bersamamu, juara!",
    'rivalTaunt': "Pasti kamu tidak bisa!",
    'buddyHappy': "Keren!",
    'rivalSad': "Tidak mungkin!",
    'buddySad': "Tenang, fokus!",
    'rivalHappy': "Haha! Sudah kubilang!",
    'owl': "Burung hantu",
    'fox': "Rubah",
    'free': "Pilihan pertama gratis",
    'switchCost': "Ganti dengan {n} koin",
    'noCoins': "Koin tidak cukup",
    'enterCode': "Ketik kode dari video",
    'ok': "OK",
    'cancel': "Batal",
    'codeOk': "Hore! Kamu dapat {n} koin",
    'codeBad': "Kode salah",
    'codeUsed': "Kode sudah dipakai",
    'shareText': "Coba Sarang Teka-Teki dan tantang aku! Aku sampai level {n} 🦉",
    'copied': "Pesan disalin, tempel ke temanmu",
    'coinsEarned': "+{n}",
  },
};

const Map<String, Map<String, List<String>>> kLines = {
  'ar': {
    'buddyCheer': ['أنا معك يا بطل!', 'يلا نلعب!', 'أنت أذكى واحد!', 'أنا واثق بيك!', 'نبدأ المغامرة؟'],
    'rivalTaunt': ['أراهن إنك ما تحلّها!', 'هههه ما تقدر علي!', 'ألغازي صعبة!', 'تعال إذا تجرأ!', 'اليوم أنا الفايز!'],
    'buddyHappy': ['رائع!', 'أحسنت!', 'عبقري!', 'برافو عليك!', 'كمّل هيچ!', 'ممتاز!', 'واو!', 'أنت نجم!'],
    'rivalSad': ['مو معقولة!', 'شلون عرفتها؟!', 'أوووف!', 'حظ بس!', 'لا لا لا!', 'المرة الجاية!'],
    'buddySad': ['لا بأس، ركّز!', 'جرّب مرة ثانية!', 'قريب جداً!', 'دقّق زين!', 'أنا معك!'],
    'rivalHappy': ['هاها! قلت لك!', 'غلط غلط!', 'أنا الفايز!', 'ما تقدر علي!', 'هههه!'],
  },
  'en': {
    'buddyCheer': ["I'm with you, champ!", "Let's play!", "You're so smart!", 'I believe in you!', 'Ready for adventure?'],
    'rivalTaunt': ["Bet you can't solve it!", "You can't beat me!", 'My puzzles are hard!', 'Come on, if you dare!', "Today I'm winning!"],
    'buddyHappy': ['Awesome!', 'Well done!', 'Genius!', 'Bravo!', 'Keep going!', 'Excellent!', 'Wow!', "You're a star!"],
    'rivalSad': ['No way!', 'How did you know?!', 'Ugh!', 'Just luck!', 'Nooo!', 'Next time!'],
    'buddySad': ["It's ok, focus!", 'Try again!', 'So close!', 'Look carefully!', "I'm with you!"],
    'rivalHappy': ['Haha! Told you!', 'Wrong!', "I'm winning!", "You can't beat me!", 'Hehe!'],
  },
  'fr': {
    'buddyCheer': ['Je suis avec toi !', 'On joue ?', "T'es trop fort !", "J'ai confiance en toi !", "Prêt pour l'aventure ?"],
    'rivalTaunt': ["Je parie que tu n'y arriveras pas !", 'Tu ne me battras pas !', 'Mes énigmes sont dures !', 'Viens si tu oses !', "Aujourd'hui je gagne !"],
    'buddyHappy': ['Génial !', 'Bravo !', 'Génie !', 'Super !', 'Continue !', 'Excellent !', 'Waouh !', 'Tu es une star !'],
    'rivalSad': ['Pas possible !', 'Comment tu as su ?!', 'Oh non !', 'Juste de la chance !', 'Nooon !', 'La prochaine fois !'],
    'buddySad': ['Pas grave, concentre-toi !', 'Réessaie !', 'Presque !', 'Regarde bien !', 'Je suis avec toi !'],
    'rivalHappy': ['Haha ! Je te l’avais dit !', 'Raté !', 'Je gagne !', 'Tu ne me battras pas !', 'Hihi !'],
  },
  'es': {
    'buddyCheer': ["¡Estoy contigo, campeón!", "¡Vamos a jugar!", "¡Eres muy listo!", "¡Confío en ti!", "¿Lista la aventura?"],
    'rivalTaunt': ["¡Apuesto a que no puedes!", "¡No me ganarás!", "¡Mis acertijos son difíciles!", "¡Ven si te atreves!", "¡Hoy gano yo!"],
    'buddyHappy': ["¡Genial!", "¡Muy bien!", "¡Genio!", "¡Bravo!", "¡Sigue así!", "¡Excelente!", "¡Guau!", "¡Eres una estrella!"],
    'rivalSad': ["¡No puede ser!", "¿Cómo lo supiste?", "¡Uf!", "¡Pura suerte!", "¡Nooo!", "¡La próxima vez!"],
    'buddySad': ["¡Tranquilo, concéntrate!", "¡Inténtalo otra vez!", "¡Casi!", "¡Mira bien!", "¡Estoy contigo!"],
    'rivalHappy': ["¡Jaja! ¡Te lo dije!", "¡Fallaste!", "¡Voy ganando!", "¡No me ganarás!", "¡Jiji!"],
  },
  'pt': {
    'buddyCheer': ["Estou com você, campeão!", "Vamos jogar!", "Você é muito esperto!", "Eu confio em você!", "Pronto para a aventura?"],
    'rivalTaunt': ["Aposto que você não consegue!", "Você não me vence!", "Meus enigmas são difíceis!", "Venha se tiver coragem!", "Hoje eu ganho!"],
    'buddyHappy': ["Incrível!", "Muito bem!", "Gênio!", "Bravo!", "Continue assim!", "Excelente!", "Uau!", "Você é uma estrela!"],
    'rivalSad': ["Não acredito!", "Como você sabia?", "Ah, não!", "Foi sorte!", "Nãooo!", "Na próxima!"],
    'buddySad': ["Calma, concentre-se!", "Tente de novo!", "Quase!", "Olhe com atenção!", "Estou com você!"],
    'rivalHappy': ["Haha! Eu falei!", "Errou!", "Estou ganhando!", "Você não me vence!", "Hihi!"],
  },
  'tr': {
    'buddyCheer': ["Yanındayım şampiyon!", "Hadi oynayalım!", "Çok akıllısın!", "Sana güveniyorum!", "Maceraya hazır mısın?"],
    'rivalTaunt': ["Bahse girerim çözemezsin!", "Beni yenemezsin!", "Bilmecelerim çok zor!", "Cesaretin varsa gel!", "Bugün ben kazanacağım!"],
    'buddyHappy': ["Harika!", "Aferin!", "Dahisin!", "Bravo!", "Devam et!", "Mükemmel!", "Vay!", "Sen bir yıldızsın!"],
    'rivalSad': ["Olamaz!", "Nasıl bildin?", "Off!", "Sadece şans!", "Hayııır!", "Bir dahaki sefere!"],
    'buddySad': ["Sorun yok, odaklan!", "Tekrar dene!", "Çok yaklaştın!", "Dikkatli bak!", "Yanındayım!"],
    'rivalHappy': ["Haha! Demiştim!", "Yanlış!", "Ben kazanıyorum!", "Beni yenemezsin!", "Hihi!"],
  },
  'id': {
    'buddyCheer': ["Aku bersamamu, juara!", "Ayo main!", "Kamu pintar sekali!", "Aku percaya padamu!", "Siap berpetualang?"],
    'rivalTaunt': ["Pasti kamu tidak bisa!", "Kamu tidak bisa mengalahkanku!", "Teka-tekiku sulit!", "Ayo kalau berani!", "Hari ini aku menang!"],
    'buddyHappy': ["Keren!", "Bagus sekali!", "Jenius!", "Hebat!", "Terus begitu!", "Luar biasa!", "Wah!", "Kamu bintang!"],
    'rivalSad': ["Tidak mungkin!", "Kok kamu tahu?", "Aduh!", "Cuma beruntung!", "Tidaaak!", "Lain kali!"],
    'buddySad': ["Tenang, fokus!", "Coba lagi!", "Hampir!", "Lihat baik-baik!", "Aku bersamamu!"],
    'rivalHappy': ["Haha! Sudah kubilang!", "Salah!", "Aku menang!", "Kamu tidak bisa mengalahkanku!", "Hihi!"],
  },
};

class Accessory {
  const Accessory(this.id, this.slot, this.price, this.aspect, this.size);
  final String id;
  final String slot; // hat أو eyes أو neck
  final int price;
  final double aspect; // العرض ÷ الارتفاع للصورة
  final double size; // العرض نسبة إلى ارتفاع الشخصية
}

const List<Accessory> kAccessories = [
  Accessory('bowtie', 'neck', 60, 367 / 200, 0.24),
  Accessory('glasses', 'eyes', 80, 400 / 156, 0.41),
  Accessory('sunglasses', 'eyes', 100, 400 / 144, 0.41),
  Accessory('cowboy', 'hat', 120, 370 / 200, 0.52),
  Accessory('pirate', 'hat', 150, 392 / 200, 0.52),
  Accessory('crown', 'hat', 250, 287 / 200, 0.36),
];

/// أماكن العينين والرأس والرقبة في كل صورة (نسبة من العرض والارتفاع)
class Anchors {
  const Anchors(this.eyeX, this.eyeY, this.hatX, this.hatY, this.neckX, this.neckY);
  final double eyeX, eyeY, hatX, hatY, neckX, neckY;
}

const Map<String, Map<String, Anchors>> kAnchors = {
  'owl': {
    'normal': Anchors(0.50, 0.32, 0.50, 0.17, 0.50, 0.50),
    'happy': Anchors(0.50, 0.32, 0.50, 0.18, 0.50, 0.50),
    'sad': Anchors(0.50, 0.38, 0.50, 0.21, 0.50, 0.57),
  },
  'fox': {
    'normal': Anchors(0.39, 0.32, 0.40, 0.17, 0.40, 0.55),
    'happy': Anchors(0.39, 0.31, 0.39, 0.16, 0.39, 0.54),
    'sad': Anchors(0.33, 0.37, 0.38, 0.17, 0.37, 0.57),
  },
};

const Map<String, double> kCharAspect = {'owl': 648 / 560, 'fox': 534 / 560};

/// كل الأصدقاء: الاسم ← السعر (0 = مجاني)
const Map<String, int> kCritters = {
  'owl': 0,
  'fox': 0,
  'cat': 300,
  'bunny': 350,
  'penguin': 400,
  'gazelle': 500,
  'falcon': 600,
  'dragon': 800,
};

const Anchors kDefaultAnchors = Anchors(0.5, 0.33, 0.5, 0.12, 0.5, 0.55);

const List<String> kStamps = [
  '🇮🇶🏛', '🇪🇬🐪', '🇫🇷🗼', '🇯🇵🗻', '🇧🇷⚽', '🇦🇺🦘', '🇮🇳🐘', '🇨🇳🐼',
  '🇺🇸🗽', '🇮🇹🍕', '🇲🇽🌮', '🇹🇷🕌', '🇸🇦🌴', '🇬🇧💂', '🇪🇸💃', '🇨🇦🍁',
  '🇰🇪🦒', '🇮🇩🌋', '🇬🇷🏺', '🇲🇦🧭', '🇳🇱🌷', '🇨🇭🧀', '🇵🇪🦙', '🇹🇭🛕',
  '🇩🇪🥨', '🇦🇷🥩', '🇳🇴⛷', '🇰🇷🎎', '🇯🇴🏜', '🇳🇿🥝',
];

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
  ['🐶', '🐱'], ['🍎', '🍅'], ['🌲', '🌳'], ['😀', '😃'], ['🐸', '🐢'],
  ['⭐', '🌟'], ['🍊', '🍑'], ['🐝', '🐞'], ['🌙', '⭐'], ['🐵', '🙈'],
  ['🚗', '🚕'], ['🍪', '🍩'], ['🐔', '🐤'], ['🍌', '🌽'], ['🎈', '🎀'],
  ['🐟', '🐠'], ['🐮', '🐷'], ['🐭', '🐹'], ['🐰', '🐻'], ['🦁', '🐯'],
  ['🐼', '🐨'], ['🐧', '🐦'], ['🦆', '🦢'], ['🐴', '🦄'], ['🐫', '🐪'],
  ['🐘', '🦏'], ['🐳', '🐋'], ['🦀', '🦞'], ['🐌', '🐛'], ['🦋', '🐝'],
  ['🍇', '🫐'], ['🍓', '🍒'], ['🍉', '🍈'], ['🍐', '🍏'], ['🥕', '🌶'],
  ['🥦', '🥬'], ['🍔', '🍞'], ['🍕', '🧀'], ['🍦', '🍧'], ['🧁', '🎂'],
  ['🍫', '🍬'], ['🥛', '☕'], ['⚽', '🏀'], ['🏈', '🏉'], ['🎾', '🥎'],
  ['🚌', '🚎'], ['🚓', '🚑'], ['✈', '🚀'], ['🚲', '🛴'], ['⛵', '🚤'],
  ['🌞', '🌝'], ['☁', '⛅'], ['🌈', '🌂'], ['❄', '💧'], ['🔥', '💥'],
  ['🌷', '🌹'], ['🌻', '🌼'], ['🍀', '☘'], ['🍁', '🍂'], ['🌵', '🌴'],
  ['🎁', '📦'], ['🔑', '🗝'], ['⏰', '⌚'], ['📕', '📗'], ['✏', '🖍'],
  ['🎩', '👒'], ['👟', '👞'], ['🧦', '🧤'], ['🕶', '👓'], ['🏠', '🏡'],
  ['🔔', '🔕'], ['💡', '🔦'], ['🎸', '🎻'], ['🥁', '🎺'], ['🧸', '🪆'],
  ['😺', '😸'], ['😊', '🙂'], ['😴', '😪'], ['🤓', '😎'], ['🥳', '🤩'],
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
    ['ح', 'خ'],
    ['ن', 'ت'],
    ['ي', 'ب'],
    ['ه', 'ة'],
    ['أ', 'إ'],
    ['ك', 'ل'],
    ['و', 'ؤ'],
    ['6', '9'],
    ['3', '8'],
    ['1', '7'],
    ['2', '5'],
    ['٢', '٣'],
    ['٦', '٧'],
  ],
  'en': [
    ['b', 'd'],
    ['p', 'q'],
    ['m', 'n'],
    ['O', 'Q'],
    ['E', 'F'],
    ['u', 'v'],
    ['C', 'G'],
    ['P', 'R'],
    ['M', 'W'],
    ['i', 'j'],
    ['h', 'n'],
    ['a', 'o'],
    ['V', 'Y'],
    ['6', '9'],
    ['3', '8'],
    ['1', '7'],
  ],
  'fr': [
    ['b', 'd'],
    ['p', 'q'],
    ['m', 'n'],
    ['O', 'Q'],
    ['E', 'F'],
    ['é', 'è'],
    ['C', 'G'],
    ['P', 'R'],
    ['à', 'â'],
    ['ç', 'c'],
    ['h', 'n'],
    ['a', 'o'],
    ['6', '9'],
    ['3', '8'],
    ['1', '7'],
  ],
  'es': [
    ["b", "d"],
    ["p", "q"],
    ["m", "n"],
    ["ñ", "n"],
    ["O", "Q"],
    ["E", "F"],
    ["C", "G"],
    ["P", "R"],
    ["á", "a"],
    ["h", "n"],
    ["6", "9"],
    ["3", "8"],
    ["1", "7"],
  ],
  'pt': [
    ["b", "d"],
    ["p", "q"],
    ["m", "n"],
    ["ç", "c"],
    ["ã", "a"],
    ["O", "Q"],
    ["E", "F"],
    ["C", "G"],
    ["P", "R"],
    ["h", "n"],
    ["6", "9"],
    ["3", "8"],
    ["1", "7"],
  ],
  'tr': [
    ["b", "d"],
    ["p", "q"],
    ["m", "n"],
    ["ç", "c"],
    ["ş", "s"],
    ["ğ", "g"],
    ["ö", "o"],
    ["ü", "u"],
    ["ı", "i"],
    ["O", "Q"],
    ["E", "F"],
    ["6", "9"],
    ["3", "8"],
  ],
  'id': [
    ["b", "d"],
    ["p", "q"],
    ["m", "n"],
    ["O", "Q"],
    ["E", "F"],
    ["C", "G"],
    ["P", "R"],
    ["M", "W"],
    ["h", "n"],
    ["a", "o"],
    ["6", "9"],
    ["3", "8"],
    ["1", "7"],
  ],
};

const List<String> kCountEmojis = [
  '🍎', '🌟', '🐞', '🍓', '🦋', '🐟', '🌸', '🍄', '🐤', '🎈',
  '🐸', '🍌', '🚗', '⚽', '🐝', '🍩', '🌙', '🐢', '🍇', '🐰',
  '🌻', '🍪', '🐧', '🔔', '🎁', '🍉', '🐙', '🦄', '🍒', '🐶',
];

// ============================================================
// الأصوات
// ============================================================
class Sfx {
  static final Map<String, AudioPlayer> _players = {};
  static bool muted = false;
  static bool musicOff = false;
  static AudioPlayer? _music;
  static AudioPlayer? _voice;

  /// الأصوات لا توقف الموسيقى
  static Future<void> init() async {
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ));
    } catch (_) {}
  }

  static Future<void> startMusic() async {
    if (muted || musicOff) return;
    try {
      _music ??= AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.3);
      await _music!.play(AssetSource('sounds/music.mp3'));
    } catch (_) {}
  }

  static Future<void> pauseMusic() async {
    try {
      await _music?.pause();
    } catch (_) {}
  }

  static Future<void> resumeMusic() async {
    if (muted || musicOff || _music == null) return;
    try {
      await _music!.resume();
    } catch (_) {}
  }

  /// صوت الشخصية وهي تقول جملتها (باللغات الثلاث، أول 3 جمل لكل حالة)
  static Future<void> say(String kind, String key, String? text, String lang) async {
    if (muted || text == null) return;
    final i = kLines[lang]?[key]?.indexOf(text) ?? -1;
    if (i < 0 || i > 2) return;
    try {
      _voice ??= AudioPlayer();
      await _voice!.stop();
      await _voice!.play(AssetSource('voice/${lang}_${kind}_${key}_$i.wav'));
    } catch (_) {}
  }

  static Future<void> play(String name) async {
    if (muted) return;
    try {
      final p = _players.putIfAbsent(name, AudioPlayer.new);
      await p.stop();
      await p.play(AssetSource('sounds/$name.wav'));
    } catch (_) {
      // لا نوقف اللعبة إذا فشل الصوت
    }
  }
}

// ============================================================
// التخزين: العملات والنجوم واللغة والصديق
// ============================================================
class Store extends ChangeNotifier {
  Store(this._p);
  final SharedPreferences _p;

  int get coins => _p.getInt('coins') ?? kStartCoins;
  String get lang {
    final saved = _p.getString('lang');
    if (saved != null) return saved;
    final dev = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final code = dev == 'in' ? 'id' : dev;
    return kStrings.containsKey(code) ? code : 'en';
  }
  bool get muted => _p.getBool('muted') ?? false;

  Future<void> toggleMute() async {
    await _p.setBool('muted', !muted);
    Sfx.muted = muted;
    if (muted) {
      Sfx.pauseMusic();
    } else {
      Sfx.startMusic();
    }
    notifyListeners();
  }
  String get buddy => _p.getString('buddy') ?? 'owl';
  String get rival => buddy == 'fox' ? 'owl' : 'fox';

  bool ownsChar(String k) => (kCritters[k] ?? 0) == 0 || owns('char_$k');
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

  /// يسحب عنصراً من مجموعة محفوظة، فلا يتكرر حتى تنتهي كل العناصر
  int draw(String key, int size, Random r) {
    final k = 'deck_${key}_$size';
    var deck = (_p.getStringList(k) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .where((i) => i >= 0 && i < size)
        .toList();
    if (deck.isEmpty) {
      deck = List<int>.generate(size, (i) => i)..shuffle(r);
    }
    final v = deck.removeLast();
    _p.setStringList(k, deck.map((e) => '$e').toList());
    return v;
  }

  String line(String key) {
    final list = kLines[lang]?[key];
    if (list == null || list.isEmpty) return t(key);
    return list[Random().nextInt(list.length)];
  }

  static String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  bool get canGift => _p.getString('giftDay') != _today();

  Future<void> claimGift() async {
    await _p.setString('giftDay', _today());
    notifyListeners();
  }

  bool owns(String id) =>
      (_p.getStringList('owned') ?? const []).contains(id);

  Future<void> buy(String id) async {
    final list = List<String>.from(_p.getStringList('owned') ?? const []);
    if (!list.contains(id)) list.add(id);
    await _p.setStringList('owned', list);
    notifyListeners();
  }

  String? worn(String kind, String slot) => _p.getString('wear_${kind}_$slot');

  Future<void> setWorn(String kind, String slot, String? id) async {
    if (id == null) {
      await _p.remove('wear_${kind}_$slot');
    } else {
      await _p.setString('wear_${kind}_$slot', id);
    }
    notifyListeners();
  }

  // لغز اليوم
  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  bool get dailyDone => _p.getString('dailyLast') == _today();
  int get dailyStreak => _p.getInt('dailyStreak') ?? 0;

  Future<int> completeDaily() async {
    final y = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    final st = _p.getString('dailyLast') == y ? dailyStreak + 1 : 1;
    await _p.setString('dailyLast', _today());
    await _p.setInt('dailyStreak', st);
    notifyListeners();
    return st;
  }

  // وقت اللعب
  int get limitMin => _p.getInt('limitMin') ?? 0;

  Future<void> setLimit(int m) async {
    await _p.setInt('limitMin', m);
    notifyListeners();
  }

  int get playedSec => _p.getInt('play_${_today()}') ?? 0;
  Future<void> addPlayed(int sec) => _p.setInt('play_${_today()}', playedSec + sec);
  bool get timeUp => limitMin > 0 && playedSec >= limitMin * 60;

  int get stampCount => _p.getInt('stamps') ?? 0;

  /// يعطي الختم التالي ويرجعه (أو null إذا اكتمل الجواز)
  Future<String?> addStamp() async {
    final n = stampCount;
    if (n >= kStamps.length) return null;
    await _p.setInt('stamps', n + 1);
    notifyListeners();
    return kStamps[n];
  }

  bool flag(String k) => _p.getBool('flag_$k') ?? false;
  Future<void> setFlag(String k) => _p.setBool('flag_$k', true);

  bool get musicOn => _p.getBool('musicOn') ?? true;

  Future<void> toggleMusic() async {
    await _p.setBool('musicOn', !musicOn);
    Sfx.musicOff = !musicOn;
    if (musicOn) {
      Sfx.startMusic();
    } else {
      Sfx.pauseMusic();
    }
    notifyListeners();
  }

  int get levelsDone {
    var n = 0;
    for (var i = 1; i <= kLevels; i++) {
      if (stars(i) > 0) n++;
    }
    return n;
  }

  int get starsTotal {
    var n = 0;
    for (var i = 1; i <= kLevels; i++) {
      n += stars(i);
    }
    return n;
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
  final store = Store(prefs);
  Sfx.muted = store.muted;
  Sfx.musicOff = !store.musicOn;
  await Sfx.init();
  WidgetsBinding.instance.addObserver(_Life());
  runApp(EshApp(store: store));
  Sfx.startMusic();
}

/// توقف الموسيقى عندما يخرج الطفل من اللعبة، وترجع عندما يعود
class _Life extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Sfx.resumeMusic();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      Sfx.pauseMusic();
    }
  }
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
            fontFamily: GoogleFonts.balooBhaijaan2().fontFamily,
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
class GameBackground extends StatefulWidget {
  const GameBackground({
    super.key,
    required this.child,
    this.colors = const [kPurpleTop, kPurpleBottom],
    this.image,
  });
  final Widget child;
  final List<Color> colors;
  final String? image;

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  final List<_Twinkle> _stars = List.generate(26, (_) => _Twinkle.random());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.image != null) ...[
            Image.asset(widget.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            Container(color: const Color(0x33000000)),
          ],
          RepaintBoundary(
            child: CustomPaint(painter: _TwinklePainter(_c, _stars)),
          ),
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}

class _Twinkle {
  _Twinkle(this.x, this.y, this.size, this.phase, this.speed);
  factory _Twinkle.random() {
    final r = Random();
    return _Twinkle(r.nextDouble(), r.nextDouble(), 1.5 + r.nextDouble() * 3,
        r.nextDouble(), 0.3 + r.nextDouble() * 0.7);
  }
  final double x, y, size, phase, speed;
}

class _TwinklePainter extends CustomPainter {
  _TwinklePainter(this.anim, this.stars) : super(repaint: anim);
  final Animation<double> anim;
  final List<_Twinkle> stars;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final st in stars) {
      final t = (anim.value * st.speed * 3 + st.phase) % 1.0;
      final a = (sin(t * 2 * pi) + 1) / 2; // 0..1
      // تنزل ببطء مثل أوراق أو نجوم
      final y = ((st.y + anim.value * st.speed * 0.25) % 1.0) * size.height;
      paint.color = Color.fromRGBO(255, 236, 170, 0.15 + a * 0.6);
      canvas.drawCircle(Offset(st.x * size.width, y), st.size * (0.6 + a * 0.6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TwinklePainter old) => false;
}

/// يظهر العنصر بقفزة صغيرة، واحداً بعد الآخر
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.index = 0, this.drop = false});
  final Widget child;
  final int index;
  final bool drop;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: 35 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaled = ScaleTransition(
      scale: CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
      child: widget.child,
    );
    if (!widget.drop) return scaled;
    return SlideTransition(
      position: Tween(begin: const Offset(0, -2.5), end: Offset.zero)
          .animate(CurvedAnimation(parent: _c, curve: Curves.bounceOut)),
      child: scaled,
    );
  }
}

/// يهز ما بداخله كلما تغير trigger
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(covariant Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx = sin(t * pi * 8) * 14 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// انفجار أوراق ونجوم ملونة كلما تغير trigger
class Confetti extends StatefulWidget {
  const Confetti({super.key, required this.trigger});
  final int trigger;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Bit {
  _Bit(Random r)
      : angle = -pi / 2 + (r.nextDouble() - 0.5) * pi * 1.4,
        speed = 0.6 + r.nextDouble() * 0.9,
        spin = (r.nextDouble() - 0.5) * 14,
        size = 6 + r.nextDouble() * 8,
        round = r.nextBool(),
        color = const [
          Color(0xFFFFC83D),
          Color(0xFF4ADE80),
          Color(0xFF8C7BFF),
          Color(0xFFFF6B8B),
          Color(0xFF38BDF8),
          Color(0xFFFFA94D),
        ][r.nextInt(6)];
  final double angle, speed, spin, size;
  final bool round;
  final Color color;
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  List<_Bit> _bits = const [];

  @override
  void didUpdateWidget(covariant Confetti old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      final r = Random();
      _bits = List.generate(46, (_) => _Bit(r));
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ConfettiPainter(_c, _bits));
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.bits) : super(repaint: anim);
  final Animation<double> anim;
  final List<_Bit> bits;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    if (t <= 0 || t >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.45);
    final paint = Paint();
    final reach = size.shortestSide * 0.75;
    for (final b in bits) {
      final d = b.speed * reach * Curves.easeOut.transform(t);
      final gravity = t * t * size.height * 0.35;
      final pos = origin + Offset(cos(b.angle) * d, sin(b.angle) * d + gravity);
      paint.color = b.color.withValues(alpha: 1 - t);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(b.spin * t);
      if (b.round) {
        canvas.drawCircle(Offset.zero, b.size / 2, paint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * 0.6),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.bits != bits;
}

/// لافتة السلسلة 🔥
class ComboBanner extends StatelessWidget {
  const ComboBanner({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Transform.rotate(
        angle: -0.08,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kOrangeTop, kOrangeBottom]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kInk, width: 4),
            boxShadow: const [BoxShadow(color: kInk, offset: Offset(0, 6))],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: kInk, offset: Offset(0, 3))],
            ),
          ),
        ),
      ),
    );
  }
}

/// نافذة الهدية أو الكنز: مغلقة، ثم تُفتح عند اللمس
class RewardDialog extends StatefulWidget {
  const RewardDialog({
    super.key,
    required this.title,
    required this.closed,
    required this.open,
    required this.amount,
  });
  final String title;
  final String closed;
  final String open;
  final int amount;

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> {
  bool _opened = false;
  int _confetti = 0;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kPurpleTop, kPurpleBottom],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: kGold, width: 4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GoldTitle(widget.title, size: 30),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _opened
                      ? null
                      : () {
                          Sfx.play('win');
                          setState(() {
                            _opened = true;
                            _confetti++;
                          });
                        },
                  child: _opened
                      ? PopIn(child: Image.asset(widget.open, height: 170))
                      : _Wobble(child: Image.asset(widget.closed, height: 170)),
                ),
                const SizedBox(height: 12),
                if (!_opened)
                  Text(s.t('tapOpen'),
                      style: const TextStyle(color: Colors.white70, fontSize: 18))
                else ...[
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: widget.amount),
                    duration: const Duration(milliseconds: 900),
                    builder: (context, v, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CoinIcon(size: 36),
                        const SizedBox(width: 8),
                        Text('+$v',
                            style: const TextStyle(
                                color: kGold, fontSize: 34, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Btn3D(
                    width: 200,
                    onTap: () => Navigator.of(context).pop(true),
                    child: Text(s.t('collect')),
                  ),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(child: Confetti(trigger: _confetti)),
          ),
        ],
      ),
    );
  }
}

/// اهتزاز خفيف متكرر يجذب الانتباه
class _Wobble extends StatefulWidget {
  const _Wobble({required this.child});
  final Widget child;

  @override
  State<_Wobble> createState() => _WobbleState();
}

class _WobbleState extends State<_Wobble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final a = t < 0.35 ? sin(t / 0.35 * pi * 4) * 0.08 : 0.0;
        final double sc = 1 + (t < 0.35 ? 0.05 * sin(t / 0.35 * pi) : 0.0);
        return Transform.rotate(
          angle: a,
          child: Transform.scale(scale: sc, child: child),
        );
      },
      child: widget.child,
    );
  }
}

Future<void> showReward(BuildContext context,
    {required String title,
    required String closed,
    required String open,
    required int amount}) async {
  final s = StoreScope.read(context);
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        RewardDialog(title: title, closed: closed, open: open, amount: amount),
  );
  if (ok == true) {
    await s.addCoins(amount);
    Sfx.play('coin');
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
          Sfx.play('tap');
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
                child: DefaultTextStyle.merge(
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
  Widget _dressed(String img) {
    final s = StoreScope.of(context);
    final h = widget.height;
    final w = h * (kCharAspect[widget.kind] ?? 1);
    final pose = (img == 'happy' || img == 'sad') ? img : 'normal';
    final a = kAnchors[widget.kind]?[pose] ?? kDefaultAnchors;
    final items = <Widget>[];
    for (final acc in kAccessories) {
      if (s.worn(widget.kind, acc.slot) != acc.id) continue;
      final iw = acc.size * h;
      final ih = iw / acc.aspect;
      double cx;
      double top;
      switch (acc.slot) {
        case 'hat':
          cx = a.hatX * w;
          top = a.hatY * h - ih * 0.85;
          break;
        case 'eyes':
          cx = a.eyeX * w;
          top = a.eyeY * h - ih / 2;
          break;
        default:
          cx = a.neckX * w;
          top = a.neckY * h - ih / 2;
      }
      items.add(Positioned(
        left: cx - iw / 2,
        top: top,
        width: iw,
        height: ih,
        child: Image.asset('assets/acc/${acc.id}.webp', fit: BoxFit.contain),
      ));
    }
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/characters/${widget.kind}_$img.webp',
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
          ...items,
        ],
      ),
    );
  }

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
          child: _dressed(img),
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
  String? _cheer;
  String? _taunt;
  bool _greeted = false;

  Future<void> _gift() async {
    final s = StoreScope.read(context);
    final amount = 20 + Random().nextInt(41); // 20 إلى 60
    await s.claimGift();
    if (!mounted) return;
    await showReward(context,
        title: s.t('dailyGift'),
        closed: 'assets/ui/gift_closed.webp',
        open: 'assets/ui/gift_open.webp',
        amount: amount);
  }

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

  String _greet(Store s) {
    _cheer ??= s.line('buddyCheer');
    if (!_greeted) {
      _greeted = true;
      final line = _cheer;
      Future<void>.delayed(const Duration(milliseconds: 700),
          () => Sfx.say(s.buddy, 'buddyCheer', line, s.lang));
    }
    return _cheer!;
  }

  void resetLines() => setState(() {
        _cheer = null;
        _taunt = null;
      });

  Future<bool> _chooseBuddy() async {
    final s = StoreScope.read(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => const BuddyDialog(),
    );
    if (!mounted || picked == null) return false;
    if (!s.ownsChar(picked)) {
      final price = kCritters[picked] ?? 0;
      if (!await s.spend(price)) {
        if (mounted) showSnack(context, s.t('noCoins'));
        return false;
      }
      Sfx.play('win');
      await s.buy('char_$picked');
      await s.setBuddy(picked);
      return true;
    }
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

  Future<void> _daily() async {
    final s = StoreScope.read(context);
    if (!s.buddyChosen) {
      final ok = await _chooseBuddy();
      if (!ok || !mounted) return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => PlayScreen(level: max(3, s.maxLevel), daily: true),
    ));
  }

  Future<void> _play() async {
    final s = StoreScope.read(context);
    if (!s.buddyChosen) {
      final ok = await _chooseBuddy();
      if (!ok || !mounted) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WorldsScreen()),
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
    Sfx.play('coin');
    if (mounted) {
      showSnack(context, s.t('codeOk').replaceAll('{n}', '$reward'));
    }
  }

  Future<void> _challenge() async {
    final s = StoreScope.read(context);
    if (!await parentGate(context)) return;
    if (!mounted) return;
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

  Widget _mini(String emoji, String label, Color top, Color bottom, VoidCallback onTap) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Btn3D(
            width: 66,
            height: 58,
            radius: 18,
            top: top,
            bottom: bottom,
            onTap: onTap,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Scaffold(
      body: GameBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  const CoinCounter(),
                  if (s.canGift)
                    GestureDetector(
                      onTap: _gift,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: _Wobble(
                          child: Image.asset('assets/ui/gift_closed.webp', height: 46),
                        ),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      s.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: s.toggleMute,
                  ),
                  const LangButton(),
                  IconButton(
                    icon: const Icon(Icons.family_restroom_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () async {
                      if (!await parentGate(context)) return;
                      if (!context.mounted) return;
                      _open(const ParentsScreen());
                    },
                  ),
                ],
              ),
              GoldTitle(s.t('appTitle'), size: 38),
              const SizedBox(height: 6),
              const GrowthCard(),
              // الشخصيات تأخذ المساحة الباقية وتصغر في الشاشات الصغيرة
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final h = (c.maxHeight - 56).clamp(50.0, 160.0).toDouble();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Critter(
                          kind: s.buddy,
                          height: h,
                          bubble: _greet(s),
                          bubbleWidth: 140,
                        ),
                      ),
                      Expanded(
                        child: Critter(
                          kind: s.rival,
                          height: h * 0.93,
                          bubble: _taunt ??= s.line('rivalTaunt'),
                          bubbleWidth: 140,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 8),
              Btn3D(
                width: 280,
                height: 68,
                onTap: _play,
                child: Text('▶  ${s.t('play')}',
                    style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 10),
              Btn3D(
                width: 280,
                height: 54,
                top: s.dailyDone ? kGreyTop : const Color(0xFFFFD95A),
                bottom: s.dailyDone ? kGreyBottom : kGoldDark,
                onTap: s.dailyDone ? null : _daily,
                child: Text(s.dailyDone
                    ? '✓ ${s.t('dailyDone')}  🔥${s.dailyStreak}'
                    : '🌟 ${s.t('daily')}${s.dailyStreak > 0 ? '  🔥${s.dailyStreak}' : ''}'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _mini('🦉', s.t('chooseBuddy'), kVioletTop, kVioletBottom, _chooseBuddy),
                  _mini('👑', s.t('shop'), const Color(0xFFF472B6), const Color(0xFFBE185D),
                      () => _open(const ShopScreen())),
                  _mini('⚔️', s.t('vsMode'), const Color(0xFFFF6B6B), const Color(0xFFB91C1C),
                      () => _open(const VersusScreen())),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _mini('🛂', '${s.t('passport')} ${s.stampCount}/${kStamps.length}',
                      const Color(0xFF38BDF8), const Color(0xFF0369A1),
                      () => _open(const PassportScreen())),
                  _mini('🔑', s.t('secretCode'), kOrangeTop, kOrangeBottom, _secretCode),
                  _mini('💬', s.t('challenge'), const Color(0xFF25D366), const Color(0xFF128C4A),
                      _challenge),
                ],
              ),
              const SizedBox(height: 6),
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
      onSelected: (v) {
        s.setLang(v);
        context.findAncestorStateOfType<_HomeScreenState>()?.resetLines();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'ar', child: Text('العربية')),
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'fr', child: Text('Français')),
        PopupMenuItem(value: 'es', child: Text('Español')),
        PopupMenuItem(value: 'pt', child: Text('Português')),
        PopupMenuItem(value: 'tr', child: Text('Türkçe')),
        PopupMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
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
      final owned = s.ownsChar(kind);
      return GestureDetector(
        onTap: () => Navigator.of(context).pop(kind),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? const Color(0x33FFC83D) : const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? kGold : Colors.white24, width: 3),
          ),
          child: Column(
            children: [
              Expanded(
                child: Opacity(
                  opacity: owned ? 1 : 0.55,
                  child: Image.asset('assets/characters/${kind}_normal.webp'),
                ),
              ),
              const SizedBox(height: 4),
              if (owned)
                FittedBox(
                  child: Text(s.t(kind),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CoinIcon(size: 18),
                    const SizedBox(width: 3),
                    Text('${kCritters[kind]}',
                        style: const TextStyle(
                            color: kGold, fontSize: 15, fontWeight: FontWeight.w900)),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: kPurpleTop,
      insetPadding: const EdgeInsets.all(16),
      title: Text(
        s.t('chooseBuddy'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: kGold, fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 340,
        height: 460,
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.72,
                children: [for (final k in kCritters.keys) option(k)],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (s.buddyChosen) const CoinIcon(size: 20),
                if (s.buddyChosen) const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    s.buddyChosen
                        ? s.t('switchCost').replaceAll('{n}', '$kSwitchCost')
                        : s.t('free'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// بوابة الأهل: سؤال ضرب قبل أي رابط خارجي
// ============================================================
Future<bool> parentGate(BuildContext context) async {
  final s = StoreScope.read(context);
  final r = Random();
  final a = 6 + r.nextInt(4);
  final b = 6 + r.nextInt(4);
  final ans = a * b;
  final opts = <int>{ans};
  while (opts.length < 3) {
    final d = ans + (r.nextBool() ? 1 : -1) * (1 + r.nextInt(9));
    if (d > 0) opts.add(d);
  }
  final list = opts.toList()..shuffle(r);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kPurpleTop,
      title: Text(s.t('parentsOnly'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: kGold, fontWeight: FontWeight.w900)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.t('parentAsk'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('$a × $b = ?',
                style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final o in list)
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(o == ans),
                  child: Text('$o', style: const TextStyle(fontSize: 22)),
                ),
            ],
          ),
        ],
      ),
    ),
  );
  return ok == true;
}

Future<void> openLink(BuildContext context, String url) async {
  if (!await parentGate(context)) return;
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    Widget stat(String label, String value) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      color: kGold, fontSize: 30, fontWeight: FontWeight.w900)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        );
    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            TopBar(title: s.t('parents')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: stat(s.t('levelsDone'), '${s.levelsDone}/$kLevels')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: stat(s.t('starsTotal'), '${s.starsTotal}/${kLevels * 3}')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                      '⏱ ${s.t('limit')}   (${s.t('playedToday')}: ${s.playedSec ~/ 60} ${s.t('min')})',
                      style: const TextStyle(
                          color: kGold, fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final m in const [0, 15, 30, 45, 60])
                        ChoiceChip(
                          label: Text(m == 0 ? s.t('off') : '$m ${s.t('min')}'),
                          selected: s.limitMin == m,
                          onSelected: (_) => s.setLimit(m),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: s.musicOn,
                    onChanged: (_) => s.toggleMusic(),
                    title: Text(s.t('musicOpt'),
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                    secondary: const Icon(Icons.music_note_rounded, color: kGold),
                  ),
                  ListTile(
                    leading: const Icon(Icons.play_circle_fill_rounded, color: Colors.red),
                    title: Text(s.t('channel'),
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                    onTap: () => openLink(context, kChannelUrl),
                  ),
                  const SizedBox(height: 10),
                  Text(s.t('privacy'),
                      style: const TextStyle(
                          color: kGold, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(s.t('privacyText'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 15, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// يد تشير للطفل أين يضغط (أول مرة فقط)
class PointingHand extends StatefulWidget {
  const PointingHand({super.key});

  @override
  State<PointingHand> createState() => _PointingHandState();
}

class _PointingHandState extends State<PointingHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 10 * Curves.easeInOut.transform(_c.value)),
          child: child,
        ),
        child: const Text('👆', style: TextStyle(fontSize: 44)),
      ),
    );
  }
}

// ============================================================
// البومة تكبر مع الطفل: بيضة ← فرخ ← بومة ← بومة حكيمة
// ============================================================
class GrowthCard extends StatelessWidget {
  const GrowthCard({super.key});
  static const List<int> _steps = [0, 10, 40, 90];

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final done = s.levelsDone;
    var stage = 0;
    for (var i = 0; i < _steps.length; i++) {
      if (done >= _steps[i]) stage = i;
    }
    final last = stage == _steps.length - 1;
    final from = _steps[stage];
    final to = last ? kLevels : _steps[stage + 1];
    final prog = last ? 1.0 : ((done - from) / (to - from)).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kGold, width: 2),
      ),
      child: Row(
        children: [
          PopIn(
            key: ValueKey('grow$stage'),
            child: Image.asset('assets/ui/grow$stage.webp', height: 74),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.t('myOwl')}  ${'⭐' * (stage + 1)}',
                    style: const TextStyle(
                        color: kGold, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: prog,
                    minHeight: 12,
                    backgroundColor: Colors.white24,
                    color: kGreenTop,
                  ),
                ),
                const SizedBox(height: 4),
                Text(last ? '🎓 $done/$kLevels' : '$done / $to',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          if (!last) ...[
            const SizedBox(width: 8),
            Opacity(
              opacity: 0.35,
              child: Image.asset('assets/ui/grow${stage + 1}.webp', height: 46),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// جواز السفر: ختم لكل لغز يوم
// ============================================================
class PassportScreen extends StatelessWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            TopBar(title: '🛂 ${s.t('passport')}'),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('🌟 ${s.t('daily')} = 1 🛂',
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(12),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (var i = 0; i < kStamps.length; i++)
                    PopIn(
                      index: i,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < s.stampCount
                              ? const Color(0xFFFFF1D6)
                              : const Color(0x22FFFFFF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: i < s.stampCount
                                  ? const Color(0xFFFF6B8B)
                                  : Colors.white24,
                              width: 3),
                        ),
                        child: Text(i < s.stampCount ? kStamps[i] : '🔒',
                            style: const TextStyle(fontSize: 34)),
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
// تحدي العائلة: لاعبان على نفس الهاتف
// ============================================================
class VersusScreen extends StatefulWidget {
  const VersusScreen({super.key});

  @override
  State<VersusScreen> createState() => _VersusScreenState();
}

class _VersusScreenState extends State<VersusScreen> {
  static const int _target = 5;
  late PuzzleGen _gen;
  late Puzzle _p;
  final List<int> _score = [0, 0];
  final List<bool> _frozen = [false, false];
  int? _winner;
  int _confetti = 0;
  int _round = 0;
  bool _lock = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final st = StoreScope.read(context);
      _gen = PuzzleGen(6, st.lang, st);
      _p = _gen._diff();
    }
  }

  void _reset() {
    setState(() {
      _score[0] = 0;
      _score[1] = 0;
      _winner = null;
      _lock = false;
      _round++;
      _p = _gen._diff();
    });
  }

  void _tap(int player, int i) {
    if (_lock || _winner != null || _frozen[player]) return;
    if (i == _p.answer) {
      HapticFeedback.mediumImpact();
      Sfx.play('correct');
      setState(() {
        _score[player]++;
        _lock = true;
        _confetti++;
      });
      if (_score[player] >= _target) {
        Sfx.play('win');
        setState(() => _winner = player);
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _p = _gen._diff();
          _round++;
          _lock = false;
        });
      });
    } else {
      HapticFeedback.heavyImpact();
      Sfx.play('wrong');
      setState(() => _frozen[player] = true);
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _frozen[player] = false);
      });
    }
  }

  Widget _cell(int i) {
    final style = i == _p.answer ? _p.style : OddStyle.other;
    Widget t = Text(_p.cells[i],
        style: TextStyle(fontSize: style == OddStyle.small ? 34 * _p.scale : 34));
    if (style == OddStyle.rotated) t = Transform.rotate(angle: _p.angle, child: t);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kInk, width: 2),
      ),
      child: FittedBox(child: Padding(padding: const EdgeInsets.all(3), child: t)),
    );
  }

  Widget _half(int player, Store s) {
    final c = player == 0 ? kVioletBottom : kOrangeBottom;
    return Container(
      color: c.withValues(alpha: 0.28),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              '${s.t(player == 0 ? 'p1' : 'p2')}   ${'⭐' * _score[player]}${'☆' * (_target - _score[player])}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _frozen[player] ? 0.3 : 1,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    key: ValueKey('g$player-$_round'),
                    crossAxisCount: _p.cols,
                    padding: const EdgeInsets.all(10),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 0; i < _p.cells.length; i++)
                        GestureDetector(onTap: () => _tap(player, i), child: _cell(i)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        GameBackground(
          child: Column(
            children: [
              Expanded(child: RotatedBox(quarterTurns: 2, child: _half(1, s))),
              Container(
                height: 46,
                color: kInk,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    Text('⚔️ ${s.t('vsMode')} ⚔️',
                        style: const TextStyle(
                            color: kGold, fontSize: 18, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(child: _half(0, s)),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(child: Confetti(trigger: _confetti)),
        ),
        if (_winner != null)
          Positioned.fill(
            child: Container(
              color: const Color(0xAA000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RotatedBox(
                      quarterTurns: _winner == 1 ? 2 : 0,
                      child: GoldTitle(
                          '🏆 ${s.t(_winner == 0 ? 'p1' : 'p2')} ${s.t('wins')}',
                          size: 34),
                    ),
                    const SizedBox(height: 20),
                    Btn3D(width: 220, onTap: _reset, child: Text(s.t('playAgain'))),
                    const SizedBox(height: 12),
                    Btn3D(
                      width: 220,
                      top: kVioletTop,
                      bottom: kVioletBottom,
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Text(s.t('ok')),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ============================================================
// المتجر: ملابس للصديق
// ============================================================
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  Future<void> _tap(BuildContext context, Accessory acc) async {
    final s = StoreScope.read(context);
    final kind = s.buddy;
    if (!s.owns(acc.id)) {
      if (!await s.spend(acc.price)) {
        if (context.mounted) showSnack(context, s.t('noCoins'));
        return;
      }
      Sfx.play('coin');
      await s.buy(acc.id);
      await s.setWorn(kind, acc.slot, acc.id);
      return;
    }
    final on = s.worn(kind, acc.slot) == acc.id;
    await s.setWorn(kind, acc.slot, on ? null : acc.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            TopBar(title: '👑 ${s.t('shop')}'),
            const SizedBox(height: 8),
            Critter(kind: s.buddy, height: 200),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(12),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
                children: [
                  for (var i = 0; i < kAccessories.length; i++)
                    PopIn(index: i, child: _card(context, s, kAccessories[i])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Store s, Accessory acc) {
    final owned = s.owns(acc.id);
    final on = s.worn(s.buddy, acc.slot) == acc.id;
    return GestureDetector(
      onTap: () => _tap(context, acc),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: on ? const Color(0x44FFC83D) : const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? kGold : Colors.white24, width: 3),
        ),
        child: Column(
          children: [
            Expanded(child: Image.asset('assets/acc/${acc.id}.webp')),
            const SizedBox(height: 6),
            if (!owned)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CoinIcon(size: 22),
                  const SizedBox(width: 4),
                  Text('${acc.price}',
                      style: const TextStyle(
                          color: kGold, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              )
            else
              Text(on ? '✓ ${s.t('takeOff')}' : s.t('wear'),
                  style: TextStyle(
                      color: on ? kGold : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900)),
          ],
        ),
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

/// كل العوالم: يفتح العالم التالي عندما يُهزم زعيم العالم السابق
class WorldsScreen extends StatelessWidget {
  const WorldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return Scaffold(
      body: GameBackground(
        child: Column(
          children: [
            TopBar(title: '🗺 ${s.t('worlds')}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  for (var w = 0; w < kWorlds.length; w++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: PopIn(index: w, child: _WorldCard(world: w)),
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

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.world});
  final int world;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final key = kWorlds[world];
    final first = world * kWorldSize + 1;
    final open = s.unlocked(first);
    var stars = 0;
    var done = 0;
    for (var i = first; i < first + kWorldSize; i++) {
      stars += s.stars(i);
      if (s.stars(i) > 0) done++;
    }
    final colors = kWorldColors[key]!;
    return GestureDetector(
      onTap: open
          ? () {
              Sfx.play('tap');
              Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => MapScreen(world: world)));
            }
          : () => showSnack(context, s.t('finishPrev')),
      child: Container(
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: open ? colors : const [kGreyTop, kGreyBottom],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: open ? kGold : Colors.white24, width: 3),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), offset: Offset(0, 6), blurRadius: 8),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: open ? 0.45 : 0.15,
              child: Image.asset('assets/ui/${key}_map.webp',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(open ? kWorldIcon[key]! : '🔒',
                      style: const TextStyle(fontSize: 54)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.t(key),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                        const SizedBox(height: 4),
                        Text(
                            open
                                ? '⭐ $stars/${kWorldSize * 3}    ✅ $done/$kWorldSize'
                                : s.t('finishPrev'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  if (done == kWorldSize) const Text('🏆', style: TextStyle(fontSize: 36)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, this.world = 0});
  final int world;
  static const List<double> _xs = [-0.55, 0.0, 0.55, 0.0];

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final key = kWorlds[world];
    final first = world * kWorldSize + 1;
    final boss = first + kWorldSize - 1;
    return Scaffold(
      body: GameBackground(
        colors: kWorldColors[key]!,
        image: 'assets/ui/${key}_map.webp',
        child: Column(
          children: [
            TopBar(title: '${kWorldIcon[key]} ${s.t(key)}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  for (var i = first; i < boss; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Align(
                        alignment: Alignment(_xs[(i - 1) % 4], 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LevelNode(level: i),
                            if (i % 5 == 0 && s.stars(i) == 0)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 6),
                                child: Image.asset('assets/ui/chest_closed.webp', height: 44),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  BossNode(level: boss, world: key),
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

/// مرحلة الزعيم في آخر كل عالم
class BossNode extends StatelessWidget {
  const BossNode({super.key, required this.level, required this.world});
  final int level;
  final String world;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final open = s.unlocked(level);
    final st = s.stars(level);
    final fallback = Text(kWorldIcon[world]!, style: const TextStyle(fontSize: 90));
    return Column(
      children: [
        _Wobble(
          child: Opacity(
            opacity: open ? 1 : 0.5,
            child: Image.asset('assets/characters/boss_$world.webp',
                height: 150, errorBuilder: (_, __, ___) => fallback),
          ),
        ),
        const SizedBox(height: 6),
        Btn3D(
          width: 220,
          height: 64,
          top: open ? const Color(0xFFFF6B6B) : kGreyTop,
          bottom: open ? const Color(0xFFB91C1C) : kGreyBottom,
          onTap: open
              ? () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => PlayScreen(level: level)),
                  )
              : null,
          child: Text(open ? '⚔️ ${s.t('boss')}' : '🔒 ${s.t('boss')}',
              style: const TextStyle(fontSize: 24)),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Icon(Icons.star_rounded, size: 26, color: i < st ? kGold : Colors.white24),
          ],
        ),
      ],
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
enum PType { diff, letter, count, seq, math, tf, odd, numseq }

/// كيف تختلف الخانة المختلفة: شكل آخر، أو أصغر، أو مقلوبة
enum OddStyle { other, small, rotated }

class Puzzle {
  Puzzle({
    required this.type,
    this.cells = const [],
    this.cols = 3,
    this.answer = -1,
    this.options = const [],
    this.correct = -1,
    this.target = '',
    this.style = OddStyle.other,
    this.scale = 0.55,
    this.angle = pi,
    this.expr = '',
  });
  final PType type;
  final List<String> cells; // خانات الشبكة أو عناصر السلسلة
  final int cols;
  final int answer; // رقم الخانة المختلفة (ألغاز الشبكة)
  final List<String> options; // الخيارات (عدّ، سلسلة، حساب)
  final int correct; // رقم الخيار الصحيح
  final String target; // الشكل المطلوب عدّه
  final OddStyle style;
  final double scale; // حجم الخانة الأصغر
  final double angle; // زاوية الخانة المقلوبة
  final String expr; // نص عملية الحساب

  bool get hasOptions => options.isNotEmpty;
}

class PuzzleGen {
  PuzzleGen(this.level, this.lang, this.store, {this.world = 'forest'});
  final int level;
  final String world;
  final String lang;
  final Store store;
  final Random _r = Random();
  late final List<PType> _order = _makeOrder();

  int get _cols => level <= 3 ? 3 : (level <= 8 ? 4 : (level <= 15 ? 5 : 6));

  // كل مرحلة فيها خليط من الأنواع المتاحة، بترتيب مختلف كل مرة
  List<PType> _makeOrder() {
    final avail = <PType>[PType.diff, PType.count, PType.letter];
    if (level >= 4) avail.add(PType.seq);
    if (level >= 6) avail.add(PType.math);
    if (level >= 2) avail.add(PType.tf);
    if (level >= 2) avail.add(PType.odd);
    if (level >= 5) avail.add(PType.numseq);
    final n = questionsFor(level);
    // نوزّع الأنواع حتى لا يتكرر نفس النوع مرتين متتاليتين
    final out = <PType>[];
    var bag = <PType>[];
    while (out.length < n) {
      if (bag.isEmpty) bag = List<PType>.from(avail)..shuffle(_r);
      var i = bag.indexWhere((t) => out.isEmpty || t != out.last);
      if (i < 0) i = 0;
      out.add(bag.removeAt(i));
    }
    return out;
  }

  Puzzle make(int index) {
    final t = _order[index % _order.length];
    return switch (t) {
      PType.diff => _diff(),
      PType.letter => _letter(),
      PType.count => _count(),
      PType.seq => _seq(),
      PType.math => _math(),
      PType.tf => _tf(),
      PType.odd => _odd(),
      PType.numseq => _numseq(),
    };
  }

  /// أيها لا ينتمي: ثلاثة من مجموعة وواحد من مجموعة أخرى
  Puzzle _odd() {
    final gi = store.draw('oddGroup', kGroups.length, _r);
    final g = List<String>.from(kGroups[gi])..shuffle(_r);
    var oi = gi;
    while (oi == gi ||
        (kLivingGroups.contains(gi) && kLivingGroups.contains(oi))) {
      oi = _r.nextInt(kGroups.length);
    }
    final other = kGroups[oi][_r.nextInt(kGroups[oi].length)];
    final count = level < 10 ? 3 : 4; // 3 أو 4 من نفس المجموعة
    final list = [...g.take(count), other]..shuffle(_r);
    return Puzzle(
      type: PType.odd,
      options: list,
      correct: list.indexOf(other),
    );
  }

  /// الرقم الناقص في سلسلة أرقام
  Puzzle _numseq() {
    final steps = level < 10 ? [1, 2] : (level < 20 ? [2, 3, 5] : [3, 4, 5, 10]);
    final step = steps[_r.nextInt(steps.length)];
    final down = level >= 15 && _r.nextBool();
    const len = 5;
    final start = down ? step * len + _r.nextInt(10) : _r.nextInt(level < 10 ? 5 : 20);
    final nums = [for (var i = 0; i < len; i++) down ? start - i * step : start + i * step];
    final miss = 1 + _r.nextInt(len - 2);
    final value = nums[miss];
    final expr = [for (var i = 0; i < len; i++) i == miss ? '?' : '${nums[i]}'].join('  ');
    final opts = <int>{value, value + step, max(0, value - step), value + 1}.toList();
    final three = <int>[value, ...opts.where((e) => e != value).take(2)]..shuffle(_r);
    return Puzzle(
      type: PType.numseq,
      options: three.map((e) => '$e').toList(),
      correct: three.indexOf(value),
      expr: expr,
    );
  }

  Puzzle _grid(String common, String odd, PType type, OddStyle style) {
    final cols = _cols;
    final n = cols * cols;
    final ans = _r.nextInt(n);
    final cells = List<String>.generate(n, (i) => i == ans ? odd : common);
    // كلما تقدمت المراحل يصير الفرق أصعب ملاحظة
    final scale = level < 10 ? 0.55 : (level < 20 ? 0.72 : 0.82);
    final angle = level < 10 ? pi : (level < 20 ? pi / 2 : 0.5);
    return Puzzle(
      type: type,
      cells: cells,
      cols: cols,
      answer: ans,
      style: style,
      scale: scale,
      angle: angle,
    );
  }

  Puzzle _diff() {
    final pair = kEmojiPairs[store.draw('pair', kEmojiPairs.length, _r)];
    final swap = _r.nextBool();
    final common = swap ? pair[1] : pair[0];
    var roll = 0;
    if (level >= 10) {
      roll = _r.nextInt(3); // 0 شكل آخر، 1 أصغر، 2 مقلوب
    } else if (level >= 3) {
      final x = _r.nextInt(5);
      roll = x == 3 ? 1 : (x == 4 ? 2 : 0);
    }
    if (roll == 1) return _grid(common, common, PType.diff, OddStyle.small);
    if (roll == 2) return _grid(common, common, PType.diff, OddStyle.rotated);
    return _grid(common, swap ? pair[0] : pair[1], PType.diff, OddStyle.other);
  }

  Puzzle _letter() {
    final list = kLetterPairs[lang] ?? kLetterPairs['ar']!;
    final pair = list[store.draw('letter_$lang', list.length, _r)];
    final swap = _r.nextBool();
    return _grid(swap ? pair[1] : pair[0], swap ? pair[0] : pair[1],
        PType.letter, OddStyle.other);
  }

  /// خيارات رقمية قريبة من الجواب
  Puzzle _numOptions(Puzzle Function(List<String>, int) build, int value) {
    final spread = level < 10 ? 2 : 1;
    final opts = <int>{value};
    var guard = 0;
    while (opts.length < 3 && guard < 50) {
      guard++;
      final d = value + _r.nextInt(spread * 2 + 1) - spread;
      if (d >= 0) opts.add(d);
    }
    var k = 1;
    while (opts.length < 3) {
      opts.add(value + k++);
    }
    final list = opts.toList()..shuffle(_r);
    return build(list.map((e) => '$e').toList(), list.indexOf(value));
  }

  Puzzle _count() {
    String target;
    String other;
    if (level >= 8 && _r.nextBool()) {
      // شكلان متشابهان حتى يصعب العدّ
      final pair = kEmojiPairs[store.draw('cpair', kEmojiPairs.length, _r)];
      target = pair[0];
      other = pair[1];
    } else {
      // نصف ألغاز العدّ من أشياء العالم الحالي
      final pool = _r.nextBool() ? kWorldItems[world]! : kCountEmojis;
      target = pool[store.draw('count_${pool.length}_$world', pool.length, _r)];
      other = target;
      while (other == target) {
        other = pool[_r.nextInt(pool.length)];
      }
    }
    final cols = level < 10 ? 4 : 5;
    final total = cols * cols;
    final maxCount = level < 10 ? 10 : 15;
    final count = 2 + _r.nextInt(min(3 + level, maxCount - 1));
    final others = min(2 + _r.nextInt(2 + level ~/ 2), total - count);
    final cells = List<String>.filled(total, '');
    final idx = List<int>.generate(total, (i) => i)..shuffle(_r);
    for (var i = 0; i < count; i++) {
      cells[idx[i]] = target;
    }
    for (var i = count; i < count + others; i++) {
      cells[idx[i]] = other;
    }
    return _numOptions(
      (opts, correct) => Puzzle(
        type: PType.count,
        cells: cells,
        cols: cols,
        options: opts,
        correct: correct,
        target: target,
      ),
      count,
    );
  }

  Puzzle _seq() {
    // أنماط تصعب مع المراحل
    final patterns = <List<int>>[
      [0, 1],
      if (level >= 8) [0, 1, 2],
      if (level >= 12) [0, 0, 1],
      if (level >= 12) [0, 1, 1],
      if (level >= 16) [0, 1, 2, 1],
      if (level >= 20) [0, 0, 1, 1],
      if (level >= 20) [0, 1, 2, 2],
    ];
    final pat = patterns[_r.nextInt(patterns.length)];
    final kinds = pat.reduce(max) + 1;
    final pool = List<String>.from(kCountEmojis)..shuffle(_r);
    final items = pool.take(kinds).toList();
    final shown = level < 12 ? 6 : 7;
    final cells = [for (var i = 0; i < shown; i++) items[pat[i % pat.length]]];
    final next = items[pat[shown % pat.length]];
    final opts = <String>{next, ...items};
    for (final e in pool.skip(kinds)) {
      if (opts.length >= 3) break;
      opts.add(e);
    }
    final list = opts.take(3).toList();
    if (!list.contains(next)) list[0] = next;
    list.shuffle(_r);
    return Puzzle(
      type: PType.seq,
      cells: cells,
      options: list,
      correct: list.indexOf(next),
    );
  }

  Puzzle _tf() {
    var truth = _r.nextBool();
    String expr;
    if (_r.nextBool()) {
      final e = kCountEmojis[store.draw('tf', kCountEmojis.length, _r)];
      final n = 2 + _r.nextInt(level < 10 ? 5 : 8);
      var shown = truth ? n : n + (_r.nextBool() ? 1 : -1) * (1 + _r.nextInt(2));
      shown = max(1, shown);
      truth = shown == n;
      expr = '${e * n}\n=  $shown';
    } else {
      final big = level < 10 ? 5 : 9;
      final a = 1 + _r.nextInt(big);
      final b = 1 + _r.nextInt(big);
      var shown = truth ? a + b : a + b + (_r.nextBool() ? 1 : -1) * (1 + _r.nextInt(2));
      shown = max(0, shown);
      truth = shown == a + b;
      expr = '$a + $b = $shown';
    }
    return Puzzle(
      type: PType.tf,
      options: const ['✔', '✘'],
      correct: truth ? 0 : 1,
      expr: expr,
    );
  }

  Puzzle _math() {
    final e = kCountEmojis[store.draw('math', kCountEmojis.length, _r)];
    final big = level >= 15 ? 6 : 4;
    String expr;
    int value;
    if (level >= 18 && _r.nextBool()) {
      final b = 1 + _r.nextInt(3);
      final a = b + 1 + _r.nextInt(big);
      expr = '${e * a}\n−  ${e * b}';
      value = a - b;
    } else {
      final a = 1 + _r.nextInt(big);
      final b = 1 + _r.nextInt(big);
      expr = '${e * a}\n+  ${e * b}';
      value = a + b;
    }
    return _numOptions(
      (opts, correct) => Puzzle(
        type: PType.math,
        options: opts,
        correct: correct,
        expr: expr,
      ),
      value,
    );
  }
}

// ============================================================
// شاشة اللعب
// ============================================================
class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.level, this.daily = false});
  final int level;
  final bool daily;

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
  bool _tut = false; // إظهار اليد المرشدة
  bool _break = false; // انتهى وقت اللعب
  Timer? _foxTimer;
  int _foxRun = 0;
  bool _foxOn = false;
  double _foxY = 0;
  StreamSubscription<UserAccelerometerEvent>? _shakeSub;
  DateTime _lastShake = DateTime(2000);
  Timer? _playTick;

  String get _tutKey => _puzzle.hasOptions ? 'tut_opt' : 'tut_grid';
  Mood _buddyMood = Mood.normal;
  Mood _rivalMood = Mood.normal;
  String? _buddyLine;
  String? _rivalLine;
  Timer? _moodTimer;
  Timer? _clock;
  double _timeLeft = 0; // من 0 إلى 1
  int _pid = 0; // رقم اللغز الحالي (للحركات)
  int _shakeTick = 0;
  int _confetti = 0;
  int _streak = 0;
  int _bonus = 0;
  String? _comboText;
  bool _started = false;

  int get _qCount => questionsFor(widget.level);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final st = StoreScope.read(context);
      _gen = PuzzleGen(diffLevel(widget.level), st.lang, st,
          world: kWorlds[worldOf(widget.level)]);
      _newPuzzle();
      if (st.timeUp) {
        _break = true;
        _clock?.cancel();
      } else {
        _playTick = Timer.periodic(const Duration(seconds: 10), (_) => st.addPlayed(10));
        try {
          _shakeSub = userAccelerometerEventStream().listen((e) {
            final f = e.x * e.x + e.y * e.y + e.z * e.z;
            final now = DateTime.now();
            if (f > 300 && now.difference(_lastShake).inMilliseconds > 2500) {
              _lastShake = now;
              _hint();
            }
          }, onError: (_) {});
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    _clock?.cancel();
    _playTick?.cancel();
    _foxTimer?.cancel();
    _shakeSub?.cancel();
    super.dispose();
  }

  void _newPuzzle() {
    _puzzle = _gen.make(_q);
    _pid++;
    _comboText = null;
    _tut = !_gen.store.flag(_tutKey);
    _foxTimer?.cancel();
    _foxOn = false;
    if (widget.level >= 2 && !_tut && Random().nextInt(4) == 0) {
      _foxTimer = Timer(Duration(milliseconds: 2000 + Random().nextInt(3000)), () {
        if (!mounted || _busy) return;
        setState(() {
          _foxRun++;
          _foxOn = true;
          _foxY = -0.4 + Random().nextDouble() * 0.9;
        });
      });
    }
    _wrong.clear();
    _wrongOpts.clear();
    _hidden.clear();
    _okCell = null;
    _okOption = null;
    _busy = false;
    _resetMoods();
    _startClock();
  }

  void _startClock() {
    _clock?.cancel();
    final secs = secondsFor(widget.level);
    if (secs == 0) return;
    _timeLeft = 1;
    final step = 0.1 / secs;
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _busy) return;
      setState(() => _timeLeft -= step);
      if (_timeLeft <= 0) {
        _answer(false); // انتهى الوقت = خطأ
        _timeLeft = 1;
      }
    });
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
      _clock?.cancel();
      if (_tut) {
        s.setFlag(_tutKey);
        _tut = false;
      }
      HapticFeedback.mediumImpact();
      Sfx.play('correct');
      setState(() {
        _busy = true;
        _correct++;
        _okCell = cell;
        _okOption = option;
        _buddyMood = Mood.happy;
        _rivalMood = Mood.sad;
        _buddyLine = s.line('buddyHappy');
        _rivalLine = s.line('rivalSad');
        _confetti++;
        Future<void>.delayed(const Duration(milliseconds: 250),
            () => Sfx.say(s.buddy, 'buddyHappy', _buddyLine, s.lang));
        _streak++;
        if (_streak >= 3) {
          _bonus += 5;
          _comboText = '🔥 ×$_streak ${s.t('combo')}';
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;
      if (_q + 1 >= _qCount) {
        await _finish(true);
      } else {
        setState(() {
          _q++;
          _newPuzzle();
        });
      }
    } else {
      HapticFeedback.heavyImpact();
      Sfx.play('wrong');
      setState(() {
        _hearts--;
        _mistakes++;
        if (cell != null) _wrong.add(cell);
        if (option != null) _wrongOpts.add(option);
        _buddyMood = Mood.sad;
        _rivalMood = Mood.happy;
        _buddyLine = s.line('buddySad');
        _rivalLine = s.line('rivalHappy');
        _shakeTick++;
        Future<void>.delayed(const Duration(milliseconds: 300),
            () => Sfx.say(s.rival, 'rivalHappy', _rivalLine, s.lang));
        _streak = 0;
        _comboText = null;
      });
      if (_hearts <= 0) {
        _clock?.cancel();
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
    _clock?.cancel();
    final int stars = won ? max(1, min(3, 3 - _mistakes)) : 0;
    final coins = (won ? _correct * 2 + stars * 10 : _correct * 2) + _bonus;
    var coins2 = coins;
    String? newStamp;
    final chest = !widget.daily &&
        won &&
        widget.level % 5 == 0 &&
        s.stars(widget.level) == 0;
    Sfx.play(won ? 'win' : 'lose');
    if (widget.daily) {
      if (won) {
        final streak = await s.completeDaily();
        newStamp = await s.addStamp();
        coins2 += 40 + min(streak, 7) * 10;
      }
    } else {
      await s.saveStars(widget.level, stars);
    }
    await s.addCoins(coins2);
    if (!mounted) return;
    nav.pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ResultScreen(
        level: widget.level,
        stars: stars,
        coins: coins2,
        won: won,
        chest: chest,
        daily: widget.daily,
        stamp: newStamp,
      ),
    ));
  }

  Future<void> _catchFox() async {
    if (!_foxOn) return;
    final s = StoreScope.read(context);
    HapticFeedback.mediumImpact();
    Sfx.play('coin');
    setState(() {
      _foxOn = false;
      _confetti++;
      _buddyMood = Mood.happy;
      _rivalMood = Mood.sad;
      _buddyLine = s.line('buddyHappy');
      _rivalLine = s.line('rivalSad');
    });
    await s.addCoins(15);
    _moodTimer?.cancel();
    _moodTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted && !_busy) setState(_resetMoods);
    });
  }

  Future<void> _hint() async {
    if (_busy) return;
    final s = StoreScope.read(context);
    if (_puzzle.hasOptions) {
      final wrongLeft = <int>[
        for (var i = 0; i < _puzzle.options.length; i++)
          if (i != _puzzle.correct && !_wrongOpts.contains(i)) i,
      ];
      if (wrongLeft.isEmpty) return;
      if (!await s.spend(kHintCost)) {
        if (mounted) showSnack(context, s.t('noCoins'));
        return;
      }
      if (!mounted) return;
      Sfx.play('coin');
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
      Sfx.play('coin');
      setState(() => _hidden.addAll(candidates.take(candidates.length ~/ 2 + 1)));
    }
  }

  String _question(Store s) {
    return switch (_puzzle.type) {
      PType.diff => s.t('qDiff'),
      PType.letter => s.t('qLetter'),
      PType.count => s.t('qCount').replaceAll('{e}', _puzzle.target),
      PType.seq => s.t('qSeq'),
      PType.math => s.t('qMath'),
      PType.tf => s.t('qTF'),
      PType.odd => s.t('qOdd'),
      PType.numseq => s.t('qNumSeq'),
    };
  }

  Widget _tile(String v, List<Color> colors, double fontSize,
      [OddStyle style = OddStyle.other, int index = 0]) {
    Widget text = Text(
      v,
      style: TextStyle(
        fontSize: style == OddStyle.small ? fontSize * _puzzle.scale : fontSize,
        fontWeight: FontWeight.w900,
        color: kInk,
      ),
    );
    if (style == OddStyle.rotated) {
      text = Transform.rotate(angle: _puzzle.angle, child: text);
    }
    return PopIn(
      key: ValueKey('t$_pid-$index'),
      index: index,
      drop: true,
      child: Container(
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
          child: text,
        ),
      ),
    ));
  }

  static const List<Color> _normalTile = [Colors.white, Color(0xFFE6E0FF)];
  static const List<Color> _okTile = [Color(0xFF86EFAC), Color(0xFF16A34A)];
  static const List<Color> _badTile = [Color(0xFFFCA5A5), Color(0xFFDC2626)];

  Widget _diffGrid() {
    final p = _puzzle;
    final fs = switch (p.cols) { 3 => 46.0, 4 => 36.0, 5 => 28.0, _ => 22.0 };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: AspectRatio(
          aspectRatio: 1,
          child: GridView.count(
            crossAxisCount: p.cols,
            mainAxisSpacing: p.cols >= 6 ? 6 : 10,
            crossAxisSpacing: p.cols >= 6 ? 6 : 10,
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: _tile(
                            p.cells[i],
                            _okCell == i
                                ? _okTile
                                : (_wrong.contains(i) ? _badTile : _normalTile),
                            fs,
                            i == p.answer ? p.style : OddStyle.other,
                            i,
                          ),
                        ),
                        if (_tut && i == p.answer && !_busy)
                          const Positioned(
                              right: -6, bottom: -26, child: PointingHand()),
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

  Widget _countBoard() {
    final p = _puzzle;
    return Center(
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
                            child: Text(c, style: const TextStyle(fontSize: 56)),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _seqBoard() {
    final p = _puzzle;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 10,
            children: [
              for (final c in p.cells) Text(c, style: const TextStyle(fontSize: 40)),
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kGold,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kInk, width: 3),
                ),
                child: const Text('?',
                    style: TextStyle(
                        color: kInk, fontSize: 32, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mathBoard({bool full = false}) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            full ? _puzzle.expr : '${_puzzle.expr}\n=  ?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              height: 1.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionsArea() {
    final p = _puzzle;
    final board = switch (p.type) {
      PType.seq => _seqBoard(),
      PType.math => _mathBoard(),
      PType.tf => _mathBoard(full: true),
      PType.numseq => _mathBoard(full: true),
      PType.odd => const Center(
          child: Text('🤔', style: TextStyle(fontSize: 90))),
      _ => _countBoard(),
    };
    final isEmoji = p.type == PType.seq || p.type == PType.odd;
    final many = p.options.length > 3;
    return Column(
      children: [
        Expanded(child: SingleChildScrollView(child: board)),
        Wrap(
          spacing: 14,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < p.options.length; i++)
              PopIn(
                key: ValueKey('o$_pid-$i'),
                index: i + 3,
                child: Btn3D(
                width: many ? 74 : 88,
                height: many ? 74 : 64,
                top: _okOption == i
                    ? const Color(0xFFFFD95A)
                    : (_wrongOpts.contains(i) ? kGreyTop : kVioletTop),
                bottom: _okOption == i
                    ? kGoldDark
                    : (_wrongOpts.contains(i) ? kGreyBottom : kVioletBottom),
                onTap: (_busy || _wrongOpts.contains(i))
                    ? null
                    : () => _answer(i == p.correct, option: i),
                child: Text(p.options[i],
                    style: TextStyle(fontSize: isEmoji ? 36 : 32)),
              )),
            if (_tut && !_busy)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('👆 ${StoreScope.read(context).t('tapHere')}  ${p.options[p.correct]}',
                    style: const TextStyle(
                        color: kGold, fontSize: 20, fontWeight: FontWeight.w900)),
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
    if (_break) {
      return Scaffold(
        body: GameBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Critter(kind: s.buddy, mood: Mood.sad, height: 180),
                  const SizedBox(height: 12),
                  GoldTitle('😴 ${s.t('breakTitle')}', size: 32),
                  const SizedBox(height: 12),
                  Text(s.t('breakText'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5)),
                  const SizedBox(height: 24),
                  Btn3D(
                    width: 220,
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Text(s.t('ok')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
      GameBackground(
        colors: kWorldColors[kWorlds[worldOf(widget.level)]]!,
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
                    widget.daily
                        ? '🌟 ${s.t('daily')}'
                        : s.t('level').replaceAll('{n}', '${widget.level}'),
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
                for (var i = 0; i < _qCount; i++)
                  Container(
                    width: 22,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i < _q ? kGold : (i == _q ? Colors.white : Colors.white24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
            ),
            if (secondsFor(widget.level) > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 8, 40, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _timeLeft.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    color: _timeLeft > 0.3 ? kGreenTop : const Color(0xFFEF4444),
                  ),
                ),
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
              child: Shake(
                trigger: _shakeTick,
                child: _puzzle.hasOptions ? _optionsArea() : _diffGrid(),
              ),
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
                      height: 130,
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
                        Text('📳💡 ${s.t('hint')}', style: const TextStyle(fontSize: 18)),
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
                      height: 125,
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
      Positioned.fill(
        child: IgnorePointer(child: Confetti(trigger: _confetti)),
      ),
      if (_foxOn)
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            key: ValueKey('fox$_foxRun'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 3200),
            onEnd: () {
              if (mounted) setState(() => _foxOn = false);
            },
            builder: (context, v, child) => Align(
              alignment: Alignment(-1.4 + 2.8 * v, _foxY + sin(v * pi * 6) * 0.03),
              child: child,
            ),
            child: GestureDetector(
              onTap: _catchFox,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.t('catchIt'),
                      style: const TextStyle(
                          color: kGold, fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(s.rival == 'fox' ? '🦊💰' : '🦉💰',
                      style: const TextStyle(fontSize: 54)),
                ],
              ),
            ),
          ),
        ),
      if (_comboText != null)
        Positioned(
          left: 0,
          right: 0,
          top: 150,
          child: IgnorePointer(
            child: Center(
              child: ComboBanner(key: ValueKey(_streak), text: _comboText!),
            ),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// شاشة النتيجة
// ============================================================
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.level,
    required this.stars,
    required this.coins,
    required this.won,
    this.chest = false,
    this.daily = false,
    this.stamp,
  });
  final bool daily;
  final String? stamp;
  final int level;
  final int stars;
  final int coins;
  final bool won;
  final bool chest;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _shown = 0; // كم نجمة ظهرت
  int _confetti = 0;
  String? _buddyLine;
  String? _rivalLine;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.stars; i++) {
      _timers.add(Timer(Duration(milliseconds: 500 + i * 450), () {
        if (!mounted) return;
        Sfx.play('coin');
        setState(() {
          _shown = i + 1;
          if (_shown == widget.stars) _confetti++;
        });
      }));
    }
    if (widget.chest) {
      _timers.add(Timer(Duration(milliseconds: 900 + widget.stars * 450), () {
        if (!mounted) return;
        final s = StoreScope.read(context);
        showReward(context,
            title: s.t('chestTitle'),
            closed: 'assets/ui/chest_closed.webp',
            open: 'assets/ui/chest_open.webp',
            amount: 100);
      }));
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final nav = Navigator.of(context);
    final won = widget.won;
    final level = widget.level;
    if (_buddyLine == null) {
      _buddyLine = s.line(won ? 'buddyHappy' : 'buddySad');
      final line = _buddyLine;
      Future<void>.delayed(const Duration(milliseconds: 900),
          () => Sfx.say(s.buddy, won ? 'buddyHappy' : 'buddySad', line, s.lang));
    }
    _rivalLine ??= s.line(won ? 'rivalSad' : 'rivalHappy');
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        GameBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: CoinCounter(),
                ),
                const SizedBox(height: 8),
                PopIn(child: GoldTitle(s.t(won ? 'win' : 'lose'), size: 34)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i == 1 ? 18 : 0),
                        child: AnimatedScale(
                          scale: i < _shown ? 1.0 : 0.75,
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.elasticOut,
                          child: Icon(
                            Icons.star_rounded,
                            size: i == 1 ? 84 : 66,
                            color: i < _shown ? kGold : Colors.white24,
                            shadows: const [Shadow(color: kInk, offset: Offset(0, 4))],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: widget.coins),
                  duration: const Duration(milliseconds: 1400),
                  builder: (context, v, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CoinIcon(size: 34),
                      const SizedBox(width: 8),
                      Text(
                        s.t('coinsEarned').replaceAll('{n}', '$v'),
                        style: const TextStyle(
                            color: kGold, fontSize: 30, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                if (widget.stamp != null) ...[
                  const SizedBox(height: 12),
                  PopIn(
                    index: 20,
                    child: Transform.rotate(
                      angle: -0.12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0x22FFFFFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFF6B8B), width: 4),
                        ),
                        child: Column(
                          children: [
                            Text(widget.stamp!, style: const TextStyle(fontSize: 44)),
                            Text(s.t('newStamp'),
                                style: const TextStyle(
                                    color: Color(0xFFFF6B8B),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Critter(
                        kind: s.buddy,
                        mood: won ? Mood.happy : Mood.sad,
                        height: 140,
                        bubble: _buddyLine,
                        bubbleWidth: 140,
                      ),
                    ),
                    Expanded(
                      child: Critter(
                        kind: s.rival,
                        mood: won ? Mood.sad : Mood.happy,
                        height: 130,
                        bubble: _rivalLine,
                        bubbleWidth: 140,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (won && level < kLevels && !widget.daily) ...[
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
                if (!widget.daily) ...[
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
                ],
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
        Positioned.fill(
          child: IgnorePointer(child: Confetti(trigger: _confetti)),
        ),
      ]),
    );
  }
}
