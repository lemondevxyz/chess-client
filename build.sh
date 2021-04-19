# clean previous build
flutter clean
# build using production file
flutter build web --release -t lib/main.prod.dart --tree-shake-icons
