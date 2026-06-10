import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'home_page.dart';
import 'antrean_page.dart';
import 'janji_temu_page.dart';
import 'profile_page.dart';
import 'services/firebase_service.dart';

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
    'Surat',
    'Rekam Medis',
  ];

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
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfilePage(), transitionDuration: Duration.zero),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firebaseService.streamUserProfile(_uid),
      builder: (context, profileSnapshot) {
        final userData = profileSnapshot.data?.data();
        final lastNoRekamMedis = userData?['lastNoRekamMedis']?.toString() ?? '';

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
              children: const [
                Icon(Icons.health_and_safety, color: Color(0xFF0052A3)),
                SizedBox(width: 8),
                Text(
                  'Dokumen Kesehatan',
                  style: TextStyle(
                    color: Color(0xFF003B73),
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          body: StreamBuilder<DatabaseEvent>(
            stream: _firebaseService.streamUserActiveQueue(_uid),
            builder: (context, activeQueueSnapshot) {
              String queueKey = '';
              if (activeQueueSnapshot.hasData && activeQueueSnapshot.data!.snapshot.value != null) {
                final data = Map<dynamic, dynamic>.from(activeQueueSnapshot.data!.snapshot.value as Map);
                queueKey = data['queue_key']?.toString() ?? '';
              }

              final bool hasActiveQueue = queueKey.isNotEmpty;
              final recordStream = hasActiveQueue
                  ? _firebaseService.streamMedicalRecordsByPatientId(queueKey)
                  : lastNoRekamMedis.isNotEmpty
                      ? _firebaseService.streamMedicalRecordsByNoRekamMedis(lastNoRekamMedis)
                      : null;

              if (recordStream == null) {
                return _buildEmptyState();
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: recordStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text('Terjadi kesalahan: ${snapshot.error}'),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final records = docs.map((doc) => doc.data()).toList();

                  if (records.isEmpty) {
                    return _buildEmptyState();
                  }

                  final filteredRecords = records.where((doc) {
                    final type = _recordType(doc);
                    final matchesCategory = _selectedCategory == 'Semua' || type == _selectedCategory;
                    final keyword = _searchQuery.toLowerCase();
                    final title = _recordTitle(doc).toLowerCase();
                    final provider = _recordProvider(doc).toLowerCase();
                    return matchesCategory && (title.contains(keyword) || provider.contains(keyword));
                  }).toList();

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSearchField(),
                              const SizedBox(height: 16),
                              _buildCategoryChips(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                      if (filteredRecords.isEmpty)
                        SliverToBoxAdapter(child: _buildNoResultsState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final record = filteredRecords[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildRecordCard(record),
                                );
                              },
                              childCount: filteredRecords.length,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(child: const SizedBox(height: 40)),
                    ],
                  );
                },
              );
            },
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Cari dokumen',
        prefixIcon: const Icon(Icons.search, color: Colors.black45),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((category) {
          final selected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF0052A3) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: selected ? Colors.transparent : Colors.grey.shade300),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final title = _recordTitle(record);
    final provider = _recordProvider(record);
    final date = _recordDate(record);
    final type = _recordType(record);
    final icon = _recordIcon(type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Color(0xFF0052A3)),
                const SizedBox(width: 8),
                Text(date, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052A3).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(color: Color(0xFF0052A3), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDocumentDetails(record),
                    icon: const Icon(Icons.remove_red_eye, size: 16),
                    label: const Text('Lihat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadRecord(record),
                    icon: const Icon(Icons.download_rounded, size: 16, color: Color.fromARGB(255, 255, 255, 255)),
                    label: const Text('Unduh', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052A3)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
          const Text(
            'Data dokumen kesehatan akan muncul setelah admin menyelesaikan pemeriksaan dan mengisi medical record.',
            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Belum ada data dokumen kesehatan',
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
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Icon(Icons.search_off_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Tidak ada dokumen ditemukan',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadRecord(Map<String, dynamic> record) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filename = 'dokumen_kesehatan_${record['noRekamMedis'] ?? DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${dir.path}/$filename');
      final content = _buildDocumentExport(record);
      await file.writeAsString(content);

      await Share.shareXFiles([XFile(file.path)], text: 'Dokumen Kesehatan ${record['noRekamMedis'] ?? ''}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh dokumen: $e')),
        );
      }
    }
  }

  String _buildDocumentExport(Map<String, dynamic> record) {
    final buffer = StringBuffer();
    buffer.writeln('Dokumen Kesehatan');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Nama Pasien: ${record['namaPasien'] ?? '-'}');
    buffer.writeln('No. Rekam Medis: ${record['noRekamMedis'] ?? '-'}');
    buffer.writeln('Dokter: ${record['dokterName'] ?? '-'}');
    buffer.writeln('Tanggal Pengecekan: ${_recordDate(record)}');
    buffer.writeln('');
    buffer.writeln('Keluhan: ${record['keluhan'] ?? '-'}');
    buffer.writeln('Diagnosa: ${record['diagnosa'] ?? '-'}');
    buffer.writeln('Catatan Dokter: ${record['catatanDokter'] ?? '-'}');
    buffer.writeln('Resep Obat: ${record['resepObat'] ?? '-'}');
    buffer.writeln('Tensi Darah: ${record['tensiDarah'] ?? '-'}');
    buffer.writeln('Suhu Tubuh: ${record['suhuTubuh'] ?? '-'}');
    buffer.writeln('Berat Badan: ${record['beratBadan'] ?? '-'}');
    buffer.writeln('Tinggi Badan: ${record['tinggiBadan'] ?? '-'}');
    return buffer.toString();
  }

  void _showDocumentDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_recordTitle(record)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dokter: ${record['dokterName'] ?? '-'}'),
                const SizedBox(height: 6),
                Text('Keluhan: ${record['keluhan'] ?? '-'}'),
                const SizedBox(height: 6),
                Text('Diagnosa: ${record['diagnosa'] ?? '-'}'),
                const SizedBox(height: 6),
                Text('Catatan Dokter: ${record['catatanDokter'] ?? '-'}'),
                const SizedBox(height: 6),
                Text('Resep Obat: ${record['resepObat'] ?? '-'}'),
                const SizedBox(height: 6),
                Text('Tensi Darah: ${record['tensiDarah'] ?? '-'}'),
                const SizedBox(height: 6),
                Text('Suhu Tubuh: ${record['suhuTubuh'] ?? '-'}'),
                const SizedBox(height: 6),
                Text('Berat Badan: ${record['beratBadan'] ?? '-'}'),
                const SizedBox(height: 6),
                Text('Tinggi Badan: ${record['tinggiBadan'] ?? '-'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  String _recordType(Map<String, dynamic> record) {
    final type = record['type']?.toString().trim();
    if (type != null && type.isNotEmpty) {
      return type;
    }
    if ((record['resepObat']?.toString().trim().isNotEmpty ?? false)) {
      return 'Resep';
    }
    if ((record['diagnosa']?.toString().trim().isNotEmpty ?? false)) {
      return 'Hasil Lab';
    }
    return 'Rekam Medis';
  }

  String _recordTitle(Map<String, dynamic> record) {
    if ((record['diagnosa']?.toString().trim().isNotEmpty ?? false)) {
      return record['diagnosa'].toString();
    }
    if ((record['resepObat']?.toString().trim().isNotEmpty ?? false)) {
      return 'Resep Obat';
    }
    return 'Dokumen Kesehatan';
  }

  String _recordProvider(Map<String, dynamic> record) {
    return record['dokterName']?.toString() ?? 'Dokter Pemeriksa';
  }

  String _recordDate(Map<String, dynamic> record) {
    final timestamp = record['tanggalPengecekan'];
    if (timestamp is Timestamp) {
      return _formatIndonesianDate(timestamp.toDate());
    }
    if (timestamp is DateTime) {
      return _formatIndonesianDate(timestamp);
    }
    return '-';
  }

  IconData _recordIcon(String type) {
    switch (type.toLowerCase()) {
      case 'resep':
        return Icons.medical_services_outlined;
      case 'hasil lab':
      case 'lab':
        return Icons.science_outlined;
      case 'surat':
        return Icons.article_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5)),
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
    );
  }

  String _formatIndonesianDate(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final monthName = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day $monthName ${dt.year} · $hour:$minute';
  }
}
