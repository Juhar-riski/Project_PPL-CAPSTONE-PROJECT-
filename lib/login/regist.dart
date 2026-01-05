import 'package:flutter/material.dart';
import 'package:app_unigive/login/login_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegistPage extends StatefulWidget {
  const RegistPage({super.key});

  @override
  State<RegistPage> createState() => _RegistPageState();
}

class _RegistPageState extends State<RegistPage> with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  bool loading = false;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );

    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    nameController.dispose();
    nimController.dispose();
    emailController.dispose();
    noHpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // 🔹 Fungsi untuk registrasi ke API
  Future<void> handleRegister() async {
    // Validasi input
    if (nameController.text.isEmpty ||
        nimController.text.isEmpty ||
        emailController.text.isEmpty ||
        noHpController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi password match
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password dan Konfirmasi Password tidak sama!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validasi email format
    if (!emailController.text.contains('@mhs.unimal.ac.id')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email harus menggunakan domain @mhs.unimal.ac.id'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:4000/api/registUsers'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'name': nameController.text,
          'nim': nimController.text,
          'email': emailController.text,
          'numberPhone': noHpController.text,
          'password': passwordController.text,
        },
      );

      setState(() {
        loading = false;
      });

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success') {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registrasi berhasil! Selamat datang ${data['data']['name']}'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigasi ke halaman login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginUser()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Registrasi gagal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Terjadi kesalahan pada server'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🎓 Logo Universitas di pojok kiri atas
          Positioned(
            top: 40,
            left: 20,
            child: Image.asset(
              'assets/uniLogo.png',
              height: 60,
            ),
          ),

          // Konten Utama
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FadeTransition(
                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🔹 Logo UNIGIVE
                    Image.asset(
                      'assets/unig.png',
                      height: 250,
                      width: 250,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      "Registrasi",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🧾 Form Fields
                    _buildTextField("Nama", nameController),
                    const SizedBox(height: 14),
                    _buildTextField("NIM", nimController, keyboardType: TextInputType.number),
                    const SizedBox(height: 14),
                    _buildTextField("email@mhs.unimal.ac.id", emailController, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _buildTextField("No. Hp", noHpController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _buildTextField("Masukkan Password", passwordController, isPassword: true),
                    const SizedBox(height: 14),
                    _buildTextField("Konfirmasi Password", confirmPasswordController, isPassword: true),
                    const SizedBox(height: 25),

                    // 🟩 Tombol Registrasi
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(110, 107, 11, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: loading ? null : handleRegister,
                        child: loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Registrasi",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already Have An Account?",
                          style: TextStyle(color: Colors.black),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginUser()),
                            );
                          },
                          child: const Text(
                            "Login Here!",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),

                    // 📜 Terms & Privacy
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text.rich(
                        TextSpan(
                          text: "By clicking registrasi, you agree to our ",
                          style: TextStyle(
                            color: Color.fromARGB(135, 35, 35, 35),
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: "Terms of Service",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(text: " and "),
                            TextSpan(
                              text: "Privacy Policy",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // 📦 Helper widget untuk TextField
  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: Colors.green.withOpacity(1)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromRGBO(110, 107, 11, 1)),
        ),
      ),
    );
  }
}