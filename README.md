# 📊 Smart Expense Tracker

A modern, responsive expense tracking mobile application built with **Flutter** and **Dart**. The app focuses on clean local state management, dynamic analytical calculations, and conditional UI updates without external database overhead.

---

## ✨ Features

- **Expense Management**: Add, track, and delete expenses with details including title, category, date, and amount.
- **Dynamic Analytical Dashboard**:
  - Total expenditure calculation.
  - Today's spending tracker.
  - Highest, lowest, and average expense calculations.
  - Category-wise breakdown (*Food, Transport, Shopping, Other*).
- **Budget Control & Health Indicator**:
  - Configurable monthly budget.
  - Dynamic spending status indicators:
    - 🟢 **Safe**: Spend < 50%
    - 🟡 **Moderate**: Spend 50% – 80%
    - 🟠 **Warning**: Spend 80% – 100%
    - 🔴 **Over Budget**: Spend > 100% (with alert dialog notification)
- **Advanced Filtering**:
  - Filter by timeframe: *Today*, *This week*, *This month*.
  - Filter by specific categories.
  - Summary metrics update dynamically based on the applied filter.
- **Robust Validation**:
  - Prevents negative or zero-value transactions.
  - Validates budget figures against negative values.
  - Gracefully handles empty states.

---

## 🛠️ Tech Stack & Widgets

- **Framework**: Flutter (Material 3)
- **Language**: Dart
- **Core Widgets Used**:
  - `Scaffold`, `AppBar`, `Card`
  - `ListView.builder` for performant dynamic rendering
  - `DropdownButton` & `DropdownButtonFormField`
  - `showDatePicker`
  - `AlertDialog` & `ModalBottomSheet`

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- VS Code or Android Studio.
- Connected Android/iOS device or desktop emulator.

### Installation

1. **Clone the repository**:
   ```bash
   git clone [https://github.com/](https://github.com/)<YOUR-USERNAME>/smart_expense_tracker.git
   cd smart_expense_tracker
