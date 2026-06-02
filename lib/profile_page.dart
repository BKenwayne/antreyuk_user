import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'home_page.dart';
import 'login_page.dart';
import 'janji_temu_page.dart';
import 'antrean_page.dart';
import 'riwayat_pengecekan_page.dart';
import 'dokumen_kesehatan_page.dart';
import 'services/firebase_service.dart';
import 'utils/image_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final int _selectedIndex = 3; // 3 is Profil

  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Menambahkan batas resolusi agar ukuran string base64 tidak terlalu besar untuk Firestore
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50,
      maxWidth: 512,
      maxHeight: 512,
    );
    
    if (image != null) {
      try {
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        await _firebaseService.saveUserProfile(_uid, {
          'photo_url': base64Image,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui foto: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _editInfo(String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masukkan $title baru',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSave(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Kata Sandi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi Lama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi Baru',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (oldController.text.isNotEmpty && newController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kata sandi berhasil diubah!')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bantuan & FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Bagaimana cara mengambil antrean?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Pilih menu "Beranda" atau "Antrean", lalu isi form pendaftaran.'),
              SizedBox(height: 12),
              Text('2. Bagaimana cara membatalkan janji temu?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Hubungi customer service kami di cs@antreyuk.com atau hubungi nomor klinik terdekat.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firebaseService.streamUserProfile(_uid),
      builder: (context, profileSnapshot) {
        String userName = "Pengguna";
        String? userPhoto;
        String userNik = "-";
        String userPhone = "-";

        if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
          final data = profileSnapshot.data!.data();
          userName = data?['name'] ?? userName;
          userPhoto = data?['photo_url'];
          userNik = data?['nik'] ?? userNik;
          userPhone = data?['phone'] ?? userPhone;
        }

        final photoProvider = ImageHelper.getImageProvider(userPhoto);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            title: const Text(
              'Profil',
              style: TextStyle(
                color: Color(0xFF003B73),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Profile Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFFE6F0FF),
                              backgroundImage: photoProvider,
                              child: photoProvider == null
                                  ? const Icon(Icons.person, color: Color(0xFF0052A3), size: 40)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: -5,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0052A3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Nama Pengguna
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              _editInfo('Nama Pengguna', userName, (newValue) async {
                                await _firebaseService.saveUserProfile(_uid, {
                                  'name': newValue,
                                });
                              });
                            },
                            child: const Icon(
                              Icons.edit,
                              color: Color(0xFF0052A3),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user_outlined, size: 14, color: Colors.black54),
                          SizedBox(width: 4),
                          Text(
                            'Pasien Terverifikasi',
                            style: TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Informasi Pribadi
                const Text(
                  'Informasi Pribadi',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.badge_outlined,
                        iconBgColor: const Color(0xFFE6F0FF),
                        iconColor: const Color(0xFF0052A3),
                        title: 'Nomor Induk Kependudukan (NIK)',
                        value: userNik,
                        hasEdit: true,
                        onTap: () {
                          _editInfo('NIK', userNik, (newValue) async {
                            await _firebaseService.saveUserProfile(_uid, {
                              'nik': newValue,
                            });
                          });
                        },
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      _buildInfoRow(
                        icon: Icons.phone_outlined,
                        iconBgColor: const Color(0xFFE6F0FF),
                        iconColor: const Color(0xFF0052A3),
                        title: 'Nomor Telepon',
                        value: userPhone,
                        hasEdit: true,
                        onTap: () {
                          _editInfo('Nomor Telepon', userPhone, (newValue) async {
                            await _firebaseService.saveUserProfile(_uid, {
                              'phone': newValue,
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Riwayat Medis
                const Text(
                  'Riwayat Medis',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firebaseService.streamRiwayatPemeriksaan(_uid),
                    builder: (context, snapshot) {
                      String lastVisit = "Belum ada kunjungan";
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        lastVisit = snapshot.data!.docs.first.data()['date'] ?? "-";
                      }
                      return _buildInfoRow(
                        icon: Icons.history,
                        iconBgColor: Colors.greenAccent.shade100,
                        iconColor: Colors.green.shade800,
                        title: 'Kunjungan Terakhir',
                        value: lastVisit,
                        hasChevron: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RiwayatPengecekanPage(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _buildInfoRow(
                    icon: Icons.description_outlined,
                    iconBgColor: const Color(0xFFE6F0FF),
                    iconColor: const Color(0xFF0052A3),
                    title: 'Dokumen Kesehatan',
                    value: 'Resep & Hasil Lab',
                    hasChevron: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DokumenKesehatanPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Pengaturan Akun
                const Text(
                  'Pengaturan Akun',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildSettingsRow(
                        icon: Icons.lock_outline,
                        title: 'Ubah Kata Sandi',
                        onTap: _changePassword,
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                      _buildSettingsRow(
                        icon: Icons.help_outline,
                        title: 'Bantuan',
                        onTap: _showHelp,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Keluar Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Keluar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4, top: 8),
                      child: Icon(Icons.calendar_month_outlined),
                    ),
                    label: 'Janji Temu',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: _selectedIndex == 3 ? Colors.blue.shade50 : Colors.transparent,
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
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String value,
    bool hasEdit = false,
    bool hasChevron = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (hasEdit)
              const Icon(Icons.edit, color: Color(0xFF0052A3), size: 20),
            if (hasChevron)
              const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54, size: 20),
          ],
        ),
      ),
    );
  }
}
