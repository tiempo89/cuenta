#!/bin/bash

# Clonar la versión estable del SDK de Flutter
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable
# Añadir Flutter al PATH para esta sesión de build
export PATH="$PATH:`pwd`/flutter/bin"
# Habilitar la compilación web y obtener dependencias
flutter config --enable-web
flutter pub get