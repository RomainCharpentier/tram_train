# Train'Qil 🚂

**Tranquille & Ponctuel** - Application de gestion des trajets de train

## 🎯 Fonctionnalités

### ✨ Interface utilisateur
- **Logo personnalisé** avec votre image
- **Thème clair/sombre** avec toggle
- **Design moderne** et intuitif
- **Icônes visibles** sur fond bleu

### 🚂 Gestion des trajets
- **Ajout de trajets** avec sélection multiple des jours
- **Modification de trajets** existants
- **Recherche intelligente** de gares connectées
- **Tableau de bord** avec trajets actifs
- **Actualisation automatique** après ajout

### 🔔 Notifications
- **Notifications locales** pour retards et annulations
- **Rappels de départ** configurables
- **Gestion des permissions** automatique

## 🏗️ Architecture

### 📁 Structure du projet
```
lib/
├── domain/           # Logique métier
│   ├── models/       # Modèles de données
│   └── services/     # Services métier
├── infrastructure/   # Couche infrastructure
│   ├── gateways/     # Interfaces externes
│   └── mappers/     # Conversion de données
├── view/            # Interface utilisateur
│   ├── pages/       # Pages de l'application
│   └── widgets/     # Composants réutilisables
└── main.dart       # Point d'entrée
```

### 🔧 Services principaux
- **TripService** : Gestion des trajets
- **ThemeService** : Gestion des thèmes
- **NotificationService** : Notifications locales
- **StationSearchService** : Recherche de gares

## 🚀 Installation

1. **Cloner le projet**
   ```bash
   git clone <repository-url>
   cd tram_train
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configurer l'environnement**
   - Créer un fichier `.env.local` avec vos clés API SNCF

4. **Lancer l'application**
   ```bash
   flutter run -d chrome --web-port=8080
   ```

## 📱 Utilisation

### Ajouter un trajet
1. Cliquer sur le bouton **+** sur la page d'accueil
2. Sélectionner la gare de départ
3. Choisir la gare d'arrivée (liste intelligente)
4. Sélectionner les jours de la semaine
5. Choisir l'heure de départ
6. Sauvegarder

### Gérer les trajets
1. Aller dans **Profil** → **Mes Trajets**
2. Modifier, dupliquer ou supprimer un trajet
3. Activer/désactiver un trajet

### Thème
- Utiliser le bouton **🌙/☀️** dans l'AppBar pour basculer entre thème clair et sombre

## 🛠️ Technologies

- **Flutter** : Framework de développement
- **Dart** : Langage de programmation
- **SharedPreferences** : Stockage local
- **HTTP** : Requêtes API
- **Flutter Local Notifications** : Notifications locales

## 📄 Licence

Ce projet est sous licence MIT.

---

**Train'Qil** - Votre compagnon de voyage tranquille et ponctuel ! 🚂✨