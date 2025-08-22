import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordService {
  static const String _passwordHashKey = 'password_hash';
  static const String _saltKey = 'password_salt';

  Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    
    await prefs.setString(_passwordHashKey, hash);
    await prefs.setString(_saltKey, salt);
  }

  Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_passwordHashKey);
    final salt = prefs.getString(_saltKey);
    
    if (storedHash == null || salt == null) {
      return false;
    }
    
    final hash = _hashPassword(password, salt);
    return hash == storedHash;
  }

  Future<bool> isPasswordSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_passwordHashKey);
  }

  Future<void> clearPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordHashKey);
    await prefs.remove(_saltKey);
  }

  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  String _hashPassword(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64.decode(salt);
    final combined = [...passwordBytes, ...saltBytes];
    
    final digest = sha256.convert(combined);
    return digest.toString();
  }
}