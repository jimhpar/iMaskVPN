# 🛡️ iMask VPN — Ultra-Fast, Secure Hybrid VPN & Admin Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Windows%20%7C%20Android%20%7C%20Web-blue)](#)
[![Protocols](https://img.shields.io/badge/Protocols-WireGuard%20%7C%20OpenVPN-orange)](#)
[![License](https://img.shields.io/badge/License-Proprietary-red)](#)

**iMask VPN** is a modern, high-performance, cross-platform VPN client designed for Windows, Android, and Web. It features an advanced **Hybrid VPN Architecture** combining private high-speed WireGuard cloud infrastructure with global live volunteer relay nodes (VPN Gate).

---

## 🌟 Key Features

* **⚡ Hybrid VPN Architecture:**
  * **Dedicated VIP / Ultra Node:** Powered by **WireGuard** on Oracle Cloud Infrastructure (10 Gbps, 24ms ultra-low latency, zero logging).
  * **Global Free Relay Tier:** Dynamically integrates with live **VPN Gate** public relays (Japan, USA, Korea, Thailand, etc.) using OpenVPN over Wintun for authentic regional IP masking.
  * **Smart Failover:** Automatically reroutes through the dedicated gateway if a volunteer relay drops, preventing IP leaks.

* **🎨 High-Contrast Adaptive UI:**
  * **Pure White & Black Mode (Light):** Sharp contrast, delicate shadows, no washed-out blues.
  * **Cyber Mode (Dark):** Deep-space dark styling with glowing telemetry indicators.
  * **Live Flight & Radar Map:** Visual flight trajectory and pulsating radar on connection.
  * **72+ Official Country Flags:** Scalable vector-accurate flag representations.

* **👥 Membership & Commercial Billing Plans:**
  * **Free:** 1-hour continuous session, 5 hours/week limit.
  * **Pro (99 BDT):** 3-hour continuous session, 15 hours/week limit.
  * **Ultra VIP (499 BDT):** Unlimited continuous connections, unlimited bandwidth, dedicated VIP nodes.

* **⚙️ Built-In SuperAdmin Hub:**
  * **User Management:** View, edit, add, delete users, and assign subscription tiers.
  * **Plan Upgrade Review:** Approve or reject user plan upgrade requests in real time.
  * **Server Telemetry:** Real-time ping, status, and network metrics.

---

## 📁 Project Structure

```
iMask/
├── lib/
│   ├── models/            # Data models (VpnServer, UserProfile, PlanRequest)
│   ├── screens/           # UI Screens (Home, Auth, Profile, Admin Hub, Review Requests)
│   ├── services/          # Core Services (VpnService, VpnGateService, AuthService, ThemeService)
│   └── widgets/           # Custom Widgets (WorldMapRadarWidget, CountryFlagWidget)
├── assets/
│   ├── flags/             # 72 official country flag icons
│   ├── icon/              # High-resolution iMask app icon
│   └── map/               # Vector world map asset
├── windows/               # Windows C++ runner and manifests
├── android/               # Android Gradle configuration
├── tools/                 # Tunnel engine installers and drivers (WireGuard, OpenVPN, Wintun)
├── windows_installer.iss  # Inno Setup 6 compilation script
└── pubspec.yaml           # Flutter dependencies & asset manifests
```

---

## 🚀 Building & Running

### Prerequisites
* Flutter SDK (3.x or higher)
* Visual Studio 2022 (with Desktop development with C++) for Windows
* Android SDK (API 34+) for Android builds
* Inno Setup 6 (for Windows Setup installer packaging)

### Windows Desktop
```bash
# Debug run
flutter run -d windows

# Production release build
flutter build windows --release

# Compile Setup Installer (.exe)
"C:\Users\Zim\AppData\Local\Programs\Inno Setup 6\ISCC.exe" windows_installer.iss
```

### Android APK
```bash
# Build optimized release APK (split-per-ABI)
flutter build apk --release --split-per-abi
```

### Web
```bash
# Build release web
flutter build web --release

# Serve locally
python -m http.server 3000 --directory "build/web"
```

---

## 🔒 Security & Privacy
* Real kernel-level tunneling using **WireGuard Windows Service** and **Wintun**.
* Complete DNS leak protection via Cloudflare DNS (`1.1.1.1`).
* WebRTC and IPv6 leak suppression.

---

## 👤 Author
Developed with ❤️ by **Jim Hpar** ([@jimhpar](https://github.com/jimhpar))
