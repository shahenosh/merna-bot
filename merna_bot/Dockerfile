# استخدام نسخة تحتوي على Flutter
FROM instrumentisto/flutter:stable AS build

WORKDIR /app
# بما أن Root Directory هو merna_bot، منسخ الملفات فوراً
COPY . .

# تجهيز Flutter وجلب المكتبات
RUN flutter pub get
# بناء التطبيق كـ Executable
RUN flutter build linux --release || dart compile exe bin/MillionGame.dart -o bin/main

FROM debian:stable-slim
# نقل الملف التشغيلي للبيئة النهائية
COPY --from=build /app/bin/main /app/main
# تشغيل البوت
CMD ["/app/main"]
