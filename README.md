# TeamGrid 🚀

TeamGrid adalah aplikasi *Enterprise Resource Planning* (ERP) mini yang berfokus spesifik pada Manajemen Sumber Daya Manusia (Resource) terhadap Proyek. Aplikasi ini dirancang untuk memudahkan alokasi dan pemetaan tim ke dalam suatu proyek, dengan fokus pada penugasan saat ini daripada pemantauan ketersediaan (*availability*) atau utilisasi tim dalam jangka panjang.

---

## ✨ Fitur Utama
- **Manajemen Proyek:** Buat, perbarui, dan pantau status proyek yang sedang berjalan.
- **Alokasi SDM:** Tambahkan dan tugaskan anggota tim ke dalam proyek spesifik dengan mudah.
- **Manajemen Peran (Role Management):** Tentukan peran setiap anggota tim (misal: *Project Manager*, *Developer*, *UI/UX Designer*) di dalam proyek.
- **Dashboard Ringkas:** Tampilan antarmuka yang intuitif untuk melihat ringkasan proyek dan siapa saja yang terlibat di dalamnya.
- **Cross-Platform:** Mendukung penggunaan di Android, iOS, dan Web.

---

## 🛠️ Teknologi yang Digunakan
Proyek ini dibangun menggunakan teknologi berikut:
- **[Flutter](https://flutter.dev/):** Framework UI utama untuk membangun aplikasi multi-platform.
- **[Dart](https://dart.dev/):** Bahasa pemrograman yang digunakan oleh Flutter.
- **[Firebase](https://firebase.google.com/):** Digunakan untuk layanan *backend* (Autentikasi, Database, dll).

---

## 📋 Prasyarat Instalasi
Sebelum menjalankan proyek ini di mesin lokal, pastikan Anda telah menginstal beberapa perangkat lunak berikut:
1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi terbaru direkomendasikan).
2. [Dart SDK](https://dart.dev/get-dart) (biasanya sudah sepaket dengan Flutter).
3. IDE seperti [Visual Studio Code](https://code.visualstudio.com/) atau [Android Studio](https://developer.android.com/studio).
4. [Firebase CLI](https://firebase.google.com/docs/cli) (jika ingin mengonfigurasi layanan Firebase secara lokal).

---

## ⚙️ Cara Instalasi & Menjalankan Proyek

1. **Clone repositori ini:**
   ```bash
   git clone [https://github.com/BerlianPurliN/TeamGrid.git](https://github.com/BerlianPurliN/TeamGrid.git)

2. **Masuk ke direktori proyek:**
   ```bash
   cd TeamGrid

3. **Unduh semua dependensi:**
   ```bash
   flutter pub get

4. **Jalankan proyek:**
   ```bash
   flutter run

---

## 📂 Susunan Proyek
TeamGrid/
├── android/          # File konfigurasi spesifik Android  

├── ios/              # File konfigurasi spesifik iOS  

├── web/              # File konfigurasi spesifik Web  

├── lib/              # Kode sumber utama aplikasi (Dart)  

│   ├── main.dart     # Entry point aplikasi  
│   └── ...           # (Folder UI, model, layanan, dsb.)
├── assets/           # Folder untuk gambar, ikon, dan font
├── pubspec.yaml      # File konfigurasi package/dependencies Flutter
└── firebase.json     # File konfigurasi Firebase

---

## 💡 Contoh Penggunaan

1. Login/Registrasi: Masuk menggunakan kredensial yang telah didaftarkan.
2. Membuat Proyek Baru: Masuk ke menu "Projects", klik tombol tambah (+), dan isi detail proyek.
3. Menugaskan Tim: Buka proyek yang baru dibuat, pilih "Add Member", lalu pilih anggota tim dari daftar SDM yang tersedia beserta role mereka di proyek tersebut.
4. Melihat Ringkasan: Buka Dashboard untuk melihat daftar proyek aktif dan siapa saja yang sedang ditugaskan di masing-masing proyek.
