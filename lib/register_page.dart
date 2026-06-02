import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firebase_service.dart';
import 'login_page.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _hpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _hpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Logo icon
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFF0052A3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'AntreYuk',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF003B73), // darker blue
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'Solusi Antrean Medis Cerdas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 48),

              // Form Container
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buat Akun Baru',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lengkapi data diri Anda untuk memulai.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Nama Lengkap'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      hint: 'Masukkan nama sesuai KTP',
                      prefixIcon: Icons.person_outline,
                      controller: _namaController,
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('NIK (16 Digit)'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      hint: '16 digit nomor KTP',
                      prefixIcon: Icons.badge_outlined,
                      controller: _nikController,
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Nomor HP'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      hint: 'Contoh: 081234567890',
                      prefixIcon: Icons.phone_iphone,
                      controller: _hpController,
                    ),

                    const SizedBox(height: 16),

                    _buildLabel('Kata Sandi'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      hint: 'Minimal 8 karakter',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      controller: _passwordController,
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () async {
                          if (_nikController.text.isEmpty || _passwordController.text.isEmpty || _namaController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua data')));
                            return;
                          }
                          if (_nikController.text.length != 16) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NIK harus 16 digit')));
                            return;
                          }

                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            // 3. Cek apakah NIK sudah terdaftar
                            final existingUser = await FirebaseFirestore.instance
                                .collection('users')
                                .where('nik', isEqualTo: _nikController.text)
                                .limit(1)
                                .get();

                            if (existingUser.docs.isNotEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NIK sudah pernah didaftarkan')));
                                setState(() => _isLoading = false);
                              }
                              return;
                            }

                            String email = "${_nikController.text}@antreyuk.com";
                            UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: _passwordController.text);
                            if (cred.user != null) {
                              await FirebaseService().saveUserProfile(cred.user!.uid, {
                                'name': _namaController.text,
                                'nik': _nikController.text,
                                'phone': _hpController.text,
                                'photo_url': null, // 2. Foto profil kosongkan saja
                              });
                              if (context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomePage(),
                                  ),
                                );
                              }
                            }
                          } on FirebaseAuthException catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Gagal mendaftar')));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052A3), // blue button
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Footer text
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: 'Sudah punya akun? ',
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                        children: [
                          TextSpan(
                            text: 'Masuk',
                            style: TextStyle(
                              color: Color(0xFF0052A3),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
        prefixIcon: Icon(prefixIcon, color: Colors.black54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
