import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:unchainedplayer/utility/constants.dart' show SettingKeys;
import 'package:get/get.dart';
import 'package:unchainedplayer/utility/themeutils.dart';

class AppSettingsScreen extends StatelessWidget {

  //region Radio Value Maps

  static const _appBrightnessMap = {
    0: "Follow System",
    1: "Light",
    2: "Dark"
  };

  static const _lightVariantMap = {
    0: "Traditional Light",
    1: "Bichromatic Light"
  };

  static const _darkVariantMap = {
    0: "Traditional Dark",
    1: "Bichromatic Dark"
  };

  //endregion

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(
      children: [
        SettingsGroup(
          title: "Appearance",
          children: [
            RadioModalSettingsTile<int>(
              title: "App Brightness",
              settingKey: SettingKeys.THEME_MODE,
              selected: ThemeMode.system.index,
              values: _appBrightnessMap,
              onChange: (int newValue){
                ThemeUtils.setThemeMode(ThemeMode.values[newValue]);
              },
            ),
            RadioModalSettingsTile<int>(
              title: "Light Theme Variant",
              settingKey: SettingKeys.LIGHT_THEME_VARIANT,
              selected: 1,
              values: _lightVariantMap,
              onChange: (int newVal){
                if(!ThemeUtils.darkMode){
                  if(newVal == 0){
                    Get.changeTheme(ThemeUtils.generateAccentedLightTheme(206));
                  }
                  else{
                    Get.changeTheme(ThemeUtils.generateBichromaticTheme(206, false));
                  }
                }
              },
            ),
            RadioModalSettingsTile<int>(
              title: "Dark Theme Variant",
              settingKey: SettingKeys.DARK_THEME_VARIANT,
              selected: 1,
              values: _darkVariantMap,
              onChange: (int newVal){
                if(ThemeUtils.darkMode){
                  if(newVal == 0){
                    Get.changeTheme(ThemeUtils.generateAccentedDarkTheme(206));
                  }
                  else{
                    Get.changeTheme(ThemeUtils.generateBichromaticTheme(206, true));
                  }
                }
              },
            )
          ],
        ),
        SettingsGroup(
          title: "Behavior",
          children: [
            SimpleSettingsTile(
              title: "Youtube",
              child: SettingsScreen(
                title: "Youtube",
                children: [],
              ),
            ),
            SliderSettingsTile(
              title: "Audio Fade Duration",
              min: 0,
              max: 1,
              step: 0.100,
              defaultValue: 0.200,
              settingKey: SettingKeys.AUDIO_FADE_DURATION,
              subtitle: "Sets the duration of the fading of audio when pausing/resuming audio",
            ),
            CheckboxSettingsTile(
              title: "Stop Media on App Kill",
              subtitle: "Stop the media player when the app is closed from \"Recents\"",
              settingKey: SettingKeys.STOP_MEDIA_ON_APP_KILL,
              defaultValue: true,
            )
          ],
        )
      ],
    );
  }
}
