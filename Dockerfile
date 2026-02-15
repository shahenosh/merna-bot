FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/MillionGame.dart -o bin/main

FROM subfuzion/dart:slim
COPY --from=build /app/bin/main /app/bin/main
CMD ["/app/bin/main"]