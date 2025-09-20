import 'package:crypto/crypto.dart';
import 'dart:convert';

class MasterKeyService {
  static const String _masterKeyHash = "14dd0014c26d361c6d3cb09480d915f4b12f28ef1a95d90ce5a48f27da739b8d";

  bool verifyMasterKey(String inputKey) {
    final bytes = utf8.encode(inputKey);
    final digest = sha256.convert(bytes);
    return digest.toString() == _masterKeyHash;
  }
}