# Spades

A Flutter project to learn Flutter and to keep track of the score in the game Spades that we do a lot. 

The app can be found on: https://spades.pvleeuwen.com/

## Features

*   **Game Management**: Create and manage multiple Spades games.
*   **Hand-by-Hand Scoring**: Enter scores for each hand as you play.
*   **Individual Player Bids**: Set bids for each of the four players.
*   **Nil Bid Tracking**: Easily toggle "nil" bids for any player.
*   **Automatic Calculations**: Automatically calculates team bids, hands won, and cumulative scores.
*   **Bag Tracking**: Keeps a running total of bags for each team and handles "bagging out".
*   **Clean UI**: A straightforward, Cupertino-style interface built for quick and easy input during a game.

## Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   An IDE like Android Studio or VS Code with the Flutter plugin.

### Installation

1.  Clone the repository:
    ```sh
    git clone https://github.com/PimVanLeeuwen/spades_flutter_app.git
    ```
2.  Navigate to the project directory:
    ```sh
    cd spades_flutter_app
    ```
3.  Install the required dependencies:
    ```sh
    flutter pub get
    ```
4.  Run the app on a simulator or physical device:
    ```sh
    flutter run
    ```

## Project Structure

The project is organized into a standard Flutter application structure:

*   `lib/main.dart`: The entry point of the application.
*   `lib/models.dart`: Contains the data models for `Game`, `Team`, and `Hand`.
*   `lib/scoring.dart`: Implements the core logic for calculating scores and bags according to Spades rules.
*   `lib/screens/`: Contains the UI for the different screens of the app.
    *   `home_screen.dart`: The main screen that lists all saved games.
    *   `games_screen.dart`: The screen for creating a new game and defining teams.
    *   `play_screen.dart`: The primary interface for scoring a hand during a game.
*   `lib/widget/`: Contains reusable custom widgets, such as the `NumericStepper` used for input.
