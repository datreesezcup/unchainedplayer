
import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:unchainedplayer/globals.dart';
import 'package:unchainedplayer/types/audio_playlist.dart';
import 'package:unchainedplayer/types/audio_cursor.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:get/get.dart';
import 'package:unchainedplayer/utility/constants.dart';

class AudioMasterController extends GetxController {

  static const UID_LENGTH = 8;

  bool _serviceIsStarted = false;

  AudioPlaylist _currentPlaylist;
  AudioPlaylist get currentPlaylist => _currentPlaylist;

  List<MediaItem> _currentMediaQueue;
  List<MediaItem> get currentMediaQueue => _currentMediaQueue;

  PlaybackState _playbackState;
  PlaybackState get playbackState => _playbackState;

  ///Whether playback of the player is considered "active"
  bool get playbackActive {
    return audioProcessingState.index >= AudioProcessingState.ready.index && audioProcessingState.index < AudioProcessingState.stopped.index;
  }

  MediaItem _mediaItem;
  MediaItem get mediaItem => _mediaItem;

  int _currentQueueIndex;
  int get currentQueueIndex => _currentMediaQueue?.indexWhere((element) => element.id == _mediaItem?.id) ?? -1;

  AudioProcessingState _processingState;
  //If a media item exists, then at least show we're connecting to it.
  AudioProcessingState get audioProcessingState => _processingState ?? AudioProcessingState.none;

  StreamSubscription<PlaybackState> _playbackStateStream;

  StreamSubscription<MediaItem> _mediaItemStream;

  StreamSubscription<List<MediaItem>> _mediaQueueStream;

  StreamSubscription<dynamic> _customEventStream;

  StreamController<bool> _playbackActiveStreamController;
  Stream<bool> get playbackActiveStream => _playbackActiveStreamController.stream;

  Stream<Duration> get positionStream => AudioService.positionStream;

  void _maybeTriggerCustomStream(){
    _playbackActiveStreamController.add(_mediaItem != null);
  }

  Map<String, dynamic> _getSettingsValues(){
    return {
      SettingKeys.AUDIO_FADE_DURATION: Settings.getValue<double>(SettingKeys.AUDIO_FADE_DURATION, 0.200),
      SettingKeys.STOP_MEDIA_ON_APP_KILL: Settings.getValue<bool>(SettingKeys.STOP_MEDIA_ON_APP_KILL, true)
    };
  }

  @override
  void onInit(){
    super.onInit();
    _ensureServiceStarted();
    _playbackActiveStreamController = StreamController<bool>();
  }

  Future<void> _ensureServiceStarted() async {
    if(_serviceIsStarted){ return; }
    _serviceIsStarted = true;


    await AudioService.start(
        backgroundTaskEntrypoint: _audioServiceEntryPoint,
        androidEnableQueue: true,
        androidArtDownscaleSize: const Size(256, 256),
        params: {
          "masterPlaylist": AudioPlaylist.masterPlaylist.toJson(),
          "userPlaylists": AudioPlaylist.userPlaylists.map<Map<String, dynamic>>((AudioPlaylist e) => e.toJson()).toList(),
          "settings": _getSettingsValues()
        }
    );

    /*if(wasRunning) {
      _mediaItem = AudioService.currentMediaItem;
      _currentMediaQueue = AudioService.queue;
      _playbackState = AudioService.playbackState;
      _processingState = AudioService.playbackState?.processingState ?? AudioProcessingState.none;
      update();
    }*/

    _mediaItemStream = AudioService.currentMediaItemStream.listen((MediaItem newItem) {
      _mediaItem = newItem;
      update(
          //["miniPlayer", "player"]
      );
      _maybeTriggerCustomStream();
    });

    _mediaQueueStream = AudioService.queueStream.listen((List<MediaItem> queue) {
      _currentMediaQueue = queue;
      update(
        //["queue"]
      );
    });


    _playbackStateStream = AudioService.playbackStateStream.listen((PlaybackState newState) {
      _playbackState = newState;
      _processingState = newState?.processingState;
      if(audioProcessingState == AudioProcessingState.none){
        _serviceIsStarted = false;
        _processingState = null;
        _currentPlaylist = null;
        _playbackState = null;
        _currentQueueIndex = null;
        _currentMediaQueue = null;
        _mediaItem = null;
        _closeSubscriptions();
      }
      update(
        //["player", "miniPlayer"]
      );
      _maybeTriggerCustomStream();
    });

    _customEventStream = AudioService.customEventStream.listen((dynamic event) {
      Map<String, dynamic> params = Map<String, dynamic>.from(event);
      String method = params["method"];
      if(method == "updateQueueIndex"){
        int newIndex = params["value"];
        _currentQueueIndex = newIndex;
        update();
      }
    });
  }

  Future<void> preparePlaylist(AudioPlaylist playlist, {int initialIndex=0}) async {
    await _ensureServiceStarted();
    _currentPlaylist = playlist;
    await AudioService.prepareFromMediaId("${playlist.id}|$initialIndex");
  }

  Future<void> playPlaylistItem(AudioPlaylist playlist, [int index=0]) async {
    await _ensureServiceStarted();
    if(playlist.id != _currentPlaylist?.id){
      await preparePlaylist(playlist, initialIndex: index);
    }
    await AudioService.skipToQueueItem(playlist[index].id);
    AudioService.play();
  }

  Future<void> addCursorToMasterPlaylist(AudioCursor cursor) async {
    bool didAdd = AudioPlaylist.masterPlaylist.add(cursor);
    if(didAdd && _serviceIsStarted){
      await AudioService.customAction("updatePlaylist", AudioPlaylist.masterPlaylist.toJson());
    }
    update();
  }

  Future<void> removeCursorFromMasterPlaylist(AudioCursor cursor) async {
    bool didRemove = AudioPlaylist.masterPlaylist.remove(cursor.id);
    for(AudioPlaylist p in AudioPlaylist.userPlaylists){
      p.remove(cursor.id);
    }

    if(didRemove && _serviceIsStarted){
      await AudioService.customAction("updatePlaylists", AudioPlaylist.masterPlaylist.toJson());
    }
    update();
  }

  Future<void> addNewUserPlaylist(AudioPlaylist playlist) async {
    AudioPlaylist.userPlaylists.add(playlist);
    if(_serviceIsStarted){
      await AudioService.customAction("updatePlaylist", playlist.toJson());
    }
    update();
  }

  Future<void> deleteUserPlaylist(AudioPlaylist playlist) async {
    AudioPlaylist.userPlaylists.removeWhere((element) => element.id == playlist.id);
    if(_serviceIsStarted){
      await AudioService.customAction("deleteUserPlaylist", playlist.id);
    }
    update();
  }

  Future<void> addCursorToUserPlaylist(AudioPlaylist playlist, AudioCursor cursor) async {
    bool didAdd = playlist.add(cursor);
    if(didAdd && _serviceIsStarted){
      await AudioService.customAction("updatePlaylist", playlist.toJson());
    }
    update();
  }

  Future<void> removeCursorsFromUserPlaylist(AudioPlaylist playlist, List<AudioCursor> cursors) async {
    int numChanged = 0;
    for(AudioCursor c in cursors) {
      numChanged += (playlist.remove(c.id) ? 1 : 0);
    }
    if(numChanged > 0 && _serviceIsStarted){
      await AudioService.customAction("updatePlaylist", playlist.toJson());
    }
    update();
  }

  Future<void> modifySaveAudioCursor(AudioCursor newCursorData) async {
    int masterIndex = AudioPlaylist.masterPlaylist.indexOf(newCursorData.id);
    AudioPlaylist.masterPlaylist[masterIndex].set(
      title: newCursorData.title,
      artist: newCursorData.artist,
      album: newCursorData.album,
      thumbnail: newCursorData.thumbnail,
      clipStart: newCursorData.clipStart,
      clipEnd: newCursorData.clipEnd
    );

    await AudioPlaylist.writePlaylistsToDisk();
    if(_serviceIsStarted){
      await AudioService.updateMediaItem(newCursorData.asMediaItem());
    }

    update();
  }

  Future<void> reorderItems(AudioPlaylist playlist, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      //newIndex -= 1;
    }
    final AudioCursor item = playlist.removeAt(oldIndex);
    playlist.insert(newIndex, item);
    await AudioPlaylist.writePlaylistsToDisk();
    if(_serviceIsStarted){
      await AudioService.customAction("reorder", {"playlistID": playlist.id, "old": oldIndex, "new": newIndex});
    }

    update();
  }

  @override
  void dispose() {
    _closeSubscriptions();
    _playbackActiveStreamController.close();
    super.dispose();
  }

  static String generateRandomID([int seed]){
    const chars = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
    var r = Random(seed);
    StringBuffer buffer = StringBuffer();
    for(int i = 0; i < UID_LENGTH; i++){
      buffer.write(chars[r.nextInt(chars.length)]);
    }

    return buffer.toString();
  }

  Future<void> _closeSubscriptions() async {
    await _playbackStateStream?.cancel();
    await _mediaItemStream?.cancel();
    await _mediaQueueStream?.cancel();
    await _customEventStream?.cancel();
  }
}

void _audioServiceEntryPoint() => AudioServiceBackground.run(() => AudioBackgroundTask());


///Custom Task for running background audio, based heavily on
///[https://github.com/ryanheise/audio_service/blob/master/example/lib/main.dart#L314](https://github.com/ryanheise/audio_service/blob/master/example/lib/main.dart#L314)
class AudioBackgroundTask extends BackgroundAudioTask {

  static AudioPlayer _player;
  static AudioPlayer get player {
    if(_player == null){
      _player = AudioPlayer();
    }
    return _player;
  }

  bool _isReorganizing = false;

  List<MediaItem> __cq = List<MediaItem>();
  List<MediaItem> get _currentQueue => __cq;
  int get _currentIndex => player.currentIndex;
  MediaItem get _currentMediaItem => _currentIndex == null ? null : _currentQueue[_currentIndex];

  Map<String, dynamic> _behaviorSettings;

  AudioPlaylist _masterPlaylist;

  Map<String, AudioPlaylist> _userPlaylists;

  AudioPlaylist _currentPlaylist;

  AudioProcessingState _skipState;

  ConcatenatingAudioSource _currentAudioSourceList;

  //region Stream Subscriptions
  StreamSubscription<PlaybackEvent> _playbackEventStream;
  StreamSubscription<bool> _shuffleEnabledStream;
  StreamSubscription<LoopMode> _loopModeStream;
  StreamSubscription<SequenceState> _sequenceStateStream;
  StreamSubscription<int> _indexStream;
  StreamSubscription<ProcessingState> _processingStateStream;
  //endregion


  Map<String, String> _lastError;

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    try {
      print("Starting Audio Service with ${params.length} params");
      print("Params Check 2: ${params.containsKey("masterPlaylist")}");
      if (params.length > 0) {
        if (params.containsKey("masterPlaylist")) {
          _masterPlaylist = AudioPlaylist.fromJson(params["masterPlaylist"]);
          print("MASTER Length: ${_masterPlaylist.length}");
        }

        if (params.containsKey("userPlaylists")) {
          List<dynamic> userLists = List<dynamic>.from(params["userPlaylists"]);
          List<AudioPlaylist> list = userLists.map<AudioPlaylist>((e) =>
              AudioPlaylist.fromJson(e)).toList();
          _userPlaylists = Map<String, AudioPlaylist>.fromIterable(list,
              key: (dynamic pl) => (pl as AudioPlaylist).id,
              value: (dynamic pl) => pl as AudioPlaylist
          );
        }

        AudioPlaylist.linkCursorReferences(
            _masterPlaylist, _userPlaylists.values.toList());
      }
      else {
        List<AudioPlaylist> lists = await AudioPlaylist.loadPlaylists();
        _masterPlaylist = lists.removeAt(0);
        _userPlaylists = Map<String, AudioPlaylist>.fromIterable(lists,
            key: (dynamic pl) => (pl as AudioPlaylist).id,
            value: (dynamic pl) => pl as AudioPlaylist
        );
      }

      await player.setLoopMode(LoopMode.all);
      await player.setShuffleModeEnabled(false);

      _playbackEventStream = player.playbackEventStream.listen((PlaybackEvent event) {
            if(_isReorganizing){ return; }
            if (event.processingState == ProcessingState.ready) {
              _skipState = null;
            }

            _broadcastState();
          });

      _loopModeStream = player.loopModeStream.listen((event) => _broadcastState());

      _shuffleEnabledStream = player.shuffleModeEnabledStream.listen((event) => _broadcastState());

      //Special handling for sequenceState b/c it contains index
      /*_sequenceStateStream = player.sequenceStateStream.listen((SequenceState state) {
            if (state?.currentIndex != null) {
              print("Setting Index to ${state.currentIndex}");
              AudioServiceBackground.setMediaItem(
                  _currentQueue[state.currentIndex]);
            }
            _broadcastState();
          });*/

      _indexStream = player.currentIndexStream.listen((int index) {
        if(_isReorganizing){ return; }
        if (index != null && _currentQueue.length > 0) {
          print("Setting Index to $index");
          AudioServiceBackground.setMediaItem(_currentQueue[index]);
          _broadcastState();
        }
      });
    } catch(e, s){
      _printMethodError("onStart", e, s);
    }
  }

  @override
  Future<void> onPlayFromMediaId(String mediaId) async {
    try {
      await onPrepareFromMediaId(mediaId);
      return onPlay();
    }
    catch(e, s){
      _printMethodError("onPlayFromMediaId", e, s);
    }
  }

  @override
  Future<void> onPlayMediaItem(MediaItem mediaItem) async {
    try {
      await _loadMedia(mediaItem);
      return onPlay();
    }
    catch(e, s){
      _printMethodError("onPlayMediaItem", e, s);
    }
  }
  
  @override
  Future<void> onPrepareFromMediaId(String mediaId) async {
    try {
      return _loadMediaFromId(mediaId);
    }
    catch(e, s){
      _printMethodError("onPrepareFromMediaId", e, s);
    }
  }

  @override
  Future<void> onSkipToPrevious() async {
    try{
      if(_currentIndex == 0){
        await player.seek(Duration.zero, index: _currentAudioSourceList.length - 1);
      }
      else{
        await player.seekToPrevious();
      }
    } catch(e, s){
      _printMethodError("onSkipToPrevious", e, s);
    }
  }
  
  @override
  Future<void> onPlay() async {
    try{
      player.play();
    }
    catch(e, s){
      _printMethodError("onPlay", e, s);
    }
  }

  @override
  Future<void> onSkipToNext() async {
    try{
      if(_currentIndex == _currentAudioSourceList.length - 1){
        await player.seek(Duration.zero, index: 0);
      }
      else{
        await player.seekToNext();
      }
    } catch(e, s){
      _printMethodError("onSkipToNext", e, s);
    }
  }

  @override
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) {
    return player.setShuffleModeEnabled(shuffleMode != AudioServiceShuffleMode.none);
  }

  @override
  Future<void> onSetRepeatMode(AudioServiceRepeatMode repeatMode) {
    return player.setLoopMode(
      repeatMode == AudioServiceRepeatMode.group ? LoopMode.all : LoopMode.one
    );
  }

  @override
  Future<void> onUpdateMediaItem(MediaItem mediaItem) async {
    try {
      if(_currentQueue != null) { //If we're NOT playing something this will be null
        int queueIndex = _currentQueue.indexWhere((element) =>
        element.id == mediaItem.id);
        if(queueIndex != -1){
          _currentQueue[queueIndex] = _currentQueue[queueIndex].copyWith(
              title: mediaItem.title,
              artist: mediaItem.artist,
              album: mediaItem.album,
              artUri: mediaItem.artUri
          );

          await AudioServiceBackground.setQueue(_currentQueue);
        }
      }

      int masterIndex = _masterPlaylist.indexOf(mediaItem.id);
      if(masterIndex != -1){
        _masterPlaylist[masterIndex].set(
          title: mediaItem.title,
          artist: mediaItem.artist,
          album: mediaItem.album,
          thumbnail: mediaItem.artUri.toString()
        );
      }

      if (_currentMediaItem?.id == mediaItem.id) {
        await AudioServiceBackground.setMediaItem(mediaItem);
      }
    }
    catch(e, s){
      _printMethodError("onUpdateMediaItem", e, s);
    }
  }

  @override
  Future<void> onStop() async {
    try {
      _skipState = AudioProcessingState.none;
      await _broadcastState();
      await player.dispose();

      await _playbackEventStream?.cancel();
      await _loopModeStream?.cancel();
      await _sequenceStateStream?.cancel();
      await _shuffleEnabledStream?.cancel();
      await _indexStream?.cancel();
      await _processingStateStream?.cancel();

      await super.onStop();
    }
    catch (e, s){
      _printMethodError("onStop", e, s);
    }
  }

  @override
  Future<void> onSeekTo(Duration position) async {
    try {
      player.seek(position);
    } catch(e, s){
      _printMethodError("onSeekTo", e, s);
    }
  }


  @override
  Future<void> onPause() async {
    try {
      player.pause();
    } catch(e, s){
      _printMethodError("onPause", e, s);
    }
  }

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    try {
      int index = _currentQueue.indexWhere((element) => element.id == mediaId);
      if (index == -1) {
        throw IndexError(index, _currentQueue, "onSkipToQueueItem", "Could not find media with ID: $mediaId", _currentQueue.length);
      }

      _skipState = index > _currentIndex
          ? AudioProcessingState.skippingToNext
          : AudioProcessingState.skippingToPrevious;
      await player.seek(Duration.zero, index: index);
      await AudioServiceBackground.setMediaItem(_currentMediaItem);
    }
    catch(e, s){
      _printMethodError("onSkipToQueueItem", e, s);
    }
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> queue) async {
    try {
      return AudioServiceBackground.setQueue(queue);
    }
    catch(e, s){
      _printMethodError("onUpdateQueue", e, s);
    }
  }


  @override
  Future<dynamic> onCustomAction(String method, dynamic params) async {
    try {
      switch (method) {
        case "updatePlaylist":
          AudioPlaylist play = AudioPlaylist.fromJson(params);
          await _updatePlaylistRelations(play);
          return null;
        case "reorder":
          Map<String, dynamic> prms = Map<String, dynamic>.from(params);
          String playlistID = prms["playlistID"];
          int oldIndex = prms["old"] as int;
          int newIndex = prms["new"] as int;
          if(playlistID == AudioPlaylist.MASTER_PLAYLIST_ID){
            _masterPlaylist.reorder(oldIndex, newIndex);
          }
          else{
            _userPlaylists[playlistID].reorder(oldIndex, newIndex);
          }

          if(_currentPlaylist?.id == playlistID){
            await _currentAudioSourceList.move(oldIndex, newIndex);
          }
          break;
        case "addCursorToMaster":
          AudioCursor c = AudioCursor.fromJson(params);
          _masterPlaylist.add(c);
          if (_currentPlaylist.id == AudioPlaylist.MASTER_PLAYLIST_ID) {
            await _currentAudioSourceList.add(_coaxSingleAudioCursor(c));
            await onUpdateQueue(_masterPlaylist.toMediaItemList());
          }
          return null;
        case "removeCursorFromMaster":
          String cursorID = params as String;
          if (_currentPlaylist.id == AudioPlaylist.MASTER_PLAYLIST_ID) {
            await _currentAudioSourceList.removeAt(_masterPlaylist.indexOf(cursorID));
          }
          _masterPlaylist.remove(cursorID);
          if (_currentPlaylist.id == AudioPlaylist.MASTER_PLAYLIST_ID) {
            await onUpdateQueue(_masterPlaylist.toMediaItemList());
          }
          return null;
        case "addNewUserPlaylist":
          AudioPlaylist newPlaylist = AudioPlaylist.fromJson(params);
          _userPlaylists[newPlaylist.id] = newPlaylist;
          return null;
        case "deleteUserPlaylist":
          String playlistID = params as String;

          /*If we delete the playlist we're currently playing, we
          have to switch the playlist to the master playlist,
          and inject all the media items before and after the
          current one into the ConcatenatingAudioSource. (We can't
          do player.load() since that would stop audio;
          */
          if(playlistID == _currentPlaylist.id){
            String _currentMediaId = _currentMediaItem.id;
            int indexOfMaster = _masterPlaylist.indexOf(_currentMediaId);
            List<AudioCursor> beforeThisItems = _masterPlaylist.items.sublist(0, indexOfMaster);
            List<AudioCursor> afterThisItems = _masterPlaylist.items.sublist(indexOfMaster + 1);

            //Now to strip the audio sources from our queue.
            await _currentAudioSourceList.removeRange(0, _currentIndex);
            await _currentAudioSourceList.removeRange(_currentIndex + 1, _currentAudioSourceList.length);

            await _currentAudioSourceList.insertAll(0, beforeThisItems.map<AudioSource>(_coaxSingleAudioCursor).toList());
            await _currentAudioSourceList.insertAll(_currentIndex + 1, afterThisItems.map<AudioSource>(_coaxSingleAudioCursor).toList());

            //Update the queue
            await AudioServiceBackground.setQueue(_masterPlaylist.toMediaItemList());
          }

          _userPlaylists.remove(playlistID);
          return null;
        case "addCursorToUser":
          Map<String, dynamic> prms = Map<String, dynamic>.from(params);
          String pID = prms["playlistID"];
          AudioCursor c = AudioCursor.fromJson(prms["cursor"]);
          AudioPlaylist pl = _userPlaylists[pID];
          int playlistIndex = pl.indexOf(c.id);
          pl[playlistIndex] = c;
          if (_currentPlaylist.id == pID) {
            AudioService.updateQueue(pl.toMediaItemList());
            _currentAudioSourceList.add(_coaxSingleAudioCursor(c));
          }
          return null;
        case "removeCursorFromUser":
          Map<String, dynamic> data = Map<String, dynamic>.from(params);
          String pID = data["playlistID"];
          String cursorID = data["cursorID"];
          AudioPlaylist targetPlaylist = _userPlaylists[pID];
          if (_currentPlaylist.id == pID) {
            await _currentAudioSourceList.removeAt(
                _currentPlaylist.indexOf(cursorID));
          }
          targetPlaylist.remove(cursorID);
          if (_currentPlaylist.id == pID) {
            await onUpdateQueue(targetPlaylist.toMediaItemList());
          }
          return null;
        default:
          return null;
      }
    }
    catch(e, s){
      _printMethodError("onCustomEvent", e, s);
    }
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {

    _currentQueue.add(mediaItem);
    await _currentAudioSourceList.add(_coaxSingleMediaItem(mediaItem));
    await AudioServiceBackground.setQueue(_currentQueue);

    /*String playlist = mediaItem.extras["playlist"];
    AudioCursor cursor = AudioCursor.fromJson(mediaItem.extras["cursor"]);
    if(playlist == AudioPlaylist.MASTER_PLAYLIST_ID){
      _masterPlaylist.add(cursor);
    }
    else{
      _userPlaylists[playlist].add(cursor);
    }

    if(_currentPlaylist.id == playlist){

    }*/
  }

  @override
  Future<void> onAddQueueItemAt(MediaItem mediaItem, int index) async {

    _currentQueue.insert(index, mediaItem);
    await _currentAudioSourceList.insert(index, _coaxSingleMediaItem(mediaItem));
    await AudioServiceBackground.setQueue(_currentQueue);

    /*String playlist = mediaItem.extras["playlist"];
    AudioCursor cursor = AudioCursor.fromJson(mediaItem.extras["cursor"]);
    if(playlist == AudioPlaylist.MASTER_PLAYLIST_ID){
      _masterPlaylist.insert(index, cursor)
    }
    else{
      _userPlaylists[playlist].insert(index, cursor);
    }

    if(playlist == _currentPlaylist.id) {

    }*/
  }

  @override
  Future<void> onRemoveQueueItem(MediaItem mediaItem) async {
    int index = _currentQueue.indexOf(mediaItem);
    if(_currentMediaItem.id == mediaItem.id){
      await onSkipToNext();
    }
    await _currentAudioSourceList.removeAt(index);
    await AudioServiceBackground.setQueue(_currentQueue);
  }

  @override
  Future<List<MediaItem>> onLoadChildren(String parentMediaId) async {
    List<AudioPlaylist> playlists = await AudioPlaylist.loadPlaylists();
    if(parentMediaId == AudioService.MEDIA_ROOT_ID || parentMediaId == AudioPlaylist.MASTER_PLAYLIST_ID){
      return playlists[0].toMediaItemList();
    }
    else{
      int index = playlists.indexOf(AudioPlaylist(title: null, id: parentMediaId));
      return playlists[index].toMediaItemList();
    }
  }

  //region internal

  Future<void> _broadcastState() async {
    try {
      await AudioServiceBackground.setState(
          controls: [
            MediaControl.skipToPrevious,
            if (player.playing ?? false) MediaControl.pause else
              MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: [
            MediaAction.seekTo,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          ],
          processingState: _getProcessingState(),
          androidCompactActions: const [0, 1, 3],
          playing: player.playing,
          position: player.position,
          bufferedPosition: player.bufferedPosition,
          speed: player.speed,
          shuffleMode: _transformShuffleMode(player.shuffleModeEnabled),
          repeatMode: _transformRepeatMode(player.loopMode)
      );
    }catch(e, s){
      _printMethodError("_broadcastState", e, s);
    }
  }
  
  AudioServiceShuffleMode _transformShuffleMode(bool shuffleEnabled){
    return (shuffleEnabled ?? false) ? AudioServiceShuffleMode.group : AudioServiceShuffleMode.none;
  }
  
  AudioServiceRepeatMode _transformRepeatMode(LoopMode loopMode){
    switch(loopMode){
      case LoopMode.off:
        return AudioServiceRepeatMode.none;
      case LoopMode.one:
        return AudioServiceRepeatMode.one;
      case LoopMode.all:
        return AudioServiceRepeatMode.group;
      default:
        return AudioServiceRepeatMode.group;
    }
  }

  AudioProcessingState _getProcessingState() {
    try {
      if (_skipState != null) return _skipState;
      switch (player.processingState) {
        case ProcessingState.idle:
          return AudioProcessingState.stopped;
        case ProcessingState.loading:
          return AudioProcessingState.connecting;
        case ProcessingState.buffering:
          return AudioProcessingState.buffering;
        case ProcessingState.ready:
          return AudioProcessingState.ready;
        case ProcessingState.completed:
          return AudioProcessingState.completed;
        default:
          print("BAD PROCESSING STATE: ${player.processingState}");
          throw Exception("Invalid state: ${_player.processingState}");
      }
    }catch(e, s){
      _printMethodError("_getProccessingState", e, s);
      return AudioProcessingState.error;
    }
  }

  Future<void> _loadMedia(MediaItem item) async {
    try{
      if(item.playable){ throw Exception("_loadMedia must be called with playlists [playable=false]"); }
      AudioPlaylist playlist;
      if(item.id == AudioPlaylist.MASTER_PLAYLIST_ID){
        playlist = _masterPlaylist;
      }
      else{
        playlist = _userPlaylists[item.id];
      }

      int index = item.extras["index"];
      _currentPlaylist = playlist;
      __cq = playlist.toMediaItemList();
      await AudioServiceBackground.setQueue(_currentQueue);
      _currentAudioSourceList = ConcatenatingAudioSource(
        children: _currentQueue.map<AudioSource>((MediaItem item) => _coaxSingleMediaItem(item)).toList(),
        useLazyPreparation: true
      );
      return player.setAudioSource(_currentAudioSourceList, initialIndex: index);
    }catch(e, s){
      _printMethodError("_loadMedia", e, s);
    }
  }

  Future<void> _loadMediaFromId(String mediaId) async {
    if(mediaId.startsWith("playlist:")){
      List<String> splits = mediaId.split("|");
      String id = splits[0];
      int index = int.tryParse(splits[1]) ?? 0;
      await _loadMedia(MediaItem(id: id, album: null, title: "PLTS", playable: false, extras: {"index": index})); //Only the playlist ID is needed.
      return;
    }
    else{
      _printMethodError("_loadMediaFromId", Exception("_loadMediaFromId should not ever be called with a standalone mediaitem now..."), null);
    }
  }


  //endregion

  Future<void> _updatePlaylistRelations(AudioPlaylist playlist) async {

    _isReorganizing = true;

    if(_currentPlaylist != null && _currentPlaylist.id == playlist.id){
      //First check: does the new playlist contain what we're currently playing
      if(_currentPlaylist.contains(_currentMediaItem.id)){
        //Just for clarity sake, remove and re-add all items before and after this in queue.
        int sourcePlaylistIndex = playlist.indexOf(_currentMediaItem.id);
        var beforeItems =  await _currentAudioSourceList.removeRange(0, _currentIndex);
        var afterItems = await _currentAudioSourceList.removeRange(_currentIndex + 1, _currentAudioSourceList.length);

        var newBeforeItems = playlist.sublist(0, sourcePlaylistIndex);
        var newAfterItems = playlist.sublist(sourcePlaylistIndex + 1, playlist.length);
        await _currentAudioSourceList.insertAll(0, newBeforeItems.map(_coaxSingleAudioCursor).toList());
        await _currentAudioSourceList.addAll(newAfterItems.map(_coaxSingleAudioCursor).toList());

        __cq = playlist.toMediaItemList();
        await AudioServiceBackground.setQueue(__cq);

      }
      else{
        if(playlist.id != AudioPlaylist.MASTER_PLAYLIST_ID){
          //Swap to the master playlist
          int masterPlaylistIndex = _masterPlaylist.indexOf(_currentMediaItem.id);
          var newBeforeItems = _masterPlaylist.sublist(0, masterPlaylistIndex);
          var newAfterItems = _masterPlaylist.sublist(masterPlaylistIndex + 1, _masterPlaylist.length);
          await _currentAudioSourceList.insertAll(0, newBeforeItems.map(_coaxSingleAudioCursor).toList());
          await _currentAudioSourceList.addAll(newAfterItems.map(_coaxSingleAudioCursor).toList());
          _currentPlaylist = _masterPlaylist;
        }
        else{
          //Don't do anything for now, we'll let the current item play/loop
        }
      }
    }

    if(playlist.id == AudioPlaylist.MASTER_PLAYLIST_ID){
      _masterPlaylist = playlist;
    }
    else{
      _userPlaylists[playlist.id] = playlist;
    }

    _isReorganizing = false;
  }

  AudioSource _coaxSingleAudioCursor(AudioCursor target){
    String path = target.filePath;
    if(path.startsWith("http")){
      return AudioSource.uri(Uri.parse(path));
    }
    else{
      AudioSource baseSource = AudioSource.uri(Uri.file(path));
      int clipStart = target.clipStart;
      int clipEnd = target.clipEnd;
      if(clipEnd - clipStart != target.milisecondsDuration){
        return ClippingAudioSource(child: baseSource,
            start: Duration(milliseconds: clipStart),
            end: Duration(milliseconds: clipEnd)
        );
      }
      else{
        return baseSource;
      }
    }
  }

  AudioSource _coaxSingleMediaItem(MediaItem target){
    String path = target.extras["path"];
    if(path.startsWith("http")){
      return AudioSource.uri(Uri.parse(path));
    }
    else{
      AudioSource baseSource = AudioSource.uri(Uri.file(path));
      int clipStart = target.extras["clipStart"] ?? 0;
      int clipEnd = target.extras["clipEnd"] ?? -1;
      if(clipEnd != -1){
        return ClippingAudioSource(child: baseSource,
            start: Duration(milliseconds: clipStart),
            end: Duration(milliseconds: clipEnd)
        );
      }
      else{
        return baseSource;
      }
    }
  }

  void _printMethodError(String method, dynamic e, dynamic s){
    _skipState = AudioProcessingState.error;
    _lastError = {"exception": e.toString(), "stack": s.toString() };
    print("[BackgroundAudioTask.$method] EXCEPTION: $e\nSTACK TRACE: $s");
    _broadcastState();
  }

}
