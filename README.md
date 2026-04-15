<div align="center">

# 🍼 TinySteps — DayCare App

**Smart Early Childhood Care Management System**  

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)](https://supabase.com)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![GitHub](https://img.shields.io/badge/GitHub-Workflow-181717?logo=github)](https://github.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> Building a digital bridge between parents, educators, and daycare administrators — one scan at a time.

</div>

---

## 📖 Table of Contents
- [About the Project](#-about-the-project)
- [Key Features](#-key-features-mvp)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Contributing Guidelines](#-contributing-guidelines)
- [Future Phases](#-future-phases)
- [License](#-license)

---

## 🌟 About the Project

**TinySteps** is a mobile-first daycare management app targeting early childhood care for children ages **0-5 years**. It empowers parents, teachers, and administrators with digital tools to streamline daily operations, ensure child safety, and improve communication.

### 🎯 Target Users
| Role | App Capabilities |
|------|------------------------|
| **Parent** | Register child profiles, view daily attendance, manage personal profile. |
| **Teacher / Staff** | Scan QR codes for seamless child check-in/check-out, monitor daily logs. |
| **Administrator** | Approve staff accounts, monitor real-time attendance, manage classrooms. |

---

## ✅ Key Features (MVP)

### 🔐 Authentication & Role-Based Access
- Secure Email/Password registration with mandatory email verification.
- Intelligent role routing (Parent → Parent Dashboard, Teacher → Teacher Dashboard, Admin → Admin Panel).
- Supabase Auth integration with secure user metadata storage.

### 👶 Child Digital Profiles
- Parents can seamlessly add, edit, and view comprehensive child profiles.
- Track critical information: Name, Date of Birth, Blood Type, Allergies, Emergency Contacts, and Pediatrician details.
- Photo upload functionality via device camera or local gallery.

### 📱 QR Touchless Attendance
- Automatic generation of a unique, secure QR code for each registered child.
- Built-in scanner for teachers to process drop-offs and pick-ups instantly.
- Real-time automated timestamp logging with full historical views for parents.

### 🎛️ Admin Control Panel
- Centralized dashboard to view all registered users.
- Workflow for approving or rejecting staff/teacher account applications.
- Real-time daily attendance summaries and classroom assignment management.

---

## 🛠️ Tech Stack

| Category | Technology | Purpose |
|----------|------------|---------|
| **Frontend** | Flutter 3.x (Dart) | Cross-platform mobile application (Android & iOS). |
| **State Management**| Provider / Riverpod | Efficient, scalable state management across the app. |
| **Backend & DB** | Supabase (PostgreSQL)| Managed relational database with Row Level Security (RLS). |
| **Storage** | Supabase Storage | Secure hosting for child photos and required documents. |
| **QR Library** | `qr_flutter` + `mobile_scanner`| High-performance QR generation and camera scanning. |
| **Routing** | Go Router | Declarative routing with secure, role-based navigation guards. |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK 3.x](https://flutter.dev/docs/get-started/install)
- Dart 3.x (Included with Flutter)
- IDE: Android Studio, VS Code, or IntelliJ
- A [Supabase](https://supabase.com/) account (for backend environment setup)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/tinysteps-daycare.git
   cd tinysteps-daycare
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   ```bash
   cp ..env.example ..env
   ```
   *Open `.env` and add your Supabase credentials:*
   ```env
   SUPABASE_URL=https://your-project-ref.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```
   > ⚠️ **Note:** Ensure `.env` is listed in your `.gitignore` to prevent leaking secrets.

4. **Run the application**
   ```bash
   flutter run
   ```

---

## 🤝 Contributing Guidelines

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1. **Fork the Project**
   Click the `Fork` button at the top right of the repository page.

2. **Clone your Fork**
   ```bash
   git clone https://github.com/your-username/tinysteps-daycare.git
   ```

3. **Create your Feature Branch**
   ```bash
   git checkout -b feat/AmazingFeature
   ```

4. **Commit your Changes** (Please follow conventional commit messages)
   ```bash
   git commit -m "feat: add some amazing feature"
   ```

5. **Push to the Branch**
   ```bash
   git push origin feat/AmazingFeature
   ```

6. **Open a Pull Request**
   Navigate to the original repository and click `New Pull Request` to submit your code for review.

> **Note:** Never hardcode credentials. Always utilize the `.env` file for API keys and endpoints. Ensure your code passes all linting checks before submitting a PR.

---

## 🔮 Future Phases 

The following features are slated for upcoming releases:
- 📹 CCTV / Live secure video streaming integrations.
- 👆 Biometric attendance hardware support.
- 🌡️ IoT environmental monitoring (Classroom AQI, temperature checks).
- 🥗 AI-powered nutritional recommendations for provided meals.
- 🔔 Push notifications and emergency broadcast alerts.

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.

---
<div align="center">
<b>Built with ❤️ by the TinySteps Development Team</b>
</div>
