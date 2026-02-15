FROM dart:stable AS build

WORKDIR /app

# نسخ ملفات المشروع (بما أن Root هو merna_bot)
COPY . .

# جلب المكتبات وبناء الملف التشغيلي
RUN dart pub get
RUN dart compile exe bin/MillionGame.dart -o bin/main

# بيئة التشغيل النهائية خفيفة جداً
FROM debian:stable-slim
COPY --from=build /app/bin/main /app/main

# تشغيل ميرنا
CMD ["/app/main"]
