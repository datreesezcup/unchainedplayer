import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:unchainedplayer/controllers/audio_master.dart';
import 'package:unchainedplayer/globals.dart';
import 'package:unchainedplayer/screens/settings/app_settings_screen.dart';
import 'package:unchainedplayer/types/audio_playlist.dart';
import 'package:unchainedplayer/screens/medialist/medialist.dart';
import 'package:unchainedplayer/screens/medialist/search_screen.dart';
import 'package:unchainedplayer/screens/medialist/widgets/mediaListItem.dart';
import 'screens/mediaplayer/mediaplayerscreen.dart';
import 'package:unchainedplayer/screens/playlist/playlistviewerscreen.dart';
import 'package:unchainedplayer/utility/constants.dart';
import 'package:unchainedplayer/utility/themeutils.dart';
import 'package:we_slide/we_slide.dart';
import 'types/mediasource/youtubesource.dart';
import 'package:get/get.dart';
import 'types/audio_cursor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Globals.init();
  List<AudioPlaylist> playlists = await AudioPlaylist.loadPlaylists();
  AudioPlaylist _master = playlists.removeAt(0);
  AudioPlaylist.setGlobalPlaylists(_master, playlists);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  MyApp({Key key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Unchained Music Player',
      themeMode: ThemeMode.values[Settings.getValue<int>(SettingKeys.THEME_MODE, ThemeMode.system.index)],
      theme: ThemeUtils.selectedLightTheme,
      darkTheme: ThemeUtils.selectedDarkTheme,
      home: AudioServiceWidget(
        child: MyHomePage(),
      ),
    );
  }


}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  TextEditingController controller;
  
  AudioMasterController master = Get.put(AudioMasterController());


  WeSlideController _slideController = WeSlideController();

  PageController _pageController = PageController(
    initialPage: 1,
  );

  int bBarIndex = 1;

  bool _playerActive = false;

  StreamSubscription<bool> _playerActiveStream;

  @override
  void initState() {
    super.initState();
    Get.lazyPut(() => MediaSearchController());
    _playerActiveStream = master.playbackActiveStream.listen((bool active) {
      if(_slideController.isOpened && !active){
        _slideController.hide();
      }
      setState(() {
        _playerActive = active;

      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if(_slideController.isOpened){
          _slideController.hide();
          return false;
        }
        else{ return true; }
      },
      child: Material(
        child: _buildWeSlidePanel(context)
      ),
    );
  }

  @override
  void dispose(){
    _playerActiveStream.cancel();
    super.dispose();
  }

  Widget _buildWeSlidePanel(BuildContext context){
    return WeSlide(
      controller: _slideController,
      panelMinSize: kBottomNavigationBarHeight + (_playerActive ? 100 : 0),
      panelMaxSize: MediaQuery.of(context).size.height,
      panelHeader: GestureDetector(

        onTap: _slideController.show,

        child: MiniMediaPlayerWidget(),
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (int newPage){
          setState(() {
            bBarIndex = newPage;
          });
        },
        children: [
          MediaSearchScreen(),
          Scaffold(
            appBar: AppBar(
              title: Text("My Media"),
              actions: [
                IconButton(
                  icon: Icon(Icons.stop),
                  onPressed: (){
                    AudioService.stop();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: (){
                    Get.to(AppSettingsScreen());
                  },
                ),
              ],
            ),
            body: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: AudioPlaylist.masterPlaylist.length,
              itemBuilder: (BuildContext context, int index){
                AudioCursor cursor = AudioPlaylist.masterPlaylist[index];


                return GestureDetector(
                  onTap: (){
                    master.playPlaylistItem(AudioPlaylist.masterPlaylist, index);
                  },
                  child: MediaListItem(
                    source: cursor,
                    isSaved: true,
                    showCacheBarIfSaved: false,
                  ),

                );
              },
            ),
          ),
          PlaylistViewerScreen(
            playlists: AudioPlaylist.userPlaylists,
          )
        ],
      ),

      panel: MediaPlayerScreen(),
      footer: BottomNavigationBar(
        currentIndex: bBarIndex,
        elevation: 0,
        showUnselectedLabels: false,
        onTap: (int newVal){
          setState(() {
            bBarIndex = newVal;
            _pageController.animateToPage(newVal,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut
            );
          });
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search_rounded),
              label: "Search"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.music_note_outlined),
              activeIcon: Icon(Icons.music_note_rounded),
              label: "Media"
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.playlist_play_outlined),
              activeIcon: Icon(Icons.playlist_play_rounded),
              label: "Playlists"
          )
        ],
      ),
    );
  }
}
