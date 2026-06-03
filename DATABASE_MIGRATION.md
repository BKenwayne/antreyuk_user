# Database Migration Summary

## Perubahan Struktur Firebase Realtime Database

Proyek telah diperbarui untuk menyesuaikan dengan struktur database baru yang telah diselaraskan dengan web admin. Berikut adalah perubahan utama:

### 1. **Antrean (Antrian Pasien)**
**Lokasi:** `/antrean/queue_X/`

```
queue_1
├── nomorAntrean: "A-14"
├── poliTujuan: "Poli Umum"
├── namaPasien: "Ratna Sari"
├── noRekamMedis: "P-00981"
├── keluhanAwal: "Sakit Kepala Berat"
├── estimasiMenit: 8
├── status: "menunggu" | "dipanggil" | "selesai"
└── waktuDaftar: 1780362000000 (timestamp)
```

**Perubahan Kode:**
- `firebase_service.dart`: Menambahkan method `createNewQueue()` untuk membuat entry antrean baru
- `ambil_antrean_page.dart`: `_submitAntrean()` sekarang menggunakan `createNewQueue()` dengan struktur baru

### 2. **Janji Temu (Appointment)**
**Lokasi:** `/antrean_janjitemu/apt_X/`

```
apt_1
├── namaPasien: "Budi Santoso"
├── nikOrKeluhan: "NIK: 32750...4401"
├── poli: "Poli Umum"
├── tanggal: 1780333200000 (timestamp)
├── waktu: "08:30"
├── isEmergency: false
├── estimasiMenit: 30
└── status: "menunggu" | "terkonfirmasi" | "selesai"
```

**Perubahan Kode:**
- `firebase_service.dart`: Menambahkan method `createAppointment()` untuk membuat entry janji temu baru
- `janji_temu_page.dart`: `_submitAppointment()` sekarang menggunakan `createAppointment()` dengan struktur baru

### 3. **Dokter**
**Lokasi:** `/dokter/doc_X/`

```
doc_1
├── name: "dr. Bambang S."
├── poli: "Poli Umum"
├── isActive: true
└── avatarUrl: ""
```

**Perubahan Kode:**
- `firebase_service.dart`: Menambahkan method `getDoctorsByPoli()` untuk mengambil dokter berdasarkan poliklinik
- `janji_temu_page.dart`: UI diperbarui untuk menampilkan dokter dari Realtime Database, bukan dari Firestore

---

## File yang Diubah

### 1. `lib/services/firebase_service.dart`
- ✅ Menambahkan `createNewQueue()` - Membuat antrean baru dengan struktur baru
- ✅ Menambahkan `getDoctorsByPoli()` - Mengambil dokter dari path `/dokter/` berdasarkan nama poli
- ✅ Menambahkan `createAppointment()` - Membuat janji temu dengan struktur baru

### 2. `lib/ambil_antrean_page.dart`
- ✅ Update `_submitAntrean()` untuk menggunakan `createNewQueue()` 
- ✅ Menghapus unused import `firebase_database`

### 3. `lib/janji_temu_page.dart`
- ✅ Update `_submitAppointment()` untuk menggunakan `createAppointment()`
- ✅ Update UI untuk mengambil dokter dari Realtime Database menggunakan `getDoctorsByPoli()`
- ✅ Menambahkan widget `_buildDoctorCard()` untuk menampilkan dokter yang tersedia
- ✅ Menambahkan pilihan waktu secara terpisah dari pilihan dokter

---

## Flow Data

### Ambil Antrean
```
User isi form
    ↓
_submitAntrean()
    ↓
createNewQueue() → Simpan ke /antrean/queue_X/
    ↓
setUserActiveQueue() → Simpan status tracking user
    ↓
Navigate ke HomePage
```

### Buat Janji Temu
```
User pilih poli, dokter, tanggal, waktu
    ↓
getDoctorsByPoli() → Ambil dokter dari /dokter/ yang sesuai poli
    ↓
_submitAppointment() 
    ↓
createAppointment() → Simpan ke /antrean_janjitemu/apt_X/
    ↓
Navigate ke HomePage
```

---

## Testing

Untuk memastikan integrasi berjalan dengan baik:

1. **Test Ambil Antrean:**
   - Buka halaman "Ambil Antrean"
   - Isi form dengan data lengkap
   - Klik "Ambil Antrean Sekarang"
   - Periksa apakah data tersimpan di `/antrean/queue_X/` di Firebase Realtime Database

2. **Test Janji Temu:**
   - Buka halaman "Janji Temu"
   - Pilih poliklinik
   - Verifikasi dokter yang ditampilkan sesuai dengan poli yang dipilih
   - Pilih dokter, tanggal, dan waktu
   - Klik "Buat Janji Temu"
   - Periksa apakah data tersimpan di `/antrean_janjitemu/apt_X/` di Firebase Realtime Database

---

## Notes
- Timestamp disimpan dalam format seconds (bukan milliseconds) untuk konsistensi dengan admin panel
- Status field menggunakan lowercase untuk consistency
- Avatar URL dokter disimpan sebagai field kosong string default, dapat diisi dari admin panel
