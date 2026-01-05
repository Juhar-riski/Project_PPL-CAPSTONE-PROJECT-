import 'package:shared_preferences/shared_preferences.dart';

/// Helper class untuk mengelola session user
class UserSession {
  // 🔹 Get User ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  // 🔹 Get User Name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  // 🔹 Get User NIM
  static Future<String?> getUserNim() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userNim');
  }

  // 🔹 Get User Email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  // 🔹 Get User Phone
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPhone');
  }

  // 🔹 Get All User Data
  static Future<Map<String, String?>> getUserData() async {
    return {
      'userId': await getUserId(),
      'userName': await getUserName(),
      'userNim': await getUserNim(),
      'userEmail': await getUserEmail(),
      'userPhone': await getUserPhone(),
    };
  }

  // 🔹 Check if User Logged In
  static Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }

  // 🔹 Logout - Clear all user data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userNim');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
  }

  // 🔹 Update User Data (jika ada perubahan)
  static Future<void> updateUserData({
    String? name,
    String? email,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString('userName', name);
    if (email != null) await prefs.setString('userEmail', email);
    if (phone != null) await prefs.setString('userPhone', phone);
  }
}