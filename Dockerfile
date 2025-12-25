# AOT won't work due to nyxx_commands using mirrors
FROM dart:stable
WORKDIR /app
COPY pubspec.yaml ./
RUN dart pub get
COPY . .
CMD ["dart", "run", "bin/main.dart"]
