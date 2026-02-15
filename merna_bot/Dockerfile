FROM dart:stable

WORKDIR /app

# نسخ الملفات (بما أن الـ Root هو merna_bot)
COPY . .

# جلب المكتبات
RUN dart pub get

# تشغيل ملف البوت (تأكد من اسم الملف جوا مجلد bin، غالباً merna.dart)
CMD ["dart", "run", "bin/main.dart"]
