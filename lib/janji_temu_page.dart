import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'antrean_page.dart';
import 'services/firebase_service.dart';
import 'utils/image_helper.dart';

class JanjiTemuPage extends StatefulWidget {
  const JanjiTemuPage({super.key});

  @override
  State<JanjiTemuPage> createState() => _JanjiTemuPageState();
}

class _JanjiTemuPageState extends State<JanjiTemuPage> {
  final int _selectedIndex = 2; // 2 is Janji Temu
  
  String _selectedPoliId = "poli_umum";
  String _selectedPoliName = "Poli Umum";
  DateTime _selectedDate = DateTime.now();
  int _selectedTimeDoctorIndex = 0;
  String _selectedTime = '08:00';

  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  String _formatDate(DateTime date) {
    List<String> months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const AntreanPage(),
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
    }
  }

  void _submitAppointment(List<dynamic> doctors) async {
    if (doctors.isEmpty || _uid.isEmpty) return;
    
    final selectedDoc = doctors[_selectedTimeDoctorIndex < doctors.length ? _selectedTimeDoctorIndex : 0];
    final String doctorName = selectedDoc['name']?.toString() ?? "";

    try {
      // Ambil profil user untuk mendapatkan nama dan NIK
      final userProfile = await _firebaseService.getUserProfile(_uid);
      if (!userProfile.exists) {
        throw Exception('Profil user tidak ditemukan');
      }

      final profileData = userProfile.data();
      final String namaPasien = profileData?['name'] ?? "Pasien";
      final String nik = profileData?['nik'] ?? "";
      
      // Format waktu untuk simpan
      // Diasumsikan waktu dipilih dari jam kerja (misal 08:30, 09:00, dst)
      String waktu = "08:30"; // Default
      if (_selectedTime.isNotEmpty) {
        waktu = _selectedTime;
      }

      // Buat janji temu dengan struktur baru
      await _firebaseService.createAppointment(
        uid: _uid,
        namaPasien: namaPasien,
        nikOrKeluhan: "NIK: $nik",
        poli: _selectedPoliName,
        doctorName: doctorName,
        tanggal: _selectedDate,
        dateLabel: _formatDate(_selectedDate),
        waktu: waktu,
        isEmergency: false,
        estimasiMenit: 30,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Berhasil membuat janji temu dengan $doctorName!"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal membuat janji temu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('poliklinik').snapshots(),
            builder: (context, poliklinikSnapshot) {
              List<QueryDocumentSnapshot<Map<String, dynamic>>> polis = [];
              if (poliklinikSnapshot.hasData) {
                polis = poliklinikSnapshot.data!.docs;
              }

              QueryDocumentSnapshot<Map<String, dynamic>>? activePoliDoc;
              for (var doc in polis) {
                if (doc.id == _selectedPoliId) {
                  activePoliDoc = doc;
                  break;
                }
              }
              if (activePoliDoc == null && polis.isNotEmpty) {
                activePoliDoc = polis[0];
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buat Janji Temu',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih poliklinik, tanggal, dan waktu yang sesuai untuk kunjungan Anda.',
                      style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Pilih Poliklinik',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (polis.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Pilih Poliklinik'),
                            value: polis.any((p) => p.id == _selectedPoliId) ? _selectedPoliId : (polis.isNotEmpty ? polis.first.id : null),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                            items: polis.map((doc) {
                              String name = doc.data()['name'] ?? "";
                              String iconName = doc.data()['icon'] ?? "";
                              IconData icon = Icons.medical_services_outlined;
                              if (iconName.contains("child")) icon = Icons.child_care;
                              if (iconName.contains("heart")) icon = Icons.monitor_heart_outlined;

                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Row(
                                  children: [
                                    Icon(icon, color: const Color(0xFF0052A3), size: 20),
                                    const SizedBox(width: 12),
                                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                final selectedDoc = polis.firstWhere((doc) => doc.id == newValue);
                                setState(() {
                                  _selectedPoliId = newValue;
                                  _selectedPoliName = selectedDoc.data()['name'] ?? "";
                                  _selectedTimeDoctorIndex = 0;
                                });
                              }
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 20, top: 20, right: 20),
                            child: Text(
                              'Pilih Tanggal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          CalendarDatePicker(
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            onDateChanged: (DateTime newDate) {
                              setState(() {
                                _selectedDate = newDate;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Pilih Dokter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(_selectedDate)} - $_selectedPoliName',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _firebaseService.getDoctorsByPoli(_selectedPoliName),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }

                        List<Map<String, dynamic>> doctorsList = snapshot.data ?? [];
                        
                        if (doctorsList.isEmpty) {
                          return const Text("Tidak ada dokter yang tersedia untuk poli ini.");
                        }

                        return Column(
                          children: List.generate(doctorsList.length, (index) {
                            final doc = doctorsList[index];
                            return _buildDoctorCard(
                              index: index,
                              doctorName: doc['name'] ?? "",
                              isSelected: _selectedTimeDoctorIndex == index,
                              onTap: () {
                                setState(() {
                                  _selectedTimeDoctorIndex = index;
                                });
                              },
                            );
                          }),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Pilih Waktu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Default time slots
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00']
                          .map((time) {
                        final bool isSelectedTime = _selectedTime == time;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTime = time;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelectedTime ? const Color(0xFF0052A3) : Colors.white,
                              border: Border.all(color: isSelectedTime ? const Color(0xFF0052A3) : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelectedTime ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _firebaseService.getDoctorsByPoli(_selectedPoliName).then((doctors) {
                            _submitAppointment(doctors);
                          });
                        },
                        icon: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                        label: const Text(
                          'Buat Janji Temu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052A3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Center(
                      child: Text(
                        'Dengan membuat janji, Anda menyetujui syarat &\nketentuan klinik.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
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
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.post_add),
                    ),
                    label: 'Antrean',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 2 ? Colors.blue.shade50 : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.calendar_month),
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

  Widget _buildDoctorCard({
    required int index,
    required String doctorName,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052A3) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF0052A3)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                doctorName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0052A3) : Colors.grey.shade400,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF0052A3),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
