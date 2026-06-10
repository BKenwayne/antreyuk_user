import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'janji_temu_page.dart';
import 'antrean_page.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';

class RiwayatPengecekanPage extends StatefulWidget {
  const RiwayatPengecekanPage({super.key});

  @override
  State<RiwayatPengecekanPage> createState() => _RiwayatPengecekanPageState();
}

class _RiwayatPengecekanPageState extends State<RiwayatPengecekanPage> {
  final int _selectedIndex = 3; // Mengubah ke 3 agar tab Profil di bottom nav tetap menyala aktif
  
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  bool _isSemuaRiwayat = true;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    Widget nextPage = const HomePage();
    if (index == 0) nextPage = const HomePage();
    if (index == 1) nextPage = const AntreanPage();
    if (index == 2) nextPage = const JanjiTemuPage();
    if (index == 3) nextPage = const ProfilePage();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextPage, 
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Riwayat Pengecekan',
          style: TextStyle(
            color: Color(0xFF003B73),
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Montserrat',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0052A3), size: 20),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const ProfilePage(),
                transitionDuration: Duration.zero,
              ),
            );
          },
        ),
      ),
      body: _uid.isEmpty
          ? const Center(child: Text('User belum login.'))
          : StreamBuilder<dynamic>(
              stream: _firebaseService.streamUserActiveQueue(_uid),
              builder: (context, activeQueueSnapshot) {
                String queueKey = '';
                if (activeQueueSnapshot.hasData && activeQueueSnapshot.data?.snapshot.value != null) {
                  final data = Map<dynamic, dynamic>.from(activeQueueSnapshot.data!.snapshot.value as Map);
                  queueKey = data['queue_key']?.toString() ?? '';
                }

                final bool hasQueueKey = queueKey.isNotEmpty;
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _firebaseService.streamUserProfile(_uid),
                  builder: (context, profileSnapshot) {
                    final lastNoRekamMedis = profileSnapshot.data?.data()?['lastNoRekamMedis']?.toString() ?? '';
                    final queryStream = hasQueueKey
                        ? _firebaseService.streamMedicalRecordsByPatientId(queueKey)
                        : lastNoRekamMedis.isNotEmpty
                            ? _firebaseService.streamMedicalRecordsByNoRekamMedis(lastNoRekamMedis)
                            : null;

                    if (queryStream == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 70, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Belum ada riwayat pengecekan', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: queryStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 70, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('Belum ada riwayat pengecekan', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                              ],
                            ),
                          );
                        }

                        var records = snapshot.data!.docs.map((doc) => doc.data()).toList();

                        records.sort((a, b) {
                          final ta = a['tanggalPengecekan'];
                          final tb = b['tanggalPengecekan'];
                          int ava = 0;
                          int bva = 0;
                          try {
                            if (ta is Timestamp) ava = ta.toDate().millisecondsSinceEpoch;
                            else if (ta is DateTime) ava = ta.millisecondsSinceEpoch;
                          } catch (_) {}
                          try {
                            if (tb is Timestamp) bva = tb.toDate().millisecondsSinceEpoch;
                            else if (tb is DateTime) bva = tb.millisecondsSinceEpoch;
                          } catch (_) {}
                          return bva.compareTo(ava);
                        });

                        if (!_isSemuaRiwayat) {
                          records = records.where((r) => (r['diagnosa'] != null && r['diagnosa'].toString().isNotEmpty)).toList();
                        }

                        if (records.isEmpty) {
                          return Center(
                            child: Text('Tidak ada data riwayat untuk kategori ini.', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: records.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isSemuaRiwayat = true;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _isSemuaRiwayat ? const Color(0xFF0052A3) : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: _isSemuaRiwayat ? Colors.transparent : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Semua Riwayat',
                                              style: TextStyle(
                                                color: _isSemuaRiwayat ? Colors.white : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isSemuaRiwayat = false;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: !_isSemuaRiwayat ? const Color(0xFF0052A3) : Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: !_isSemuaRiwayat ? Colors.transparent : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Pengecekan Fisik',
                                              style: TextStyle(
                                                color: !_isSemuaRiwayat ? Colors.white : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final data = records[index - 1];
                            String formattedDate = 'Baru Saja';
                            if (data['tanggalPengecekan'] != null) {
                              try {
                                final dt = (data['tanggalPengecekan'] as Timestamp).toDate();
                                formattedDate = '${dt.day}/${dt.month}/${dt.year}';
                              } catch (_) {}
                            }
                            return _buildHistoryCard(
                              doctorName: data['dokterName'] ?? 'Dokter Pemeriksa',
                              doctorSpecialty: data['dokterSpesialis'] ?? 'Umum',
                              dateStr: formattedDate,
                              summaryTitle: 'DIAGNOSA & KELUHAN',
                              summaryText: 'Keluhan: ${data['keluhan'] ?? '-'}\nDiagnosa: ${data['diagnosa'] ?? '-'}\nCatatan: ${data['catatanDokter'] ?? '-'}',
                              summaryBgColor: const Color(0xFFF8F9FA),
                              summaryBorderColor: Colors.grey.shade200,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFF0052A3),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: [
              const BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 8), child: Icon(Icons.home_outlined)), label: 'Beranda'),
              const BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 8), child: Icon(Icons.post_add)), label: 'Antrean'),
              const BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4, top: 8), child: Icon(Icons.calendar_month_outlined)), label: 'Janji Temu'),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person),
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= WIDGET COMPONENT ASLI BAWAAN VERSI LAMA ANDA =================
  Widget _buildHistoryCard({
    required String doctorName,
    required String doctorSpecialty,
    required String dateStr,
    required String summaryTitle,
    required String summaryText,
    required Color summaryBgColor,
    required Color summaryBorderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF0052A3),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            doctorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctorSpecialty,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: summaryBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: summaryBorderColor,
                width: summaryBorderColor == Colors.transparent ? 0 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summaryTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003B73),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summaryText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}