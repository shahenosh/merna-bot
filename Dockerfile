FROM dart:stable AS build
WORKDIR /app
# نسخ المجلد بالكامل
COPY . .
# الدخول للمجلد اللي فيه الملفات
WORKDIR /app/merna_bot
RUN dart pub get
RUN dart compile exe bin/MillionGame.dart -o bin/main

FROM subfuzion/dart:slim
COPY --from=build /app/merna_bot/bin/main /app/bin/main
# تشغيل الملف
CMD ["/app/bin/main"]
