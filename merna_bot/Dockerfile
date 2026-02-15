FROM dart:stable AS build
WORKDIR /app
# بما أننا داخل merna_bot، انسخ كل شيء هنا
COPY . .
RUN dart pub get
RUN dart compile exe bin/MillionGame.dart -o bin/main

FROM subfuzion/dart:slim
COPY --from=build /app/bin/main /app/bin/main
CMD ["/app/bin/main"]
