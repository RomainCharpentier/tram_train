#!/bin/bash
# Script pour lancer l'app avec les données mock
flutter run -d web-server --web-port=8080 --dart-define=USE_MOCK_DATA=true

