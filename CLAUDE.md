# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building
```bash
# Build the project
xcodebuild -project FoodStocker.xcodeproj -scheme FoodStocker -configuration Debug build

# Build for release
xcodebuild -project FoodStocker.xcodeproj -scheme FoodStocker -configuration Release build
```

### Testing
```bash
# Run unit tests
xcodebuild test -project FoodStocker.xcodeproj -scheme FoodStocker -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests only
xcodebuild test -project FoodStocker.xcodeproj -scheme FoodStocker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:FoodStockerUITests

# Run unit tests only
xcodebuild test -project FoodStocker.xcodeproj -scheme FoodStocker -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:FoodStockerTests
```

### Running
Open `FoodStocker.xcodeproj` in Xcode and run the project using Cmd+R, or use:
```bash
xcodebuild -project FoodStocker.xcodeproj -scheme FoodStocker -destination 'platform=iOS Simulator,name=iPhone 15' run
```

## Architecture Overview

### Core Data Stack
- **PersistenceController**: Manages the Core Data stack (local storage only)
- **Data Model**: `FoodStocker.xcdatamodeld` contains Product entity with food inventory attributes
- **Local Storage**: Uses NSPersistentContainer for local data persistence

### App Structure
- **FoodStockerApp.swift**: Main app entry point, sets up persistence context
- **ContentView.swift**: Primary UI with NavigationView displaying Core Data items
- **Item Management**: Basic CRUD operations for timestamped items

### Key Patterns
- Uses `@FetchRequest` for automatic Core Data updates in SwiftUI
- Environment-based dependency injection for managed object context
- Standard SwiftUI navigation patterns with NavigationView/NavigationLink
- Error handling with fatalError for development (needs production-ready error handling)

### Project Structure
```
FoodStocker/
├── FoodStocker/           # Main app target
│   ├── Assets.xcassets/   # App icons and colors
│   ├── ContentView.swift  # Main UI
│   ├── FoodStockerApp.swift # App entry point
│   ├── Persistence.swift  # Core Data stack
│   └── FoodStocker.xcdatamodeld/ # Data model
├── FoodStockerTests/      # Unit tests
└── FoodStockerUITests/    # UI tests
```

### Development Notes
- Application de gestion de stocks alimentaires complète avec données de test automatiques
- Interface utilisateur en français avec TabView (Stocks, Alertes, Ajouter)
- Scanner de codes-barres intégré avec VisionKit (iOS 16+)
- Notifications locales pour les alertes d'expiration
- Stockage local uniquement (compatible avec compte développeur gratuit)
- Données de test créées automatiquement au premier lancement

### Fonctionnalités implémentées
- CRUD complet pour les produits alimentaires
- Système d'alertes avec codes couleur (vert/orange/rouge)
- Recherche et tri dans la liste des produits
- Scanner de codes-barres pour les numéros de lot
- Notifications 24h avant expiration
- Interface adaptée aux différents emplacements (frigo, congélateur, etc.)

### Compatibilité
- Fonctionne avec un compte développeur Apple gratuit
- Pas de synchronisation CloudKit (stockage local uniquement)
- Compatible iOS 15.0+