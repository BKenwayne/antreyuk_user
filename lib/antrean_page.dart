import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'janji_temu_page.dart';
import 'profile_page.dart';
import 'ambil_antrean_page.dart';
import 'services/firebase_service.dart';
import 'utils/image_helper.dart';

class AntreanPage extends StatefulWidget {
  const AntreanPage({super.key});

  @override
  State<AntreanPage> createState() => _AntreanPageState();
}

class _AntreanPageState extends State<AntreanPage> {
  int _selectedIndex = 1; // 1 is Antrean

  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const JanjiTemuPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const ProfilePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firebaseService.streamUserProfile(_uid),
      builder: (context, profileSnapshot) {
        String? userPhoto;
        if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
          userPhoto = profileSnapshot.data!.data()?['photo_url'];
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.health_and_safety, color: Color(0xFF0052A3)),
                SizedBox(width: 8),
                Text(
                  'AntreYuk',
                  style: TextStyle(
                    color: Color(0xFF003B73),
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const ProfilePage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE6F0FF),
                    backgroundImage: userPhoto != null ? ImageHelper.getImageProvider(userPhoto) : null,
                    child: userPhoto == null ? const Icon(Icons.person, color: Color(0xFF0052A3), size: 20) : null,
                  ),
                ),
              )
            ],
            automaticallyImplyLeading: false,
          ),
          body: StreamBuilder<DatabaseEvent>(
            stream: _firebaseService.streamUserActiveQueue(_uid),
            builder: (context, activeQueueSnapshot) {
              bool hasQueue = false;
              String queueNumber = "";
              String poli = "";
              int estimasi = 0;
              String status = "";

              if (activeQueueSnapshot.hasData &&
                  activeQueueSnapshot.data!.snapshot.value != null) {
                final data = Map<dynamic, dynamic>.from(
                    activeQueueSnapshot.data!.snapshot.value as Map);
                queueNumber = data['queue_number']?.toString() ?? "";
                poli = data['poli']?.toString() ?? "";
                estimasi = int.tryParse(data['estimasi_menit']?.toString() ?? "0") ?? 0;
                status = data['status']?.toString() ?? "";
                if (queueNumber.isNotEmpty) {
                  hasQueue = true;
                }
              }

              String dbPoliKey = "poli_umum";
              if (poli.toLowerCase().contains("gigi")) dbPoliKey = "poli_gigi";
              if (poli.toLowerCase().contains("anak")) dbPoliKey = "poli_anak";
              if (poli.toLowerCase().contains("jantung")) dbPoliKey = "poli_jantung";

              return StreamBuilder<DatabaseEvent>(
                stream: _firebaseService.streamCurrentQueue(dbPoliKey),
                builder: (context, currentPoliQueueSnapshot) {
                  String currentCalling = "-";
                  if (currentPoliQueueSnapshot.hasData &&
                      currentPoliQueueSnapshot.data!.snapshot.value != null) {
                    currentCalling = currentPoliQueueSnapshot.data!.snapshot.value.toString();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!hasQueue)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.amber, size: 40),
                                const SizedBox(height: 12),
                                const Text(
                                  'Anda belum memiliki nomor antrean hari ini',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const AmbilAntreanPage()),
                                    );
                                  },
                                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                  label: const Text(
                                    'Ambil Antrean',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0052A3),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  poli,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Nomor Antrean Anda',
                                  style: TextStyle(color: Colors.black54, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  queueNumber,
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0052A3),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'ESTIMASI WAKTU',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$estimasi Menit',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Antrean aktif di poli',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$currentCalling sedang',
                                          style: const TextStyle(
                                            color: Color(0xFF0052A3),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Text(
                                          'dilayani',
                                          style: TextStyle(
                                            color: Color(0xFF0052A3),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Builder(
                                  builder: (context) {
                                    double progressVal = 0.0;
                                    if (queueNumber.isNotEmpty && currentCalling.isNotEmpty && currentCalling != "-") {
                                      final myNum = int.tryParse(queueNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                      final currentNum = int.tryParse(currentCalling.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                      if (myNum > 0) {
                                        progressVal = (currentNum / myNum).clamp(0.0, 1.0);
                                      }
                                    }
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progressVal,
                                        backgroundColor: Colors.grey.shade300,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0052A3)),
                                        minHeight: 12,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        const Text(
                          'Poliklinik Tersedia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance.collection('poliklinik').snapshots(),
                          builder: (context, poliSnapshot) {
                            if (!poliSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                            return Column(
                              children: poliSnapshot.data!.docs.map((doc) {
                                final data = doc.data();
                                final name = data['name']?.toString() ?? "Poliklinik";
                                IconData iconData = Icons.local_hospital;
                                if (data['icon'] == 'medical_services_outlined') iconData = Icons.medical_services_outlined;
                                else if (data['icon'] == 'child_care' || data['icon'] == 'child_care_outlined') iconData = Icons.child_care_outlined;
                                else if (data['icon'] == 'monitor_heart_outlined') iconData = Icons.monitor_heart_outlined;
                                else if (data['icon'] == 'visibility_outlined') iconData = Icons.visibility_outlined;

                                // MENGGUNAKAN STREAM BARU UNTUK MENGAMBIL SELURUH DATA ANTRENAN POLI
                                return StreamBuilder<DatabaseEvent>(
                                  stream: _firebaseService.streamFullQueueData(doc.id),
                                  builder: (context, queueSnapshot) {
                                    String currentQueue = "-";
                                    int waitingCount = 0;

                                    if (queueSnapshot.hasData && queueSnapshot.data!.snapshot.value != null) {
                                      final queueData = Map<dynamic, dynamic>.from(
                                          queueSnapshot.data!.snapshot.value as Map);

                                      // Ambil nilai current dan total_queued dari database
                                      currentQueue = queueData['current']?.toString() ?? "-";

                                      int totalQueued = int.tryParse(queueData['total_queued']?.toString() ?? "0") ?? 0;

                                      // Membersihkan karakter non-angka pada currentQueue (misal 'A-10' menjadi 10)
                                      int currentNum = int.tryParse(currentQueue.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                                      // Rumus hitung jumlah menunggu: total pendaftar - nomor yang sedang berjalan
                                      if (totalQueued > currentNum) {
                                        waitingCount = totalQueued - currentNum;
                                      } else {
                                        waitingCount = 0; // Proteksi jika antrean kosong atau data belum sinkron
                                      }
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildPoliklinikCard(
                                        icon: iconData,
                                        title: name,
                                        currentQueue: currentQueue,
                                        waitingCount: waitingCount, // <--- Sekarang otomatis realtime dari database!
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
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
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.home_outlined),
                    ),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 1 ? Colors.blue.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.post_add),
                    ),
                    label: 'Antrean',
                  ),
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.calendar_month_outlined),
                    ),
                    label: 'Janji Temu',
                  ),
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.person_outline),
                    ),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPoliklinikCard({
    required IconData icon,
    required String title,
    required String currentQueue,
    required int waitingCount,
  }) {
    Color waitingColor = waitingCount > 0 ? const Color(0xFF0F7A3E) : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0052A3), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Antrean saat ini: $currentQueue',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: waitingColor),
                    const SizedBox(width: 4),
                    Text(
                      '$waitingCount menunggu',
                      style: TextStyle(
                        color: waitingColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
