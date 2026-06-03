import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ambil_antrean_page.dart';
import 'profile_page.dart';
import 'janji_temu_page.dart';
import 'antrean_page.dart';
import 'riwayat_pengecekan_page.dart';
import 'services/firebase_service.dart';
import 'utils/image_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedAppointmentIndex = 0; // Melacak janji temu yang dipilih di dropdown

  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  String _extractQueueKeyFromQueueNumber(String queueNumber) {
    final match = RegExp(r'\d+').firstMatch(queueNumber);
    if (match != null) {
      return 'queue_${match.group(0)}';
    }
    return '';
  }

  String _getPoliKeyFromName(String poliName) {
    final lower = poliName.toLowerCase();
    if (lower.contains('gigi')) return 'poli_gigi';
    if (lower.contains('anak')) return 'poli_anak';
    if (lower.contains('jantung')) return 'poli_jantung';
    if (lower.contains('kia')) return 'poli_kia';
    if (lower.contains('mata')) return 'poli_mata';
    return 'poli_umum';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firebaseService.streamUserProfile(_uid),
      builder: (context, profileSnapshot) {
        String userName = "Pengguna";
        String? userPhoto;

        if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
          final profileData = profileSnapshot.data!.data();
          userName = profileData?['name'] ?? userName;
          userPhoto = profileData?['photo_url'];
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
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
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang,',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    StreamBuilder<DatabaseEvent>(
                      stream: _firebaseService.streamUserActiveQueue(_uid),
                      builder: (context, activeQueueSnapshot) {
                        bool hasQueue = false;
                        String queueNumber = "";
                        String queueKey = "";
                        String poli = "";
                        int estimasi = 0;

                        if (activeQueueSnapshot.hasData &&
                            activeQueueSnapshot.data!.snapshot.value != null) {
                          final data = Map<dynamic, dynamic>.from(
                              activeQueueSnapshot.data!.snapshot.value as Map);
                          queueNumber = data['queue_number']?.toString() ?? "";
                          queueKey = data['queue_key']?.toString() ?? "";
                          poli = data['poli']?.toString() ?? "";
                          estimasi = int.tryParse(data['estimasi_menit']?.toString() ?? "0") ?? 0;
                          if (queueNumber.isNotEmpty) {
                            hasQueue = true;
                          }
                        }

                        if (!hasQueue) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
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
                          );
                        }

                        final effectiveQueueKey = queueKey.isNotEmpty
                            ? queueKey
                            : _extractQueueKeyFromQueueNumber(queueNumber);

                        return StreamBuilder<DatabaseEvent>(
                          stream: effectiveQueueKey.isNotEmpty
                              ? _firebaseService.streamQueueDataByKey(effectiveQueueKey)
                              : Stream<DatabaseEvent>.empty(),
                          builder: (context, queueDetailSnapshot) {
                            String queueStatus = "";
                            if (queueDetailSnapshot.hasData &&
                                queueDetailSnapshot.data!.snapshot.value != null) {
                              final queueData = Map<dynamic, dynamic>.from(
                                  queueDetailSnapshot.data!.snapshot.value as Map);
                              queueNumber = queueData['nomorAntrean']?.toString() ?? queueNumber;
                              poli = queueData['poliTujuan']?.toString() ?? poli;
                              estimasi = int.tryParse(
                                      queueData['estimasiMenit']?.toString() ??
                                          queueData['estimasi_menit']?.toString() ??
                                          estimasi.toString()) ??
                                  estimasi;
                              queueStatus = queueData['status']?.toString() ?? queueStatus;
                            }

                            final String dbPoliKey = _getPoliKeyFromName(poli);

                            return StreamBuilder<DatabaseEvent>(
                              stream: _firebaseService.streamCurrentQueue(dbPoliKey),
                              builder: (context, currentPoliQueueSnapshot) {
                                String currentCalling = "-";
                                if (currentPoliQueueSnapshot.hasData &&
                                    currentPoliQueueSnapshot.data!.snapshot.value != null) {
                                  currentCalling =
                                      currentPoliQueueSnapshot.data!.snapshot.value.toString();
                                }

                                if (currentCalling == "-" &&
                                    queueStatus.toLowerCase().contains('dipanggil')) {
                                  currentCalling = queueNumber;
                                }

                                Widget buildQueueCard(String currentCalling) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation1, animation2) =>
                                              const AntreanPage(),
                                          transitionDuration: Duration.zero,
                                          reverseTransitionDuration: Duration.zero,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 24),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0052A3),
                                              borderRadius:
                                                  BorderRadius.vertical(top: Radius.circular(16)),
                                            ),
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'Nomor Antrean Anda',
                                                  style: TextStyle(
                                                      color: Colors.white, fontSize: 14),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  queueNumber,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 56,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF0F7A3E),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                          Icons.notifications_active_outlined,
                                                          color: Colors.white,
                                                          size: 16),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Estimasi Waktu: $estimasi Menit',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: const BorderRadius.vertical(
                                                  bottom: Radius.circular(16)),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  'Sedang Dipanggil ($poli)',
                                                  style: const TextStyle(
                                                      color: Colors.black54, fontSize: 15),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  currentCalling,
                                                  style: const TextStyle(
                                                    color: Color(0xFF003B73),
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                if (currentCalling == "-" && poli.isNotEmpty) {
                                  return StreamBuilder<DatabaseEvent>(
                                    stream: _firebaseService.streamAntreanByPoli(poli),
                                    builder: (context, samePoliSnapshot) {
                                      if (samePoliSnapshot.hasData &&
                                          samePoliSnapshot.data!.snapshot.value != null) {
                                        final allQueues = Map<dynamic, dynamic>.from(
                                            samePoliSnapshot.data!.snapshot.value as Map);
                                        for (final entry in allQueues.values) {
                                          try {
                                            final queue = Map<dynamic, dynamic>.from(entry as Map);
                                            final statusValue =
                                                queue['status']?.toString().toLowerCase() ?? "";
                                            if (statusValue.contains('dipanggil')) {
                                              final calledNumber =
                                                  queue['nomorAntrean']?.toString();
                                              if (calledNumber != null && calledNumber.isNotEmpty) {
                                                currentCalling = calledNumber;
                                                break;
                                              }
                                            }
                                          } catch (_) {}
                                        }
                                      }
                                      return buildQueueCard(currentCalling);
                                    },
                                  );
                                }

                                return buildQueueCard(currentCalling);
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firebaseService.streamAppointments(_uid),
                      builder: (context, appointmentSnapshot) {
                        if (appointmentSnapshot.hasData &&
                            appointmentSnapshot.data!.docs.isNotEmpty) {
                          
                          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = appointmentSnapshot.data!.docs.toList();

                          // Sort di memori agar jadwal paling dekat muncul pertama
                          docs.sort((a, b) {
                            var dateA = a.data()['appointment_date'];
                            var dateB = b.data()['appointment_date'];
                            if (dateA is Timestamp && dateB is Timestamp) {
                              return dateA.compareTo(dateB);
                            }
                            return 0;
                          });

                          // Reset index jika data berubah atau berkurang
                          if (_selectedAppointmentIndex >= docs.length) {
                            _selectedAppointmentIndex = 0;
                          }

                          final appointmentDoc = docs[_selectedAppointmentIndex].data();
                          final String appointmentPoli = appointmentDoc['poli']?.toString() ?? "";
                          final String appointmentDoctor = appointmentDoc['doctorName']?.toString() ?? "";
                          final String appointmentDate = appointmentDoc['date']?.toString() ?? "";
                          final String appointmentTime = appointmentDoc['time']?.toString() ?? "";

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECE0), // Light peach color
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFC78D6B), width: 1.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_calendar, color: Color(0xFF3E1F11)),
                                          SizedBox(width: 8),
                                          Text(
                                            'Janji Temu',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF3E1F11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Dropdown jika ada lebih dari 1 janji temu
                                    if (docs.length > 1)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFC78D6B).withOpacity(0.5)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: _selectedAppointmentIndex,
                                            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF3E1F11)),
                                            dropdownColor: const Color(0xFFFFECE0),
                                            items: List.generate(docs.length, (index) {
                                              final d = docs[index].data();
                                              // Ambil tanggal singkat saja untuk dropdown item
                                              String dateStr = d['date'].toString();
                                              String shortDate = dateStr.contains(',') ? dateStr.split(',').last.trim() : dateStr;
                                              return DropdownMenuItem(
                                                value: index,
                                                child: Text(
                                                  "${d['poli']} ($shortDate)",
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3E1F11)),
                                                ),
                                              );
                                            }),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _selectedAppointmentIndex = val;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('POLI',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5A44))),
                                          const SizedBox(height: 4),
                                          Text(appointmentPoli,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xFF3E1F11))),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('TANGGAL',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5A44))),
                                          const SizedBox(height: 4),
                                          Text(appointmentDate,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xFF3E1F11))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('JAM',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5A44))),
                                          const SizedBox(height: 4),
                                          Text(appointmentTime,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xFF3E1F11))),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('DOKTER',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF8B5A44))),
                                          const SizedBox(height: 4),
                                          Text(appointmentDoctor,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xFF3E1F11))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AmbilAntreanPage()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003B73),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.post_add, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Antre Sekarang',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ambil nomor antrean hari ini',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation1, animation2) => const JanjiTemuPage(),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              );
                            },
                            child: _buildActionCard(
                              icon: Icons.calendar_today,
                              iconBgColor: Colors.grey.shade200,
                              iconColor: const Color(0xFF003B73),
                              title: 'Janji Temu',
                              subtitle: 'Jadwalkan\ndokter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RiwayatPengecekanPage()),
                              );
                            },
                            child: _buildActionCard(
                              icon: Icons.assignment,
                              iconBgColor: const Color(0xFFE6F0FF),
                              iconColor: const Color(0xFF003B73),
                              title: 'Riwayat Kesehatan',
                              subtitle: 'Cek hasil\nsebelumnya',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  if (index == 1) {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const AntreanPage(),
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
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                selectedItemColor: const Color(0xFF0052A3),
                unselectedItemColor: Colors.grey,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 0 ? Colors.blue.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.home_filled),
                    ),
                    label: 'Beranda',
                  ),
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.post_add),
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

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}