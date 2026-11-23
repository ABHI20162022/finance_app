import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupHelper {
  /// Exports all SharedPreferences keys/values into a JSON backup file
  /// and opens the share/save dialog (WhatsApp, Drive, Files, etc.).
  static Future<String> exportBackupFile() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> backupMap = {};

    for (final key in prefs.getKeys()) {
      backupMap[key] = prefs.get(key);
    }

    final payload = {
      'app': 'finance_app',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': backupMap,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/finance_app_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Finance App Backup ($timestamp)',
    );

    return file.path;
  }

  /// Picks a .json backup file and restores all saved keys into SharedPreferences.
  static Future<bool> importBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return false;
    }

    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map) {
      throw const FormatException('Invalid backup file format');
    }

    final Map<String, dynamic> dataMap =
        Map<String, dynamic>.from(decoded['data'] as Map);
    final prefs = await SharedPreferences.getInstance();

    for (final entry in dataMap.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is List) {
        await prefs.setStringList(
          key,
          value.where((e) => e != null).map((e) => e.toString()).toList(),
        );
      }
    }

    return true;
  }
}