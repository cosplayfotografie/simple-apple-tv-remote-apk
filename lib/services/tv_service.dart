import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TvDevice {
  final String name;
  final String identifier;
  final String address;

  TvDevice({required this.name, required this.identifier, required this.address});

  factory TvDevice.fromJson(Map<String, dynamic> json) {
    return TvDevice(
      name: json['name'] ?? 'Unknown ATV',
      identifier: json['identifier'] ?? '',
      address: json['address'] ?? '',
    );
  }
}

class TvService {
  static const MethodChannel _channel = MethodChannel('com.example.apple_tv_remote/pyatv');

  Future<List<TvDevice>> scanDevices({String? manualIp}) async {
    try {
      final String resultJson = await _channel.invokeMethod('scan', {'ip': manualIp});
      if (resultJson.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(resultJson);
      return decoded.map((e) => TvDevice.fromJson(e)).toList();
    } catch (e) {
      print("Scan Error: $e");
      throw Exception(e.toString());
    }
  }

  Future<bool> connect(String identifier, {String? address}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final creds = prefs.getString('credentials_$identifier');
      
      if (creds == null || creds.isEmpty) {
        print("No credentials found, triggering pairing mode.");
        return false;
      }

      final bool result = await _channel.invokeMethod('connect', {
        'identifier': identifier,
        'address': address,
        'credentials': creds,
      });
      return result;
    } catch (e) {
      print("Connect Error: $e");
      return false;
    }
  }

  Future<bool> startPairing(String identifier, {String? address}) async {
    try {
      final bool result = await _channel.invokeMethod('startPairing', {
        'identifier': identifier,
        'address': address,
      });
      return result;
    } catch (e) {
      print("Start Pairing Error: $e");
      throw Exception(e.toString());
    }
  }

  Future<bool> finishPairing(String identifier, String pin) async {
    try {
      final String credentialsJson = await _channel.invokeMethod('finishPairing', {
        'pin': pin,
      });
      
      if (credentialsJson.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('credentials_$identifier', credentialsJson);
        return true;
      }
      return false;
    } catch (e) {
      print("Finish Pairing Error: $e");
      return false;
    }
  }

  Future<bool> sendCommand(String command) async {
    try {
      final bool result = await _channel.invokeMethod('sendCommand', {'command': command});
      return result;
    } catch (e) {
      print("Command Error: $e");
      return false;
    }
  }

  Future<bool> sendText(String text) async {
    try {
      final bool result = await _channel.invokeMethod('sendText', {'text': text});
      return result;
    } catch (e) {
      print("Keyboard Error: $e");
      return false;
    }
  }

  Future<List<Map<String, String>>> getApps() async {
    try {
      final String resultJson = await _channel.invokeMethod('getApps');
      if (resultJson.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(resultJson);
      return decoded.map((e) => {
        "name": e["name"].toString(),
        "identifier": e["identifier"].toString()
      }).toList();
    } catch (e) {
      print("Apps Error: $e");
      return [];
    }
  }

  Future<bool> launchApp(String identifier) async {
    try {
      final bool result = await _channel.invokeMethod('launchApp', {'identifier': identifier});
      return result;
    } catch (e) {
      print("Launch Error: $e");
      return false;
    }
  }
}
