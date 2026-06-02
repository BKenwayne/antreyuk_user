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
  Future<void> saveUserProfile(String uid, Map<String, dynamic> profileData) async {
    await _firestore.collection('users').doc(uid).set(profileData, SetOptions(merge: true));
  }

  /// Ambil data profile user dari Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Stream data profile user dari Firestore
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  /// Ambil dokumen kesehatan milik user dari Firestore
  Future<QuerySnapshot<Map<String, dynamic>>> getHealthDocuments(String uid) async {
    return await _firestore.collection('users').doc(uid).collection('health_documents').get();
  }

  /// Ambil riwayat pemeriksaan dari Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> streamRiwayatPemeriksaan(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('medical_history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Stream data janji temu mendatang dari Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAppointments(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .snapshots();
  }

  /// Cek apakah NIK sudah terdaftar
  Future<bool> isNikRegistered(String nik) async {
    final query = await _firestore.collection('users').where('nik', isEqualTo: nik).limit(1).get();
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

  /// Update nomor antrean yang sedang dipanggil
  Future<void> updateCurrentQueue(String poliName, String currentQueueNumber) async {
    await _realtimeDb.ref('queues/$poliName').update({
      'current': currentQueueNumber,
      'last_updated': ServerValue.timestamp,
    });
  }

  /// Ambil antrean baru secara berurutan
  Future<String> takeNewQueue(String poliName) async {
    final ref = _realtimeDb.ref('queues/$poliName/total_queued');
    final TransactionResult result = await ref.runTransaction((Object? currentData) {
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
  Future<void> setUserActiveQueue(String uid, Map<String, dynamic> queueData) async {
    await _realtimeDb.ref('users/$uid/active_queue').set(queueData);
  }
}
