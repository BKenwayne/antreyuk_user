import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  // Private Constructor
  FirebaseService._internal();

  // Singleton Instance
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;

  // Database Instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  // ==========================================
  // CLOUD FIRESTORE (Slow, Persistent Data)
  // ==========================================

  /// Simpan atau update data profile user di Firestore
  Future<void> saveUserProfile(
    String uid,
    Map<String, dynamic> profileData,
  ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(profileData, SetOptions(merge: true));
  }

  /// Ambil data profile user dari Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(
    String uid,
  ) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Stream data profile user dari Firestore
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Ambil dokumen kesehatan milik user dari Firestore
  Future<QuerySnapshot<Map<String, dynamic>>> getHealthDocuments(
    String uid,
  ) async {
    return await _firestore
        .collection('users')
        .doc(uid)
        .collection('health_documents')
        .get();
  }

  /// Ambil data medical_records berdasarkan patientId (queue key)
  Future<QuerySnapshot<Map<String, dynamic>>> getMedicalRecordsByPatientId(
    String patientId,
  ) async {
    return await _firestore
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .get();
  }

  /// Stream data medical_records berdasarkan patientId (queue key)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMedicalRecordsByPatientId(
    String patientId,
  ) {
    return _firestore
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .snapshots();
  }

  /// Ambil data medical_records berdasarkan nomor rekam medis user
  Future<QuerySnapshot<Map<String, dynamic>>> getMedicalRecordsByNoRekamMedis(
    String noRekamMedis,
  ) async {
    return await _firestore
        .collection('medical_records')
        .where('noRekamMedis', isEqualTo: noRekamMedis)
        .get();
  }

  /// Stream data medical_records berdasarkan nomor rekam medis user
  Stream<QuerySnapshot<Map<String, dynamic>>>
  streamMedicalRecordsByNoRekamMedis(String noRekamMedis) {
    return _firestore
        .collection('medical_records')
        .where('noRekamMedis', isEqualTo: noRekamMedis)
        .snapshots();
  }

  /// Ambil riwayat pemeriksaan dari Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> streamRiwayatPemeriksaan(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('medical_history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Simpan janji temu baru
  Future<void> saveAppointment(
    String uid,
    Map<String, dynamic> appointmentData,
  ) async {
    // Simpan di sub-koleksi user untuk akses cepat user
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .add(appointmentData);

    // Simpan di koleksi global 'appointments' agar bisa dilihat oleh admin/klinik
    await _firestore.collection('appointments').add({
      ...appointmentData,
      'userId': uid,
    });
  }

  /// Stream data janji temu mendatang dari Firestore (diurutkan dari TANGGAL TERDEKAT)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAppointments(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .orderBy(
          'appointment_date',
          descending: false,
        ) // Diubah: ascending agar yang paling dekat muncul pertama
        .snapshots();
  }

  /// Stream janji temu user di koleksi global appointments untuk memastikan update admin ikut terbaca
  /// (Sorting dilakukan di memory, bukan di query, untuk menghindari composite index requirement)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserAppointments(
    String uid,
  ) {
    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  /// Cek apakah NIK sudah terdaftar
  Future<bool> isNikRegistered(String nik) async {
    final query = await _firestore
        .collection('users')
        .where('nik', isEqualTo: nik)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // ==========================================
  // FIREBASE REALTIME DATABASE (Instant Data)
  // ==========================================

  /// Stream nomor antrean saat ini yang sedang dipanggil (Realtime)
  Stream<DatabaseEvent> streamCurrentQueue(String poliName) {
    return _realtimeDb.ref('queues/$poliName/current').onValue;
  }

  /// Stream data lengkap antrean poliklinik (current dan total_queued)
  Stream<DatabaseEvent> streamFullQueueData(String poliName) {
    return _realtimeDb.ref('queues/$poliName').onValue;
  }

  /// Stream antrean milik user sendiri secara realtime
  Stream<DatabaseEvent> streamUserActiveQueue(String uid) {
    return _realtimeDb.ref('users/$uid/active_queue').onValue;
  }

  /// Stream data antrean per queue key di /antrean/queue_X
  Stream<DatabaseEvent> streamQueueDataByKey(String queueKey) {
    return _realtimeDb.ref('antrean/$queueKey').onValue;
  }

  /// Stream antrean semua queue yang memiliki poliTujuan tertentu
  Stream<DatabaseEvent> streamAntreanByPoli(String poliTujuan) {
    return _realtimeDb
        .ref('antrean')
        .orderByChild('poliTujuan')
        .equalTo(poliTujuan)
        .onValue;
  }

  /// Update nomor antrean yang sedang dipanggil
  Future<void> updateCurrentQueue(
    String poliName,
    String currentQueueNumber,
  ) async {
    await _realtimeDb.ref('queues/$poliName').update({
      'current': currentQueueNumber,
      'last_updated': ServerValue.timestamp,
    });
  }

  /// Ambil antrean baru secara berurutan
  Future<String> takeNewQueue(String poliName) async {
    final ref = _realtimeDb.ref('queues/$poliName/total_queued');
    final TransactionResult result = await ref.runTransaction((
      Object? currentData,
    ) {
      if (currentData == null) {
        return Transaction.success(1);
      }
      if (currentData is int) {
        return Transaction.success(currentData + 1);
      }
      return Transaction.success(1);
    });

    if (result.committed) {
      final currentNumber = result.snapshot.value as int? ?? 1;
      return currentNumber.toString();
    } else {
      throw Exception('Gagal mengambil antrean');
    }
  }

  /// Set antrean aktif untuk user (Realtime)
  Future<void> setUserActiveQueue(
    String uid,
    Map<String, dynamic> queueData,
  ) async {
    await _realtimeDb.ref('users/$uid/active_queue').set(queueData);
  }

  /// Generate nomor rekam medis unik seperti P-00891
  Future<String> generateUniqueMedicalRecordNumber() async {
    final counterRef = _realtimeDb.ref('medical_record_counter');
    final TransactionResult result = await counterRef.runTransaction((
      Object? currentData,
    ) {
      int currentCounter = (currentData as int?) ?? 0;
      return Transaction.success(currentCounter + 1);
    });

    if (!result.committed) {
      throw Exception('Gagal membuat nomor rekam medis unik');
    }

    final int recordCounter = result.snapshot.value as int? ?? 1;
    return 'P-${recordCounter.toString().padLeft(5, '0')}';
  }

  // ==========================================
  // QUEUE MANAGEMENT (Struktur Baru)
  // ==========================================

  /// Buat antrean baru dengan struktur baru di /antrean/queue_X/
  /// Mengembalikan queue key (misal: queue_1, queue_2)
  Future<String> createNewQueue({
    required String nomorAntrean,
    required String poliTujuan,
    required String namaPasien,
    required String noRekamMedis,
    required String keluhanAwal,
    int estimasiMenit = 25,
  }) async {
    try {
      // Ambil counter untuk queue ID
      final counterRef = _realtimeDb.ref('queue_counter');
      final TransactionResult result = await counterRef.runTransaction((
        Object? currentData,
      ) {
        int currentCounter = (currentData as int?) ?? 0;
        return Transaction.success(currentCounter + 1);
      });

      if (!result.committed) {
        throw Exception('Gagal membuat counter untuk antrean');
      }

      final queueCounter = result.snapshot.value as int? ?? 1;
      final queueKey = 'queue_$queueCounter';

      // Simpan data antrean dengan struktur baru
      await _realtimeDb.ref('antrean/$queueKey').set({
        'nomorAntrean': nomorAntrean,
        'poliTujuan': poliTujuan,
        'namaPasien': namaPasien,
        'noRekamMedis': noRekamMedis,
        'keluhanAwal': keluhanAwal,
        'estimasiMenit': estimasiMenit,
        'status': 'menunggu',
        'waktuDaftar': ServerValue.timestamp,
      });

      return queueKey;
    } catch (e) {
      throw Exception('Error membuat antrean baru: $e');
    }
  }

  // ==========================================
  // APPOINTMENT MANAGEMENT (Struktur Baru)
  // ==========================================

  /// Ambil dokter-dokter dari /dokter/ berdasarkan poli
  Future<List<Map<String, dynamic>>> getDoctorsByPoli(String poliName) async {
    try {
      final snapshot = await _realtimeDb.ref('dokter').get();
      if (!snapshot.exists) {
        return [];
      }

      final allDoctors = Map<String, dynamic>.from(snapshot.value as Map);
      List<Map<String, dynamic>> filteredDoctors = [];

      for (var doctorEntry in allDoctors.entries) {
        final doctorData = Map<String, dynamic>.from(doctorEntry.value as Map);
        // Filter berdasarkan poli dan isActive = true
        if (doctorData['poli'] == poliName &&
            (doctorData['isActive'] ?? false)) {
          doctorData['key'] = doctorEntry.key;
          filteredDoctors.add(doctorData);
        }
      }

      return filteredDoctors;
    } catch (e) {
      throw Exception('Error mengambil dokter: $e');
    }
  }

  /// Buat janji temu baru di Firestore
  Future<void> createAppointment({
    required String uid,
    required String namaPasien,
    required String nikOrKeluhan,
    required String poli,
    required String doctorName,
    required DateTime tanggal,
    required String dateLabel,
    required String waktu,
    bool isEmergency = false,
    int estimasiMenit = 30,
  }) async {
    try {
      // Simpan janji temu ke Firestore saja
      await saveAppointment(uid, {
        'namaPasien': namaPasien,
        'nikOrKeluhan': nikOrKeluhan,
        'poli': poli,
        'doctorName': doctorName,
        'date': dateLabel,
        'time': waktu,
        'isEmergency': isEmergency,
        'estimasiMenit': estimasiMenit,
        'status': 'Menunggu Konfirmasi',
        'timestamp': FieldValue.serverTimestamp(),
        'appointment_date': Timestamp.fromDate(tanggal),
      });
    } catch (e) {
      throw Exception('Error membuat janji temu: $e');
    }
  }

  /// Hapus active queue user (digunakan ketika antrean selesai)
  Future<void> clearActiveQueue(String uid) async {
    try {
      await _realtimeDb.ref('users/$uid/active_queue').remove();
    } catch (e) {
      throw Exception('Error menghapus active queue: $e');
    }
  }
}
