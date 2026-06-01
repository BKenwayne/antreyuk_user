import 'package:flutter/material.dart';
import 'ambil_antrean_page.dart';
import 'profile_page.dart';
import 'janji_temu_page.dart';
import 'antrean_page.dart';

class HomePageWithJanji extends StatefulWidget {
  const HomePageWithJanji({super.key});

  @override
  State<HomePageWithJanji> createState() => _HomePageWithJanjiState();
}

class _HomePageWithJanjiState extends State<HomePageWithJanji> {
  int _selectedIndex = 0;
  double _fabX = -1;
  double _fabY = 400;
  bool _hasJanjiTemu = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fabX == -1) {
      _fabX = MediaQuery.of(context).size.width - 70;
      _fabY = MediaQuery.of(context).size.height * 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
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
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE6F0FF),
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
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
            const Text(
              'Bapak Budi Santoso',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            // Antrean Card
            Container(
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
                  // Top part (blue)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0052A3),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Nomor Antrean Anda',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A-15',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F7A3E), // green
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_active_outlined, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Estimasi Waktu: 10 Menit',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom part (white)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Sedang Dipanggil (Poli Umum)',
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A-12',
                          style: TextStyle(
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
            
            const SizedBox(height: 24),
            
            if (_hasJanjiTemu) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE0), // Light peach color
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC78D6B), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.edit_calendar, color: Color(0xFF3E1F11)),
                        SizedBox(width: 8),
                        Text(
                          'Janji Temu Mendatang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E1F11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('POLI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5A44))),
                              SizedBox(height: 4),
                              Text('Poli Umum', style: TextStyle(fontSize: 15, color: Color(0xFF3E1F11))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TANGGAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5A44))),
                              SizedBox(height: 4),
                              Text('12 Okt 2023', style: TextStyle(fontSize: 15, color: Color(0xFF3E1F11))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('JAM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5A44))),
                              SizedBox(height: 4),
                              Text('09:00 WIB', style: TextStyle(fontSize: 15, color: Color(0xFF3E1F11))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DOKTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5A44))),
                              SizedBox(height: 4),
                              Text('dr. Budi Santoso', style: TextStyle(fontSize: 15, color: Color(0xFF3E1F11))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Antre Sekarang Button
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
            
            // Two cards
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
                  child: _buildActionCard(
                    icon: Icons.assignment,
                    iconBgColor: const Color(0xFFE6F0FF),
                    iconColor: const Color(0xFF003B73),
                    title: 'Riwayat Kesehatan',
                    subtitle: 'Cek hasil\nsebelumnya',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
          // Draggable FAB
          Positioned(
            left: _fabX,
            top: _fabY,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _fabX += details.delta.dx;
                  _fabY += details.delta.dy;
                });
              },
              onPanEnd: (details) {
                setState(() {
                  double screenWidth = MediaQuery.of(context).size.width;
                  if (_fabX > screenWidth / 2) {
                    _fabX = screenWidth - 70; // snap to right edge
                  } else {
                    _fabX = 10; // snap to left edge
                  }
                  
                  // clamp Y
                  double screenHeight = MediaQuery.of(context).size.height;
                  _fabY = _fabY.clamp(0.0, screenHeight - 200);
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F7A3E), // dark green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.chat, color: Colors.white, size: 28),
              ),
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
