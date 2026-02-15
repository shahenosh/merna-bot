import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;
// استيراد ملف المليون
import 'MillionGame.dart';

// ===================== الإعدادات =====================
const String OWNER_JID = "almuftrs@syriatalk.info";
const String BOT_JID_STR = "tsunamei@syriatalk.info";
const String BOT_PASS = "tsunamei123";
const String BOT_NICK = "MeRnA";
const String STATUS_TEXT = "بوت ميرنا لطلبي اضف almuftrs";
// ===================================================

void main() => MernaLegendBot().run();

class MernaLegendBot {
  late xmpp.Connection connection;
  List<String> players = [];
  String lastRoom = "";
  final Random _random = Random();

  // تعريف نسخة من لعبة المليون
  final MillionGame million = MillionGame();

  List<Map<String, String>> riddlesList = [];
  List<String> futurePredictions = [];
  List<String> funnyPrizes = [];

  String currentAnswer = "";
  String targetNick = "";
  bool isRiddleActive = false;
  Timer? riddleTimer;

  final Map<String, int> horoIds = {
    "الحمل": 1,
    "الثور": 2,
    "الجوزاء": 3,
    "السرطان": 4,
    "الأسد": 5,
    "الاسد": 5,
    "العذراء": 6,
    "الميزان": 7,
    "العقرب": 8,
    "القوس": 9,
    "الجدي": 10,
    "الدلو": 11,
    "الحوت": 12
  };

  final List<String> userDescriptions = [
    "ياسمينة شامية بتنشر ريحة طيبة وين ما كانت 🌸",
    "قلبه أبيض من التلج ولسانه بينقط عسل مهضوم 🍯",
    "رايق وميوزك وبيحب كاسة المتة بفيّة الياسمين 🧉",
    "شخصية قوية ومهيبة والكل بيحسبله ألف حساب 👑",
    "روح الروم وضحكته بتعدي الكل بالإيجابية ✨",
    "فنان بالردود ودايماً حضوره إله نكهة خاصة 🍭"
  ];

  void run() {
    _initFiles();
    _loadRoom();
    var jid = xmpp.Jid.fromFullJid(BOT_JID_STR);
    final settings = xmpp.XmppAccountSettings(
        BOT_JID_STR, jid.local, jid.domain, BOT_PASS, 5222,
        host: "syriatalk.info");
    settings.resource = BOT_NICK;
    connection = xmpp.Connection(settings);
    connection.connect();
    connection.connectionStateStream.listen((state) {
      if (state == xmpp.XmppConnectionState.Authenticated) {
        print("✅ ميرنا أونلاين بكامل عتادها!");
        _updatePresence();
        _setup();
        if (lastRoom.isNotEmpty)
          Timer(Duration(seconds: 2), () => _join(lastRoom));
      }
    });
  }

  void _initFiles() {
    try {
      File fRiddles = File('riddles.txt');
      if (fRiddles.existsSync()) {
        riddlesList =
            fRiddles.readAsLinesSync().where((l) => l.contains('|')).map((l) {
          var parts = l.split('|');
          return {"q": parts[0].trim(), "a": parts[1].trim()};
        }).toList();
      }
      File fFuture = File('future.txt');
      if (fFuture.existsSync())
        futurePredictions =
            fFuture.readAsLinesSync().where((l) => l.isNotEmpty).toList();
      File fPrizes = File('prizes.txt');
      if (fPrizes.existsSync())
        funnyPrizes =
            fPrizes.readAsLinesSync().where((l) => l.isNotEmpty).toList();

      print("📊 تم تحميل ${riddlesList.length} حزورة.");
    } catch (e) {
      print("❌ خطأ بالملفات: $e");
    }
  }

  void _setup() {
    xmpp.MessageHandler.getInstance(connection)
        .messagesStream
        .listen((msg) async {
      if (msg == null || msg.body == null || msg.fromJid?.resource == BOT_NICK)
        return;

      final body = msg.body!.trim();
      final senderNick = msg.fromJid?.resource ?? "عضو";
      final isGroup = (msg.type == xmpp.MessageStanzaType.GROUPCHAT);

      // --- 1. فحص أمر "حزورة" ---
      if (body.startsWith("حزورة ")) {
        if (isRiddleActive) return;
        String target = body.replaceFirst("حزورة ", "").trim();
        if (target.isNotEmpty && riddlesList.isNotEmpty) {
          var riddle = riddlesList[_random.nextInt(riddlesList.length)];
          currentAnswer = riddle['a']!;
          targetNick = target;
          isRiddleActive = true;
          _send(
              msg.fromJid!,
              "🤔 حزيره لـ [$targetNick]:\n📝 ${riddle['q']}\n━━━━━━━━━━━━━\n⏱️ معك 30 ثانية يا بطل!",
              isGroup);
          riddleTimer = Timer(Duration(seconds: 30), () {
            if (isRiddleActive) {
              _send(
                  msg.fromJid!,
                  "⏰ خلص الوقت لـ [$targetNick]! الجواب: [$currentAnswer] 😋",
                  isGroup);
              _resetRiddle();
            }
          });
          return;
        }
      }

      // --- 2. فحص الجواب على الحزورة ---
      if (isRiddleActive && currentAnswer.isNotEmpty) {
        if (body == currentAnswer) {
          if (senderNick == targetNick) {
            riddleTimer?.cancel();
            String prize = funnyPrizes.isNotEmpty
                ? funnyPrizes[_random.nextInt(funnyPrizes.length)]
                : "بوسة 💋";
            _send(msg.fromJid!,
                "🎉 مبروك [$senderNick] جوابك صح!\n🎁 ربحت: $prize", isGroup);
            _resetRiddle();
            return;
          } else if (body.length > 1 && !body.startsWith("حزورة ")) {
            _send(
                msg.fromJid!,
                "⛔ تؤبشني [$senderNick] الدور لـ [$targetNick] بس! 🤫",
                isGroup);
            return;
          }
        }
      }

      // --- 3. تمرير الرسالة للمليون ---
      million.handleMillion(msg, body, senderNick, _send);

      // --- 4. باقي الأوامر العامة ---

      // رد ميرنا لما حدا يناديها
      if (body.toLowerCase() == "بوت") {
        _send(msg.fromJid!, "يا عيون البوت.. شو بدك  🌸", isGroup);
      }
      // أمر النكز
      else if (body.startsWith("نكز ")) {
        String t = body.replaceFirst("نكز ", "").trim();
        _send(
            msg.fromJid!, "👉 [$senderNick] ينكز [$t].. وين غطست؟ 🌸", isGroup);
      }
      // أمر حظي (العام)
      else if (body == "حظي") {
        int perc = _random.nextInt(101);
        _send(msg.fromJid!, "✨ [$senderNick] حظك اليوم هو: $perc% 🍀", isGroup);
      }
      // أمر حظي من (مخصص مع تعليقات)
      else if (body.startsWith("حظي من ")) {
        String t = body.replaceAll("حظي من ", "").trim();
        int perc = _random.nextInt(101);
        String comment = "";
        if (perc >= 90) {
          comment = "يا ويلي شو محظوظ! الحظ راكض وراك ركد 😍";
        } else if (perc >= 75) {
          comment = "حظك بيجنن، متل فنجان قهوة الصبح عالروقان ☕";
        } else if (perc >= 50) {
          comment = "ماشي حالك، يعني نص نص.. بدها شوية تفاؤل 🌤️";
        } else if (perc >= 25) {
          comment = "يا لطيف! حظك بدو رقية شرعية وشوية بخور 🧿";
        } else {
          comment = "يا حيف! حظك نايم بالعسل، روح غسل وجهك وارجع 😴";
        }
        _send(msg.fromJid!,
            "❤️ [$senderNick] حظك من [$t]: $perc% \n💬 $comment", isGroup);
      } else if (body == "مستقبل" || body == "مستقبلي") {
        String res = futurePredictions.isNotEmpty
            ? futurePredictions[_random.nextInt(futurePredictions.length)]
            : "مستقبلك عسل 🌸";
        _send(msg.fromJid!, "🔮 [$senderNick]: $res", isGroup);
      } else if (body.startsWith("وصف ")) {
        String t = body.replaceAll("وصف ", "").trim();
        _send(
            msg.fromJid!,
            "📝 وصف [$t]: ${userDescriptions[_random.nextInt(userDescriptions.length)]}",
            isGroup);
      } else if (body.startsWith("برج ")) {
        _send(
            msg.fromJid!,
            "⏳ ثواني [$senderNick]...\n" +
                await _fetchFromElabraj(body.replaceAll("برج ", "").trim()),
            isGroup);
      } else if (body.startsWith("تفسير ")) {
        _send(
            msg.fromJid!,
            "⏳ ثواني [$senderNick]...\n" +
                await _fetchDream(body.replaceAll("تفسير ", "").trim()),
            isGroup);
      } else if (body == "تحديث" && msg.fromJid?.userAtDomain == OWNER_JID) {
        _initFiles();
        _send(msg.fromJid!, "✅ تم التحديث!", isGroup);
      } else if (body == "تست") {
        _send(msg.fromJid!, "📢 شغال ليرة ذهب ✅", isGroup);
      } else if (body == "تصميم") {
        _send(msg.fromJid!, "🤖 بوت ميرنا، تطوير: almuftrs@syriatalk.info 🌸",
            isGroup);
      } else if (msg.fromJid?.userAtDomain == OWNER_JID) {
        if (body.startsWith("اذهب ")) {
          lastRoom = body.split(" ")[1];
          _saveRoom(lastRoom);
          _join(lastRoom);
        } else if (body == "ريستارت") exit(0);
      }
    });
  }

  void _resetRiddle() {
    currentAnswer = "";
    targetNick = "";
    isRiddleActive = false;
    riddleTimer?.cancel();
  }

  Future<String> _fetchDream(String dream) async {
    try {
      final url = Uri.parse("https://www.tafsir-ahlam.com/search?q=" +
          Uri.encodeComponent(dream));
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      var doc = parse(utf8.decode(res.bodyBytes));
      return doc.querySelector('.entry-summary p')?.text.trim() ??
          "ما لقيت تفسير.";
    } catch (e) {
      return "❌ خطأ اتصال.";
    }
  }

  Future<String> _fetchFromElabraj(String sign) async {
    int? id = horoIds[sign];
    if (id == null) return "اكتب اسم البرج صح.";
    try {
      final url = Uri.parse(
          "https://www.elabraj.net/ar/horoscope/daily/" + id.toString());
      final res = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      var doc = parse(utf8.decode(res.bodyBytes));
      String text = doc.querySelector('.horoscope-daily-text')?.text.trim() ??
          "فشل سحب البرج.";
      return text
          .replaceAll("مهنياً:", "\n\n🔹 مهنياً:")
          .replaceAll("عاطفياً:", "\n\n\n🔹 عاطفياً:")
          .replaceAll("صحياً:", "\n\n🔹 صحياً:");
    } catch (e) {
      return "❌ خطأ أبراج.";
    }
  }

  void _updatePresence() {
    var p = xmpp.PresenceStanza();
    p.status = STATUS_TEXT;
    connection.writeStanza(p);
  }

  void _join(String r) => connection.write(
      "<presence to='$r/$BOT_NICK'><x xmlns='http://jabber.org/protocol/muc'/></presence>");

  void _send(xmpp.Jid to, String txt, bool gp) {
    final s = xmpp.MessageStanza(xmpp.AbstractStanza.getRandomId(),
        gp ? xmpp.MessageStanzaType.GROUPCHAT : xmpp.MessageStanzaType.CHAT);
    s.toJid = gp ? xmpp.Jid.fromFullJid(to.local + "@" + to.domain) : to;
    s.body = txt;
    connection.writeStanza(s);
  }

  void _saveRoom(String r) => File("room.txt").writeAsStringSync(r);
  void _loadRoom() {
    if (File("room.txt").existsSync())
      lastRoom = File("room.txt").readAsStringSync();
  }
}
