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
    if (doctors.isEmpty) return;
    
    final selectedDoc = doctors[_selectedTimeDoctorIndex < doctors.length ? _selectedTimeDoctorIndex : 0];
    final String doctorName = selectedDoc['name']?.toString() ?? "";
    final String timeRange = selectedDoc['time']?.toString() ?? "";

    if (_uid.isEmpty) return;

    try {
      // Menyiapkan DateTime objek untuk sorting di Beranda
      final timeParts = timeRange.split(" - ").first.split(":");
      final appointmentDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      await _firebaseService.saveAppointment(_uid, {
        'poli': _selectedPoliName,
        'doctorName': doctorName,
        'date': _formatDate(_selectedDate),
        'time': timeRange.split(" - ").first + " WIB",
        'timestamp': FieldValue.serverTimestamp(),
        'appointment_date': Timestamp.fromDate(appointmentDateTime), // Untuk sorting
        'status': 'Menunggu Konfirmasi',
      });

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

              List<dynamic> doctors = [];
              if (activePoliDoc != null) {
                doctors = activePoliDoc.data()['doctors'] as List<dynamic>? ?? [];
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
                      'Pilih poliklinik, tanggal, dan waktu\nyang sesuai untuk kunjungan Anda.',
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
                      'Pilih Waktu & Dokter',
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
                    
                    if (doctors.isEmpty)
                      const Text("Tidak ada dokter yang tersedia untuk poli ini.")
                    else
                      ...List.generate(doctors.length, (index) {
                        final doc = doctors[index];
                        return _buildTimeDoctorCard(
                          index: index,
                          time: doc['time']?.split(" - ")?.first ?? "08:00",
                          doctorName: doc['name'] ?? "",
                          specialty: doc['specialty'] ?? "",
                        );
                      }),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _submitAppointment(doctors),
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

  Widget _buildTimeDoctorCard({
    required int index,
    required String time,
    required String doctorName,
    required String specialty,
    bool isFull = false,
  }) {
    bool isSelected = _selectedTimeDoctorIndex == index && !isFull;
    return GestureDetector(
      onTap: isFull ? null : () {
        setState(() {
          _selectedTimeDoctorIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFull ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052A3) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : (isFull ? Colors.grey.shade200 : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0052A3) : (isFull ? Colors.transparent : Colors.grey.shade300),
                ),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isFull ? Colors.grey.shade400 : (isSelected ? const Color(0xFF0052A3) : Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isFull ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialty,
                    style: TextStyle(
                      color: isFull ? Colors.grey.shade300 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isFull)
              const Text(
                'Penuh',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              )
            else
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
