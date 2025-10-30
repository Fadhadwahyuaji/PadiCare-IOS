# 🌾 Klasifikasi Penyakit Padi

Aplikasi mobile berbasis Flutter untuk deteksi dan klasifikasi penyakit pada tanaman padi menggunakan teknologi deep learning dan AI.

## 📱 Tentang Aplikasi

Aplikasi ini merupakan sistem diagnosis penyakit tanaman padi yang menggunakan teknologi computer vision dan artificial intelligence untuk mengidentifikasi berbagai jenis penyakit berdasarkan foto daun padi. Aplikasi ini dilengkapi dengan fitur konsultasi AI untuk memberikan saran pengobatan dan perawatan.

### ✨ Fitur Utama

- **🔬 Deteksi Penyakit Real-time**: Upload foto daun padi dan dapatkan hasil diagnosis instan
- **🎯 Akurasi Tinggi**: Menggunakan model deep learning dengan confidence score
- **💬 Konsultasi AI**: Chat dengan AI ahli untuk mendapatkan saran pengobatan
- **📊 Top 3 Predictions**: Melihat 3 kemungkinan diagnosis teratas
- **📝 Riwayat Diagnosis**: Simpan dan akses kembali hasil diagnosis sebelumnya
- **🔄 Mode Offline**: Deteksi status server dan handling error yang baik
- **📱 UI Modern**: Interface yang user-friendly dan responsif

## 🏗️ Arsitektur & State Management

### State Management

- **Flutter Modular**: Digunakan untuk dependency injection dan routing modular
- **Stateful Widget**: State management lokal untuk UI components
- **Controller Pattern**: Pemisahan business logic dengan presentation layer

### Arsitektur Project

```
lib/
├── app.dart                    # App configuration & theming
├── main.dart                   # Entry point aplikasi
└── modules/
    └── disesase/
        ├── disease_modul.dart  # Module configuration
        ├── logic/
        │   ├── controllers/    # Business logic controllers
        │   ├── models/         # Data models
        │   └── services/       # API & external services
        └── presentation/       # UI screens & widgets
```

## 📦 Dependencies & Packages

### Core Dependencies

```yaml
# Framework
flutter: sdk
cupertino_icons: ^1.0.5

# State Management & Architecture
flutter_modular: ^5.0.3 # Dependency injection & modular routing

# Network & API
http: ^1.1.0 # HTTP client
http_parser: ^4.0.2 # HTTP parsing utilities

# Media & File Handling
image_picker: ^1.0.4 # Camera & gallery access

# Device & System Info
connectivity_plus: ^5.0.0 # Network connectivity status
device_info_plus: ^9.0.3 # Device information
shared_preferences: ^2.2.1 # Local storage

# Utilities
uuid: ^4.0.0 # Unique ID generation
intl: ^0.18.1 # Internationalization & date formatting

# App Configuration
flutter_launcher_icons: ^0.14.4 # Custom app icons
```

### Dev Dependencies

```yaml
flutter_test: sdk # Testing framework
flutter_lints: ^5.0.0 # Code quality & linting
```

## 🛠️ Teknologi & Tools

### Frontend (Mobile)

- **Flutter 3.8.1+**: Cross-platform mobile framework
- **Dart**: Programming language
- **Material Design**: UI design system

### Backend Integration

- **REST API**: Komunikasi dengan server AI
- **JSON**: Data exchange format
- **Multipart Form**: Image upload handling

### AI & Machine Learning

- **Deep Learning Model**: Model klasifikasi penyakit padi
- **Computer Vision**: Pengolahan gambar daun padi
- **Expert System**: AI chatbot untuk konsultasi

### Storage & Persistence

- **SharedPreferences**: Local data storage
- **Device ID**: User session management
- **Image Caching**: Optimasi performa gambar

## 🚀 Cara Menjalankan Aplikasi

### Prerequisites

```bash
Flutter SDK >= 3.8.1
Dart SDK >= 3.0.0
Android Studio / VS Code
Android SDK / iOS development tools
```

### Instalasi

1. **Clone repository**

```bash
git clone [repository-url]
cd klasifikasi_penyakit_padi
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Konfigurasi**

- Pastikan server AI sudah running
- Update base URL di `lib/modules/disesase/logic/services/api_service.dart`

4. **Run aplikasi**

```bash
flutter run
```

### Build untuk Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📋 Fitur Detail

### 1. Diagnosis Penyakit

- **Image Input**: Camera atau Gallery
- **Processing**: Upload ke server AI
- **Results**: Nama penyakit, confidence score, saran pengobatan
- **Top Predictions**: 3 kemungkinan diagnosis teratas

### 2. Konsultasi AI Expert

- **Real-time Chat**: Tanya jawab dengan AI
- **Context Aware**: AI memahami context dari diagnosis
- **Expert Advice**: Saran pengobatan dan perawatan
- **Chat History**: Riwayat percakapan tersimpan

### 3. Manajemen Riwayat

- **History List**: Daftar semua diagnosis sebelumnya
- **Filter & Sort**: Filter berdasarkan status kesehatan, urutan tanggal
- **Detail View**: Lihat kembali hasil diagnosis lengkap
- **Delete Function**: Hapus riwayat yang tidak diperlukan

### 4. Network Handling

- **Connectivity Check**: Deteksi status jaringan
- **Server Status**: Monitor status server AI
- **Error Handling**: Pesan error yang informatif
- **Retry Mechanism**: Otomatis retry jika gagal

## 🎨 UI/UX Features

### Design System

- **Material Design 3**: Modern design language
- **Green Theme**: Warna hijau natural untuk tema pertanian
- **Responsive Layout**: Adaptif untuk berbagai ukuran screen
- **Smooth Animations**: Transisi halus antar screen

### User Experience

- **Intuitive Navigation**: Navigasi yang mudah dipahami
- **Visual Feedback**: Loading indicators dan progress bars
- **Error Messages**: Pesan error yang user-friendly
- **Accessibility**: Support untuk accessibility features

## 🔧 Konfigurasi & Environment

### Server Configuration

```dart
// Production
static const String baseUrl = 'https://predict-disease.petanitech.com';

// Development
// static const String baseUrl = 'http://192.168.100.8:7788';
```

### App Configuration

```yaml
name: klasifikasi_penyakit_padi
description: "Deteksi penyakit padi menggunakan deep learning berbasis Flutter"
version: 0.1.0
```

## 📊 Performance & Optimization

### Image Optimization

- **Image Compression**: Otomatis compress sebelum upload
- **Size Validation**: Validasi ukuran file maksimal 10MB
- **Format Support**: JPEG, PNG support
- **Caching**: Image caching untuk performa optimal

### Network Optimization

- **Timeout Handling**: 60 detik timeout untuk request
- **Retry Logic**: Otomatis retry untuk network failures
- **Connection Pooling**: Reuse HTTP connections
- **Error Recovery**: Graceful error handling

## 🧪 Testing & Quality

### Code Quality

- **Flutter Lints**: Enforced code quality standards
- **Error Handling**: Comprehensive error handling
- **Logging**: Detailed logging untuk debugging
- **Type Safety**: Strong typing dengan Dart

### Performance Monitoring

- **Memory Management**: Proper widget lifecycle management
- **Battery Optimization**: Efficient background processing
- **Startup Time**: Optimized app startup
- **Smooth Animations**: 60fps smooth animations

## 🚀 Deployment & Distribution

### Supported Platforms

- **Android**: Android 5.0+ (API level 21+)
- **iOS**: iOS 12.0+
- **Web**: Progressive Web App support
- **Desktop**: Windows, macOS, Linux (experimental)

### Distribution Channels

- **Google Play Store**: Android distribution
- **Apple App Store**: iOS distribution
- **Direct APK**: Sideload installation
- **Enterprise**: Internal distribution

## 🤝 Contributing

Untuk berkontribusi pada project ini:

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

Project ini menggunakan lisensi [Fadhad Wahyu Aji](LICENSE).

## 👥 Team & Contact

**Development Team:**

- Mobile App Developer: Fadhad Wahyu Aji
- AI/ML Engineer: Fadhad Wahyu Aji
- Backend Developer: Fadhad Wahyu Aji

**Contact:**

- Email: [fadhadwahyuaji@gmail.com]
- GitHub: [fadhadwahyuaji]

---

_Dibuat dengan ❤️ menggunakan Flutter untuk membantu petani Indonesia dalam mendeteksi penyakit tanaman padi_
