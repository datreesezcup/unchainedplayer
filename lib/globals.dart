import 'dart:io';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
export 'package:flutter_settings_screens/src/settings.dart' show Settings;

class Globals {

  Globals._();

  static bool _hasInit;

  static Directory _baseDirectory;
  static Directory get baseDirectory => _baseDirectory;

  static Future<void> init() async {
    await Future.wait([
      _loadBaseDirectory(),
      _loadSettingsPreferences()
    ]);
  }

  static Future<void> _loadBaseDirectory() async {
    _baseDirectory = await getApplicationSupportDirectory();
  }

  static Future<void> _loadSettingsPreferences() async {
    await Settings.init();
  }

}