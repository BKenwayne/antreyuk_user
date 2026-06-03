import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'janji_temu_page.dart';
import 'antrean_page.dart';
import 'profile_page.dart';
import 'utils/image_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';

class RiwayatPengecekanPage extends StatefulWidget {
  const RiwayatPengecekanPage({super.key});

  @override
  State<RiwayatPengecekanPage> createState() => _RiwayatPengecekanPageState();
}

class _RiwayatPengecekanPageState extends State<RiwayatPengecekanPage> {
  final int _selectedIndex = 0;
  
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  bool _isSemuaRiwayat = true;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(pageBuilder: (_, __, ___) => const HomePage(), transitionDuration: Duration.zero),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(pageBuilder: (_, __, ___) => const AntreanPage(), transitionDuration: Duration.zero),
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(pageBuilder: (_, __, ___) => const JanjiTemuPage(), transitionDuration: Duration.zero),
        (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfilePage(), transitionDuration: Duration.zero),
        (route) => false,
      );
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF003B73)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                const Icon(Icons.health_and_safety, color: Color(0xFF0052A3)),
                const SizedBox(width: 8),
                const Text(
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
                    radius: 16,
                    backgroundColor: const Color(0xFFE6F0FF),
                    backgroundImage: userPhoto != null ? ImageHelper.getImageProvider(userPhoto) : null,
                    child: userPhoto == null ? const Icon(Icons.person, color: Color(0xFF0052A3)) : null,
                  ),
                ),
              )
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firebaseService.streamRiwayatPemeriksaan(_uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              
              final filteredDocs = docs.where((doc) {
                final data = doc.data();
                if (_isSemuaRiwayat) return true;
                return data['status'] == 'Menunggu Hasil';
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Pengecekan',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF003B73),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Pantau riwayat kunjungan medis dan hasil pemeriksaan Anda di sini.',
                      style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isSemuaRiwayat = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isSemuaRiwayat ? const Color(0xFF0052A3) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Semua Riwayat',
                              style: TextStyle(
                                color: _isSemuaRiwayat ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => setState(() => _isSemuaRiwayat = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isSemuaRiwayat ? const Color(0xFF0052A3) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Menunggu Hasil',
                              style: TextStyle(
                                color: !_isSemuaRiwayat ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (filteredDocs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60.0),
                          child: Column(
                            children: [
                              Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada riwayat pemeriksaan',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDocs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data();
                          return _buildHistoryCardFromData(data);
                        },
                      ),
                  ],
                ),
              );
            }
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
                onTap: _onItemTapped,
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
                        color: Colors.blue.shade50,
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

  Widget _buildHistoryCardFromData(Map<String, dynamic> data) {
    bool isSelesai = data['status'] == 'Selesai';
    bool isLab = data['isLab'] ?? false;

    return _buildHistoryCard(
      icon: isLab ? Icons.science : (data['icon'] == 'monitor_heart' ? Icons.monitor_heart : Icons.medical_services_outlined),
      iconBgColor: isLab ? const Color(0xFFFDE8D7) : const Color(0xFFE6F0FF),
      iconColor: isLab ? const Color(0xFF5A2A18) : const Color(0xFF0052A3),
      title: data['title'] ?? 'Pemeriksaan',
      date: data['date'] ?? '',
      statusText: data['status'] ?? '',
      statusBgColor: isSelesai ? Colors.greenAccent.shade200 : const Color(0xFF8B4513),
      statusTextColor: isSelesai ? Colors.green.shade900 : Colors.white,
      doctorName: data['doctorName'] ?? '',
      doctorSpecialty: data['doctorSpecialty'] ?? '',
      doctorAvatarUrl: data['doctorAvatarUrl'],
      isLab: isLab,
      summaryTitle: isSelesai ? 'RINGKASAN MEDIS' : 'STATUS PEMERIKSAAN',
      summaryText: data['summary'] ?? '',
      summaryBgColor: isSelesai ? Colors.grey.shade100 : const Color(0xFFFFF6ED),
      summaryBorderColor: isSelesai ? Colors.transparent : const Color(0xFFFFDAB9),
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String date,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    required String doctorName,
    required String doctorSpecialty,
    String? doctorAvatarUrl,
    required bool isLab,
    required String summaryTitle,
    required String summaryText,
    required Color summaryBgColor,
    required Color summaryBorderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          Row(
            children: [
              if (isLab)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital_outlined, color: Colors.black54, size: 20),
                )
              else
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: doctorAvatarUrl != null ? NetworkImage(doctorAvatarUrl) : null,
                  child: doctorAvatarUrl == null ? const Icon(Icons.person, color: Colors.blue) : null,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
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
