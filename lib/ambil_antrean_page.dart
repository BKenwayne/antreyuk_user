import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_page.dart';
import 'janji_temu_page.dart';
import 'profile_page.dart';
import 'antrean_page.dart';
import 'services/firebase_service.dart';
import 'utils/image_helper.dart';

class AmbilAntreanPage extends StatefulWidget {
  const AmbilAntreanPage({super.key});

  @override
  State<AmbilAntreanPage> createState() => _AmbilAntreanPageState();
}

class _AmbilAntreanPageState extends State<AmbilAntreanPage> {
  String? selectedPoli;
  final int _selectedIndex = 0;

  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _keluhanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    if (_uid.isEmpty) return;
    final profile = await _firebaseService.getUserProfile(_uid);
    if (profile.exists) {
      final data = profile.data();
      setState(() {
        _namaController.text = data?['name'] ?? "";
        _nikController.text = data?['nik'] ?? "";
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const HomePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const AntreanPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const JanjiTemuPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const ProfilePage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    }
  }

  void _submitAntrean() async {
    if (selectedPoli == null || _namaController.text.isEmpty || _nikController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan lengkapi semua bidang form!"), backgroundColor: Colors.red),
      );
      return;
    }

    String prefix = "A";
    String dbPoliKey = "poli_umum";
    if (selectedPoli!.toLowerCase().contains("gigi")) {
      prefix = "B";
      dbPoliKey = "poli_gigi";
    } else if (selectedPoli!.toLowerCase().contains("anak")) {
      prefix = "C";
      dbPoliKey = "poli_anak";
    } else if (selectedPoli!.toLowerCase().contains("jantung")) {
      prefix = "D";
      dbPoliKey = "poli_jantung";
    } else if (selectedPoli!.toLowerCase().contains("kia")) {
      prefix = "E";
      dbPoliKey = "poli_kia";
    } else if (selectedPoli!.toLowerCase().contains("mata")) {
      prefix = "F";
      dbPoliKey = "poli_mata";
    }

    try {
      String queueNumberStr = await _firebaseService.takeNewQueue(dbPoliKey);
      String queueNum = "$prefix-$queueNumberStr";

      await _firebaseService.setUserActiveQueue(_uid, {
        'queue_number': queueNum,
        'poli': selectedPoli,
        'estimasi_menit': 25,
        'status': 'Menunggu Panggilan',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Berhasil mengambil antrean: $queueNum"), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mendapatkan antrean: $e"), backgroundColor: Colors.red),
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF0052A3)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Ambil Antrean',
              style: TextStyle(
                color: Color(0xFF003B73),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
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
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052A3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: -25,
                        bottom: -35,
                        child: Icon(
                          Icons.assignment_add,
                          size: 110,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pendaftaran Mandiri',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Silakan lengkapi formulir di bawah\nini untuk mendapatkan nomor\nantrean pelayanan hari ini.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Container(
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
                      _buildLabel('Nama Lengkap'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _namaController,
                        hint: 'Contoh: Budi Santoso',
                        prefixIcon: Icons.person_outline,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildLabel('Nomor NIK (16 Digit)'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nikController,
                        hint: '3201xxxxxxxxxxxx',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pastikan 16 digit NIK sesuai dengan KTP Anda.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildLabel('Pilih Poli Tujuan'),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance.collection('poliklinik').snapshots(),
                        builder: (context, poliSnapshot) {
                          List<String> poliOptions = ['Poli Umum', 'Poli Anak', 'Poli Jantung'];
                          if (poliSnapshot.hasData && poliSnapshot.data!.docs.isNotEmpty) {
                            poliOptions = poliSnapshot.data!.docs
                                .map((doc) => doc.data()['name']?.toString() ?? "")
                                .where((name) => name.isNotEmpty)
                                .toList();
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Row(
                                  children: [
                                    Icon(Icons.medical_services_outlined, color: Colors.black54, size: 20),
                                    SizedBox(width: 12),
                                    Text('Pilih Poliklinik', style: TextStyle(color: Colors.black54, fontSize: 14)),
                                  ],
                                ),
                                value: selectedPoli,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                                items: poliOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.medical_services_outlined, color: Colors.black54, size: 20),
                                        const SizedBox(width: 12),
                                        Text(value, style: const TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedPoli = newValue;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildLabel('Keluhan Awal'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keluhanController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Jelaskan secara singkat gejala atau keluhan yang Anda rasakan...',
                          hintStyle: const TextStyle(color: Colors.black38, fontSize: 14, height: 1.4),
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF0052A3), width: 1.5),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info, color: Color(0xFF0F7A3E), size: 18),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Data yang Anda masukkan akan digunakan untuk proses verifikasi di loket pendaftaran.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _submitAntrean,
                          icon: const Icon(Icons.confirmation_num, color: Colors.white, size: 18),
                          label: const Text(
                            'Ambil Antrean Sekarang',
                            style: TextStyle(
                              fontSize: 14,
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
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: Colors.black54, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0052A3), width: 1.5),
        ),
      ),
    );
  }
}
