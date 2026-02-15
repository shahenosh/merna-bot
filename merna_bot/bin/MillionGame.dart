import 'dart:async';
import 'dart:math';
import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

class MillionGame {
  final Random _random = Random();
  
  // المبالغ المالية ونقاط التثبيت
  final List<String> prizes = [
    "100", "200", "300", "500", "1,000", 
    "2,000", "4,000", "8,000", "16,000", "32,000", 
    "64,000", "125,000", "250,000", "500,000", "1,000,000"
  ];

  Map<String, Map<String, dynamic>> sessions = {};
  Timer? gameTimer;

  // قاعدة بيانات الأسئلة (المراحل كاملة)
  final Map<int, List<Map<String, String>>> allQuestions = {
    1: [
      {'q': 'اكمل المثل التالي: مين أمنك لا تخونو ولو كنت...', 'opts': '• خوان\n• ندل', 'ans': 'خوان'},
      {'q': 'ما هي لغة أهل الجنة؟', 'opts': '• العربية\n• الأرامية', 'ans': 'العربية'},
      {'q': 'ما هو صوت القطط؟', 'opts': '• مواء\n• عواء', 'ans': 'مواء'},
      {'q': 'السنة تتألف من كم شهر؟', 'opts': '• 12 شهر\n• 10 شهور', 'ans': '12'},
    ],
    2: [
      {'q': 'ما هو اسم المكان الذي يسكنه النحل؟', 'opts': '• الخلية\n• العش', 'ans': 'الخلية'},
      {'q': 'ما هي عاصمة فرنسا؟', 'opts': '• باريس\n• ليون', 'ans': 'باريس'},
      {'q': 'البرازيل تشتهر بإنتاج الـ...', 'opts': '• بن\n• شاي', 'ans': 'بن'},
    ],
    3: [
      {'q': 'أين يوجد المسجد الأموي؟', 'opts': '• دمشق\n• حلب', 'ans': 'دمشق'},
      {'q': 'ما هي الدولة التي ليس لها جيش؟', 'opts': '• سويسرا\n• سوريا', 'ans': 'سويسرا'},
    ],
    4: [
      {'q': 'مدينة سورية تسمى الشهباء هي...', 'opts': '• حلب\n• حمص', 'ans': 'حلب'},
      {'q': 'على أي بلد أطلق اسم بلاد الرافدين؟', 'opts': '• العراق\n• مصر', 'ans': 'العراق'},
    ],
    5: [
      {'q': 'من هو سيف الله المسلول؟', 'opts': '• خالد بن الوليد\n• عمر بن الخطاب', 'ans': 'خالد بن الوليد'},
      {'q': 'قائد معركة حطين هو...', 'opts': '• صلاح الدين الأيوبي\n• الزير سالم', 'ans': 'صلاح الدين الأيوبي'},
    ],
    // فيك تكمل باقي المراحل (6 لـ 15) بنفس هاد التنسيق تماماً
  };

  void handleMillion(xmpp.MessageStanza msg, String body, String senderNick, Function sendCallback) {
    final String userJid = msg.fromJid!.toString();
    final bool isGroup = (msg.type == xmpp.MessageStanzaType.GROUPCHAT);

    // أمر تشغيل اللعبة
    if (body == "المليون") {
      if (sessions.containsKey(userJid)) {
        sendCallback(msg.fromJid!, "⚠️ تؤبشني [$senderNick] اللعبة شغالة عندك! اكتب (بدء) لنكفي.", isGroup);
      } else {
        sessions[userJid] = {'nick': senderNick, 'level': 1, 'fixed': "0", 'status': 'idle', 'current_q': null};
        sendCallback(msg.fromJid!, "💰 **من سيربح المليون مع ميرنا** 💰\n━━━━━━━━━━━━━\n✨ المشترك: [$senderNick]\n📝 الجواب بكتابة الكلمة حصراً.\n━━━━━━━━━━━━━\nاكتب (بدء) لتبلش يا بطل!", isGroup);
      }
      return;
    }

    // حماية: التأكد أن المتحدث هو صاحب اللعبة
    if (!sessions.containsKey(userJid)) return;
    var s = sessions[userJid]!;

    // أمر البدء أو المتابعة
    if (body == "بدء" || body == "متابعة") {
      int lvl = s['level'] ?? 1;
      
      if (!allQuestions.containsKey(lvl)) {
        sendCallback(msg.fromJid!, "🏁 مبروك! خلصت كل الأسئلة المتاحة حالياً.", isGroup);
        return;
      }

      var qList = allQuestions[lvl]!;
      var q = qList[_random.nextInt(qList.length)];
      s['current_q'] = q;
      s['status'] = 'playing';

      // عرض منسق ومرتب للخيارات
      String qMsg = "💎 **السؤال رقم [ $lvl ]** 💎\n"
                    "💵 الجائزة: ${prizes[lvl - 1]} دولار\n"
                    "━━━━━━━━━━━━━\n"
                    "❓ ${q['q']}\n\n"
                    "${q['opts']}\n"
                    "━━━━━━━━━━━━━\n"
                    "⏱️ معك 30 ثانية للجواب بالكلمة!";
      
      sendCallback(msg.fromJid!, qMsg, isGroup);
      _startTimer(msg, userJid, senderNick, q['ans'] ?? "", isGroup, sendCallback);
      return;
    }

    // معالجة الجواب
    if (s['status'] == 'playing' && s['current_q'] != null) {
      String correctAnswer = s['current_q']!['ans']!.trim();
      
      if (body == correctAnswer) {
        gameTimer?.cancel();
        int lvl = s['level'];
        
        if (lvl >= 15) {
          sendCallback(msg.fromJid!, "🎊 مبرووووك!!! [$senderNick] صار مليونير ميرنا! 👑", isGroup);
          sessions.remove(userJid);
        } else {
          // نظام تثبيت الرصيد
          if (lvl == 5) s['fixed'] = "1,000";
          if (lvl == 10) s['fixed'] = "32,000";
          
          s['level'] = lvl + 1;
          s['status'] = 'waiting';
          
          String winMsg = "✅ برافو [$senderNick]! إجابة صحيحة.\n💰 رصيدك الحالي: ${prizes[lvl-1]} دولار.\n";
          if (lvl == 5 || lvl == 10) winMsg += "📌 تم تثبيت رصيدك على ${s['fixed']} دولار.\n";
          winMsg += "اكتب (متابعة) للسؤال التالي.";
          
          sendCallback(msg.fromJid!, winMsg, isGroup);
        }
      } 
      // فحص إذا كان الجواب المكتوب هو أحد الخيارات الخاطئة
      else if (s['current_q']!['opts']!.contains(body) && body.length > 1) {
        gameTimer?.cancel();
        sendCallback(msg.fromJid!, "❌ للأسف يا [$senderNick] غلط!\nالجواب الصح هو: [ $correctAnswer ]\nرصيدك رجع لـ [ ${s['fixed']} ] دولار. نورتنا! 🌸", isGroup);
        sessions.remove(userJid);
      }
    }

    // أمر الإيقاف
    if (body == "ايقاف") {
      gameTimer?.cancel();
      s['status'] = 'paused';
      sendCallback(msg.fromJid!, "⏸️ تم إيقاف اللعبة يا [$senderNick]. اكتب (متابعة) لما ترجع.", isGroup);
    }
  }

  void _startTimer(msg, userJid, nick, ans, isGroup, sendCallback) {
    gameTimer?.cancel();
    gameTimer = Timer(Duration(seconds: 30), () {
      if (sessions.containsKey(userJid) && sessions[userJid]!['status'] == 'playing') {
        sendCallback(msg.fromJid!, "⏱️ [$nick].. وين غطست؟ باقي 10 ثواني وبتروح عليك! 🔥", isGroup);
        
        gameTimer = Timer(Duration(seconds: 10), () {
          if (sessions.containsKey(userJid) && sessions[userJid]!['status'] == 'playing') {
            sendCallback(msg.fromJid!, "⏰ انتهى الوقت! طار المليون من ايدك يا [$nick].. الجواب كان: [$ans]", isGroup);
            sessions.remove(userJid);
          }
        });
      }
    });
  }
}