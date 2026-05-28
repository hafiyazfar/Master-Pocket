# Master Pocket

Master Pocket is a simple Flutter finance tracker for monitoring personal income, expenses, monthly budgets, and category-wise spending. It is designed to help you quickly log transactions and see how your money is being used at a glance.

## Features

- Add income and expense transactions with title, amount, category, and date
- Track monthly spending against a custom budget
- Review category breakdowns with visual charts
- View recent activity and delete transactions with undo support
- Persist data locally using SQLite on the device

## Tech Stack

- Flutter
- Dart
- Riverpod for state management
- SQLite via sqflite for local data storage
- fl_chart for spending visuals

## Project Structure

- lib/main.dart — app entry point and dashboard UI
- lib/pages/add_transaction_page.dart — form to add new transactions
- lib/providers/ — Riverpod providers for transactions, budget, and category totals
- lib/database/app_db.dart — local SQLite database setup and persistence
- lib/models/transactions.dart — transaction model and types

## Getting Started

1. Install Flutter SDK 3.9.2 or newer.
2. Install dependencies:
   ```sh
   flutter pub get
   ```
3. Run the app:
   ```sh
   flutter run
   ```

## Useful Commands

- Run tests:
  ```sh
  flutter test
  ```
- Analyze the project:
  ```sh
  flutter analyze
  ```

## Notes

This app currently stores data locally on the device, so your transactions and budget settings remain available even after reopening the app.

