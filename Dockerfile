FROM dart:stable
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart compile exe bin/main.dart -o main
CMD "./main"
