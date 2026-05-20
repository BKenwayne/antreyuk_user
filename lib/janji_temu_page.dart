import 'package:flutter/material.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'antrean_page.dart';
import 'home_page_with_janji.dart';

class JanjiTemuPage extends StatefulWidget {
  const JanjiTemuPage({super.key});

  @override
  State<JanjiTemuPage> createState() => _JanjiTemuPageState();
}

class _JanjiTemuPageState extends State<JanjiTemuPage> {
  final int _selectedIndex = 2; // 2 is Janji Temu
  
  int _selectedPoliIndex = 0;
  int _selectedDate = 9;
  int _selectedTimeDoctorIndex = 0;

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
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.teal.shade200,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
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
            
            // Pilih Poliklinik
            const Text(
              'Pilih Poliklinik',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildPoliCard(
              index: 0,
              title: 'Poli Umum',
              icon: Icons.medical_services_outlined,
            ),
            _buildPoliCard(
              index: 1,
              title: 'Poli Anak',
              icon: Icons.child_care,
            ),
            _buildPoliCard(
              index: 2,
              title: 'Poli Jantung',
              icon: Icons.monitor_heart_outlined,
            ),

            const SizedBox(height: 24),

            // Pilih Tanggal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Tanggal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.chevron_left, color: Colors.black54),
                      const Text(
                        'Oktober 2026',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black54),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Days header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDayHeader('Sen'),
                      _buildDayHeader('Sel'),
                      _buildDayHeader('Rab'),
                      _buildDayHeader('Kam'),
                      _buildDayHeader('Jum'),
                      _buildDayHeader('Sab'),
                      _buildDayHeader('Min', isWeekend: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Simplified static calendar
                  Table(
                    children: [
                      TableRow(
                        children: [
                          _buildDateCell(text: ''),
                          _buildDateCell(text: ''),
                          _buildDateCell(text: '1', isDisabled: true),
                          _buildDateCell(text: '2', isDisabled: true),
                          _buildDateCell(text: '3', isDisabled: true),
                          _buildDateCell(text: '4'),
                          _buildDateCell(text: '5', isWeekend: true),
                        ]
                      ),
                      TableRow(
                        children: [
                          _buildDateCell(text: '6'),
                          _buildDateCell(text: '7'),
                          _buildDateCell(text: '8'),
                          _buildDateCell(text: '9', isSelected: _selectedDate == 9),
                          _buildDateCell(text: '10'),
                          _buildDateCell(text: '11'),
                          _buildDateCell(text: '12', isWeekend: true),
                        ]
                      ),
                      TableRow(
                        children: [
                          _buildDateCell(text: '13'),
                          _buildDateCell(text: '14'),
                          _buildDateCell(text: '15'),
                          _buildDateCell(text: '16'),
                          _buildDateCell(text: '17'),
                          _buildDateCell(text: '18'),
                          _buildDateCell(text: '19', isWeekend: true),
                        ]
                      ),
                      TableRow(
                        children: [
                          _buildDateCell(text: '20'),
                          _buildDateCell(text: '21'),
                          _buildDateCell(text: '22'),
                          _buildDateCell(text: '23'),
                          _buildDateCell(text: '24'),
                          _buildDateCell(text: '25'),
                          _buildDateCell(text: '26', isWeekend: true),
                        ]
                      ),
                      TableRow(
                        children: [
                          _buildDateCell(text: '27'),
                          _buildDateCell(text: '28'),
                          _buildDateCell(text: '29'),
                          _buildDateCell(text: '30'),
                          _buildDateCell(text: '31'),
                          _buildDateCell(text: ''),
                          _buildDateCell(text: ''),
                        ]
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pilih Waktu & Dokter
            const Text(
              'Pilih Waktu & Dokter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kamis, 9 Oktober 2026 - Poli Umum',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            
            _buildTimeDoctorCard(
              index: 0,
              time: '08:00',
              doctorName: 'Dr. Budi Santoso',
              specialty: 'Dokter Umum',
            ),
            _buildTimeDoctorCard(
              index: 1,
              time: '09:00',
              doctorName: 'Dr. Budi Santoso',
              specialty: 'Dokter Umum',
            ),
            _buildTimeDoctorCard(
              index: 2,
              time: '10:00',
              doctorName: 'Dr. Rina Purnamasari',
              specialty: 'Dokter Umum',
              isFull: true,
            ),
            _buildTimeDoctorCard(
              index: 3,
              time: '11:00',
              doctorName: 'Dr. Rina Purnamasari',
              specialty: 'Dokter Umum',
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomePageWithJanji(),
                    ),
                  );
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
  }

  Widget _buildPoliCard({
    required int index,
    required String title,
    required IconData icon,
  }) {
    bool isSelected = _selectedPoliIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPoliIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0052A3) : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? const Color(0xFF0052A3) : Colors.black54, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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

  Widget _buildDayHeader(String day, {bool isWeekend = false}) {
    return Center(
      child: Text(
        day,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isWeekend ? Colors.red : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDateCell({
    required String text,
    bool isDisabled = false,
    bool isWeekend = false,
    bool isSelected = false,
  }) {
    if (text.isEmpty) {
      return const SizedBox(height: 40);
    }

    Color textColor = Colors.black87;
    if (isDisabled) textColor = Colors.grey.shade400;
    else if (isWeekend) textColor = Colors.red;
    if (isSelected) textColor = Colors.white;

    return GestureDetector(
      onTap: isDisabled ? null : () {
        setState(() {
          _selectedDate = int.parse(text);
        });
      },
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0052A3) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
