# ♠️ Spades Scorer

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter" alt="Flutter Version">
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart" alt="Dart Version">
  <img src="https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20Desktop-lightgrey" alt="Platforms">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

A beautiful, modern Flutter application for keeping score in the card game **Spades**. Built as a learning project to demonstrate Flutter/Dart best practices, architecture patterns, and modern UI design.

🌐 **Live Demo**: [spades.pvleeuwen.com](https://spades.pvleeuwen.com/)

---

## 📱 Screenshots

| Home Screen | Active Game | Game History |
|:-----------:|:-----------:|:------------:|
| Modern landing page with quick actions | Score hands with intuitive controls | View and manage past games |

---

## ✨ Features

### Game Management
- 🎮 **Create Games** - Set up new games with custom player names
- 📂 **Game History** - View, continue, or delete past games
- 💾 **Auto-Save** - All game data persists locally using Hive

### Scoring
- 📝 **Individual Player Bids** - Track each player's bid separately
- 🎯 **Nil Bid Support** - Toggle nil status with visual feedback
- 📊 **Automatic Calculations** - Real-time score computation
- 🎒 **Bag Tracking** - Automatic bag penalty calculation at 10 bags
- 🏆 **Win Detection** - Visual indicators when a team wins

### User Experience
- 🎨 **Modern Dark Theme** - Sleek, eye-friendly design
- 📱 **Cupertino Design** - iOS-style UI that works everywhere
- ⚡ **Fast & Responsive** - Optimized for smooth interactions
- 🔄 **Cross-Platform** - Runs on iOS, Android, Web, and Desktop

---

## 🎓 Learning Flutter/Dart with This Project

This codebase is extensively commented to serve as a learning resource. Each file demonstrates specific Flutter and Dart concepts:

### Architecture & Patterns

| File | Concepts Demonstrated |
|------|----------------------|
| `lib/main.dart` | App entry point, CupertinoApp, GoRouter setup, theme configuration |
| `lib/state.dart` | Riverpod state management, StateNotifier, Provider pattern |
| `lib/models.dart` | Immutable data models, `@immutable`, `copyWith` pattern |
| `lib/game_repository.dart` | Repository pattern, Singleton, JSON serialization, Hive persistence |
| `lib/scoring.dart` | Pure functions, business logic separation |

### Widget Patterns

| File | Concepts Demonstrated |
|------|----------------------|
| `lib/screens/home_screen.dart` | ConsumerWidget, dialogs, async navigation |
| `lib/screens/play_screen.dart` | ConsumerStatefulWidget, complex state, widget composition |
| `lib/screens/games_screen.dart` | ListView.separated, empty states, confirmation dialogs |
| `lib/widget/numeric_stepper.dart` | Custom input widgets, controlled components |
| `lib/widget/readonly_field.dart` | Widget composition, theming |

### Key Dart Concepts Covered

- **Null Safety** - `?`, `!`, `late`, `required`
- **Collections** - `List.generate`, `.map()`, `.where()`, spread operator
- **Async/Await** - `Future`, async methods, `mounted` checks
- **Classes** - Constructors, `const`, `factory`, private members
- **Functional** - First-class functions, closures, callbacks

---

## 🏗️ Project Structure

```
lib/
├── main.dart              # App entry point & configuration
├── colors.dart            # Color palette & theme constants
├── models.dart            # Immutable domain models
├── scoring.dart           # Score calculation logic
├── state.dart             # Riverpod state management
├── game_repository.dart   # Data persistence layer
├── screens/
│   ├── home_screen.dart   # Landing page
│   ├── games_screen.dart  # Game history list
│   └── play_screen.dart   # Active game scoring
└── widget/
    ├── numeric_stepper.dart   # Custom number input
    └── readonly_field.dart    # Display-only field
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.38+)
- Dart SDK (3.10+)
- An IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/PimVanLeeuwen/spades_flutter_app.git
   cd spades_flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # Run on default device
   flutter run

   # Run on specific platform
   flutter run -d chrome      # Web
   flutter run -d ios         # iOS Simulator
   flutter run -d macos       # macOS Desktop
   ```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## 🎴 Spades Rules (Quick Reference)

For those unfamiliar with Spades, here's how scoring works:

| Scenario | Points |
|----------|--------|
| Make your bid | +10 × tricks bid |
| Fail your bid | -10 × tricks bid |
| Overtricks (bags) | +1 each |
| Every 10 bags | -100 penalty |
| Nil bid made | +100 |
| Nil bid failed | -100 |

**Win Condition**: First team to reach 500 points wins (must be ahead of opponent).

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Riverpod** | State management |
| **GoRouter** | Declarative routing |
| **Hive** | Local NoSQL database |
| **UUID** | Unique identifier generation |

---

## 📚 Learning Resources

If you're using this project to learn Flutter, here are helpful resources:

- 📖 [Flutter Documentation](https://docs.flutter.dev/)
- 🎥 [Flutter YouTube Channel](https://www.youtube.com/c/flutterdev)
- 📦 [Riverpod Documentation](https://riverpod.dev/)
- 🗺️ [GoRouter Documentation](https://pub.dev/packages/go_router)
- 💾 [Hive Documentation](https://docs.hivedb.dev/)

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

## 👨‍💻 Author

**Pim van Leeuwen**

