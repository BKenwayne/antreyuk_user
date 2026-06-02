import 'package:flutter/material.dart';
import 'home_page.dart';
import 'antrean_page.dart';
import 'janji_temu_page.dart';
import 'profile_page.dart';
import 'utils/image_helper.dart';
import 'services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthDocument {
  final String title;
  final String provider;
  final String date;
  final String type; // 'Hasil Lab', 'Resep', 'Sertifikat'
  final IconData icon;

  const HealthDocument({
    required this.title,
    required this.provider,
    required this.date,
    required this.type,
    required this.icon,
  });

  factory HealthDocument.fromFirestore(Map<String, dynamic> data) {
    IconData iconData = Icons.description_outlined;
    if (data['type'] == 'Sertifikat') iconData = Icons.vaccines_outlined;
    
    return HealthDocument(
      title: data['title'] ?? '',
      provider: data['provider'] ?? '',
      date: data['date'] ?? '',
      type: data['type'] ?? 'Lainnya',
      icon: iconData,
    );
  }
}

class DokumenKesehatanPage extends StatefulWidget {
  const DokumenKesehatanPage({super.key});

  @override
  State<DokumenKesehatanPage> createState() => _DokumenKesehatanPageState();
}

class _DokumenKesehatanPageState extends State<DokumenKesehatanPage> {
  final int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? "";
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = const [
    'Semua',
    'Hasil Lab',
    'Resep',
    'Sertifikat',
  ];

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AntreanPage(),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const JanjiTemuPage(),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const ProfilePage(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  Widget _buildDocumentCard(HealthDocument doc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(doc.icon, color: const Color(0xFF0052A3)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  doc.provider,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  doc.date,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: _firebaseService.getHealthDocuments(_uid),
            builder: (context, snapshot) {
              List<HealthDocument> documents = [];
              if (snapshot.hasData) {
                documents = snapshot.data!.docs.map((doc) => HealthDocument.fromFirestore(doc.data())).toList();
              }

              final filteredDocuments = documents.where((doc) {
                final matchesCategory = _selectedCategory == 'Semua' || doc.type == _selectedCategory;
                final matchesSearch = doc.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    doc.provider.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesCategory && matchesSearch;
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Title
                const Text(
                  'Dokumen Kesehatan',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF003B73),
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari dokumen',
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 15,
                        fontFamily: 'Montserrat',
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.black45),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Color(0xFF0052A3), width: 1.5),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Filter Chips Horizontal Scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0052A3) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.transparent : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),

                // Document List
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (filteredDocuments.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada dokumen ditemukan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
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
                    itemCount: filteredDocuments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final doc = filteredDocuments[index];
                      return _buildDocumentCard(doc);
                    },
                  ),
                const SizedBox(height: 40),
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
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Montserrat'),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontFamily: 'Montserrat'),
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
}
