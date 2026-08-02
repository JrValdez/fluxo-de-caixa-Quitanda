# ---- build (Flutter Web) ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml ./
RUN flutter pub get
COPY . .
# API na mesma origem (o nginx faz proxy de /api) e assets sob /quitanda/.
# API_URL=/quitanda -> o cliente Dio usa "/quitanda/api" como base.
RUN flutter build web --release --dart-define=API_URL=/quitanda --base-href=/quitanda/

# ---- runtime (nginx) ----
FROM nginx:alpine AS final
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
