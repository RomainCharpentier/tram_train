# Tests d'intégration API SNCF

Ce dossier contient des tests d'intégration pour vérifier que les appels API SNCF fonctionnent correctement.

## 📁 Fichiers disponibles

### Tests Flutter
- **`sncf_api_test.dart`** : Tests d'intégration Flutter avec l'API SNCF réelle
  - Tests automatiques avec `flutter test`
  - Nécessite une clé API valide dans `.env.local`
  - Couvre tous les endpoints du `SncfGateway`

### Tests manuels (curl)
- **`curl_tests.sh`** : Script bash pour Linux/Mac
- **`curl_tests.ps1`** : Script PowerShell pour Windows

## 🚀 Comment utiliser

### 1. Tests Flutter automatiques

```bash
# Lancer tous les tests d'intégration
flutter test test/integration/

# Lancer seulement les tests d'intégration SNCF
flutter test test/integration/sncf_api_test.dart
```

**Prérequis :**
- Clé API SNCF valide dans `.env.local`
- Connexion internet

### 2. Tests manuels avec curl

#### Linux/Mac
```bash
# Rendre le script exécutable
chmod +x test/integration/curl_tests.sh

# Éditer le script pour ajouter votre clé API
nano test/integration/curl_tests.sh
# Remplacer YOUR_API_KEY par votre vraie clé

# Lancer les tests
./test/integration/curl_tests.sh
```

#### Windows PowerShell
```powershell
# Éditer le script pour ajouter votre clé API
notepad test/integration/curl_tests.ps1
# Remplacer YOUR_API_KEY par votre vraie clé

# Lancer les tests
.\test\integration\curl_tests.ps1
```

## 🔧 Configuration

### Clé API SNCF
1. Obtenez une clé API sur [https://www.sncf.com/fr/partenaires/partenaires-technologiques](https://www.sncf.com/fr/partenaires/partenaires-technologiques)
2. Ajoutez-la dans `.env.local` :
   ```
   API_KEY=votre_cle_api_ici
   ```

### Installation des dépendances
```bash
# Pour les tests curl avec jq (Linux/Mac)
sudo apt install jq  # Ubuntu/Debian
brew install jq      # macOS
```

## 📋 Endpoints testés

### 1. Recherche de gares
- **Endpoint** : `/places?q={query}&type[]=stop_area`
- **Tests** : Recherche par nom (Nantes, Paris)
- **Vérifications** : Retourne des gares valides

### 2. Départs d'une gare
- **Endpoint** : `/stop_areas/stop_area:{id}/departures`
- **Tests** : Départs actuels et à horaire spécifique
- **Vérifications** : Retourne des trains avec horaires

### 3. Horaires de route
- **Endpoint** : `/stop_areas/stop_area:{id}/route_schedules`
- **Tests** : Tous les trains passant par une gare
- **Vérifications** : Trains dans les deux sens

### 4. Trajets entre gares
- **Endpoint** : `/journeys?from=stop_area:{from}&to=stop_area:{to}`
- **Tests** : Trajets directs, avec horaire de départ/arrivée
- **Vérifications** : Itinéraires valides avec durées

### 5. Informations de gare
- **Endpoint** : `/stop_areas/stop_area:{id}/stop_schedules`
- **Tests** : Détails d'une gare
- **Vérifications** : Informations réseau et mode

### 6. Perturbations
- **Endpoint** : `/disruptions`
- **Tests** : Perturbations actuelles
- **Vérifications** : Messages et niveaux d'impact

## 🐛 Gestion d'erreurs

Les tests vérifient :
- **Erreurs 401** : Clé API invalide
- **Erreurs 404** : Gare inexistante
- **Erreurs réseau** : Connexion internet
- **Rate limiting** : Limitation de débit API

## 📊 Exemples de sortie

### Test de recherche de gares
```json
{
  "places": [
    {
      "id": "stop_area:SNCF:87590349",
      "name": "Nantes",
      "label": "Nantes (Nantes)"
    }
  ]
}
```

### Test de départs
```json
{
  "departures": [
    {
      "display_informations": {
        "direction": "Paris Montparnasse",
        "headsign": "Paris Montparnasse"
      },
      "stop_date_time": {
        "departure_date_time": "20250125T143000"
      }
    }
  ]
}
```

## 🔍 Debugging

### Problèmes courants
1. **Erreur 401** : Vérifiez votre clé API
2. **Erreur 404** : Vérifiez les IDs de gares
3. **Timeout** : Vérifiez votre connexion internet
4. **Rate limiting** : Attendez avant de relancer

### Logs détaillés
Les tests Flutter affichent des logs détaillés :
```
Found 5 departures from Nantes:
  - Paris Montparnasse at 2025-01-25 14:30:00.000 (onTime)
  - Rennes at 2025-01-25 15:00:00.000 (delayed)
```

## 📚 Documentation API

- **Documentation SNCF** : [https://www.sncf.com/fr/partenaires/partenaires-technologiques](https://www.sncf.com/fr/partenaires/partenaires-technologiques)
- **Endpoints** : [https://api.sncf.com/v1/coverage/sncf/](https://api.sncf.com/v1/coverage/sncf/)
- **Authentification** : Basic Auth avec clé API
