

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart' show Settings;
import 'package:get/get.dart';
import 'package:unchainedplayer/utility/constants.dart';

class ThemeUtils {

  ThemeUtils._();

  static bool get darkMode => _tm2b(ThemeMode.values[Settings.getValue<int>(SettingKeys.THEME_MODE, ThemeMode.system.index)]) == Brightness.dark;

  static void setThemeMode(ThemeMode mode){
    Brightness brightness;


    if(brightness == Brightness.light){
      Get.changeTheme(selectedLightTheme);
    }
    else{
      Get.changeTheme(selectedDarkTheme);
    }
  }

  static ThemeData get selectedLightTheme {
    int variant = Settings.getValue<int>(SettingKeys.LIGHT_THEME_VARIANT, 1);
    int hue = Settings.getValue<int>(SettingKeys.THEME_COLOR_HUE, 206);

    if(variant == 0){
      return generateAccentedLightTheme(hue.toDouble());
    }
    else{
      return generateBichromaticTheme(hue.toDouble(), false);
    }
  }

  static ThemeData get selectedDarkTheme {
    int variant = Settings.getValue(SettingKeys.DARK_THEME_VARIANT, 1);
    int hue = Settings.getValue<int>(SettingKeys.THEME_COLOR_HUE, 206);

    if(variant == 0){
      return generateAccentedDarkTheme(hue.toDouble());
    }
    else{
      return generateBichromaticTheme(hue.toDouble(), true);
    }
  }

  static ThemeData generateAccentedLightTheme(double hue){
    Color mainColor = HSVColor.fromAHSV(1, hue, 88.6 / 100, 44 / 100).toColor();
    MaterialColor primarySwatch = MaterialColor(mainColor.value, _generateMaterialColors(mainColor));

    return ThemeData(
      primarySwatch: primarySwatch
    );
  }

  static ThemeData generateBichromaticTheme(double hue, bool darkMode){
    Color mainColor = HSVColor.fromAHSV(1, hue, (!darkMode ? 34.84 : 88.6) / 100, (!darkMode ? 95 : 44) / 100).toColor();
    Color accentColor = HSVColor.fromAHSV(1, hue, (darkMode ?  34.84 : 88.6) / 100, (darkMode ? 95 : 44) / 100).toColor();

    MaterialColor primaryColor = MaterialColor(mainColor.value, _generateMaterialColors(mainColor));
    MaterialColor accentMaterialColors = MaterialColor(accentColor.value, _generateMaterialColors(accentColor));

    final ThemeData _default = ThemeData(brightness: darkMode ? Brightness.dark : Brightness.light);

    return ThemeData(
      primarySwatch: primaryColor,
      accentColor: accentColor,
      canvasColor: mainColor,
      dividerColor: accentColor.withAlpha(200),
      cursorColor: accentColor,
      brightness: darkMode ? Brightness.dark : Brightness.light,
      dialogTheme: DialogTheme(
        backgroundColor: mainColor,
        titleTextStyle: _default.textTheme.headline6.copyWith(color: accentColor, fontSize: 24)
      ),
      toggleableActiveColor: accentColor,
      textSelectionHandleColor: accentColor,
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: accentColor.withOpacity(0.5),
        thumbColor: accentColor,
      ),
      iconTheme: IconThemeData(
          color: accentColor
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: accentMaterialColors,
        unselectedItemColor: accentMaterialColors.withOpacity(0.5),
        backgroundColor: mainColor,
      ),
      cardTheme: CardTheme(
          color: primaryColor[600],
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 4),
          clipBehavior: Clip.hardEdge
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        color: mainColor,
        iconTheme: IconThemeData(
          color: accentColor
        ),
        actionsIconTheme: IconThemeData(
          color: accentColor
        )
      ),
    );
  }

  static ThemeData generateAccentedDarkTheme(double hue){
    Color accent = HSVColor.fromAHSV(1, hue, 34.84 / 100, 95 / 100).toColor();
    return ThemeData.dark().copyWith(
      accentColor: accent
    );
  }

  //region Helpers

  static Brightness _tm2b(ThemeMode mode){
    if(mode == ThemeMode.system){
      return Get.mediaQuery.platformBrightness;
    }
    else if(mode == ThemeMode.light){ return Brightness.light;}
    else{ return Brightness.dark; }

  }

  static Map<int, Color> _generateMaterialColors(Color baseColor){
    final Map<int, Color> colors = { 500: baseColor };
    const Color white = Colors.white; //Multiplied for the lighter colors
    final Color dark = _multiplyColors(baseColor, Colors.black);
    //Generate the lightest color; 50
    colors[50] = _multiplyColors(white, baseColor, 0.12);
    colors[100] = _multiplyColors(white, baseColor, 0.30);
    colors[200] = _multiplyColors(white, baseColor, 0.50);
    colors[300] = _multiplyColors(white, baseColor, 0.70);
    colors[400] = _multiplyColors(white, baseColor, 0.85);
    //Colors[500] is the base color
    colors[600] = _multiplyColors(dark, baseColor, 0.87);
    colors[700] = _multiplyColors(dark, baseColor, 0.70);
    colors[800] = _multiplyColors(dark, baseColor, 0.54);
    colors[900] = _multiplyColors(dark, baseColor, 0.39);
    return colors;
  }



  static Color _multiplyColors(Color color1, Color color2, [double colorMult = 1.0]){
    return Color.fromRGBO(
        ((color2.red - color1.red) * colorMult).floor() + color1.red,
        ((color2.green - color1.green) * colorMult).floor() + color1.green,
        ((color2.blue - color1.blue) * colorMult).floor() + color1.blue,
        1.0);
  }
  //endregion

}