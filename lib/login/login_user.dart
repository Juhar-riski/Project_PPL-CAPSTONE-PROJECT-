import 'package:flutter/material.dart';
import 'package:app_unigive/login/login_admin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'regist.dart';
import '../home/homepage.dart';

class LoginUser extends StatefulWidget {
  const LoginUser({super.key});

  @override
  State<LoginUser> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginUser> with SingleTickerProviderStateMixin {
  final TextEditingController nimUserController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String parseErrorMessage(dynamic message) {
  if (message == null) return "Terjadi kesalahan";

  if (message is List) {
    return message.join(", ");
  }

  if (message is String) {
    return message;
  }

  return message.toString();
}

  
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

    // Check if user already logged in
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    nimUserController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 🔹 Check if user already logged in
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    
    if (userId != null) {
      // User sudah login, langsung ke homepage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  // 🔹 Fungsi login ke API
  Future<void> handleLogin() async {
    // Validasi input
    if (nimUserController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIM dan Password harus diisi!'),
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
        Uri.parse('http://10.0.2.2:4000/api/loginUsers'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nim': nimUserController.text,
          'password': passwordController.text,
        }),
      );


      setState(() {
        loading = false;
      });

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (_) {
        responseData = {
          "message": "Response server tidak valid",
        };
      }
      
      if (response.statusCode == 200) {
        if (responseData['status'] == 'success' && responseData['data'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', responseData['data']['id'].toString());
          await prefs.setString('userName', responseData['data']['name']);
          await prefs.setString('userNim', responseData['data']['nim'].toString());
          await prefs.setString('userEmail', responseData['data']['email']);
          await prefs.setString(
            'userPhone',
            responseData['data']['numberPhone']?.toString() ?? '',
          );
          
      
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login berhasil! Selamat datang ${responseData['data']['name']}',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
      
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                parseErrorMessage(responseData['message']),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              parseErrorMessage(responseData['message']),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
          // 🔹 Latar belakang
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg1.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔹 Logo Universitas di pojok kiri atas
          Positioned(
            top: 40,
            left: 20,
            child: Image.asset(
              'assets/uniLogo.png',
              height: 60,
            ),
          ),

          // 🔹 Form login di tengah
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: FadeTransition(
                opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/unig.png',
                      height: 250,
                      width: 250,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 0),

                    const Text(
                      "Login User",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: nimUserController,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "NIM",
                        prefixIcon: const Icon(Icons.person, color: Colors.green),
                        labelStyle: TextStyle(color: Colors.green.withOpacity(1)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock, color: Colors.green),
                        labelStyle: TextStyle(color: Colors.green.withOpacity(1)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: loading ? null : handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(110, 107, 11, 1),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
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
                              "Login",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 5),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't Have An Account?",
                          style: TextStyle(color: Colors.black),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegistPage()),
                            );
                          },
                          child: const Text(
                            "Register Here!",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Login As",
                          style: TextStyle(color: Colors.black),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginAdmin()),
                            );
                          },
                          child: const Text(
                            "Admin",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text.rich(
                        TextSpan(
                          text: "By clicking login, you agree to our ",
                          style: TextStyle(
                            color: Color.fromARGB(135, 35, 35, 35),
                            fontSize: 13,
                          ),
                          children: [
                            TextSpan(
                              text: "Terms of Service",
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
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
}