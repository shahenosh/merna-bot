FROM dart:stable

WORKDIR /app

# نسخ الملفات (بما أن الـ Root هو merna_bot)
COPY . .

# جلب المكتبات
RUN dart pub get

# تشغيل البوت الأساسي مباشرة
CMD ["dart", "run", "bin/merna.dart"]
