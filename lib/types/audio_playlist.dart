import 'dart:collection';
import 'dart:convert';
import 'package:meta/meta.dart';

import 'package:audio_service/audio_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:unchainedplayer/controllers/audio_master.dart';
import 'package:unchainedplayer/globals.dart';
import 'package:unchainedplayer/types/audio_interfaces.dart';
import 'package:unchainedplayer/types/mediasource/baseMediaSource.dart';
import 'package:unchainedplayer/types/mediasource/youtubesource.dart';
import 'dart:io';
import 'audio_cursor.dart';
import 'package:http/http.dart' as http;

class AudioPlaylist with ListMixin<AudioCursor> {

  static AudioPlaylist _masterPlaylist;
  static AudioPlaylist get masterPlaylist => _masterPlaylist;

  static List<AudioPlaylist> _userPlaylists;
  static List<AudioPlaylist> get userPlaylists => _userPlaylists;

  static const String MASTER_PLAYLIST_ID = "playlist:0MASTER0";


  AudioPlaylist({@required String title, String id, List<AudioCursor> items}) :
        _name = title,
        _id = id ?? "playlist:${AudioMasterController.generateRandomID()}",
        _items = items ?? List<AudioCursor>(),
        _tracker = (items ?? []).map<String>((AudioCursor c) => c.id).toSet();

  String _name;
  String get name => _name;
  set name(String newName) => _name = newName;

  String _id;
  String get id => _id;

  List<AudioCursor> _items;
  ///Return a COPY of the items in this [AudioPlaylist]
  List<AudioCursor> get items => _items.toList(growable: false);
  Set<String> _tracker;

  int get length => _items.length;

  set length(int newLength){
    if(newLength >= length){
      _items.length = newLength;
    }
    else{
      _items.removeRange(length-newLength, length);
      Set<String> remainingKeys = _items.map<String>((AudioCursor c) => c.id).toSet();
      _tracker = remainingKeys;
    }
  }

  @override
  bool add(AudioCursor cursor){
    if(_tracker.contains(cursor.id)) { return false; }
    if(this.id == MASTER_PLAYLIST_ID){
      _items.insert(0, cursor);
    }
    else {
      _items.add(cursor);
    }
    return true;
  }

  @override
  void addAll(Iterable<AudioCursor> iterable){
    Set<String> missingKeys = _tracker.difference(iterable.map<String>((AudioCursor e) => e.id).toSet());
    Iterable<AudioCursor> keepCursors = iterable.where((element) => missingKeys.contains(element.id));
    _tracker.addAll(missingKeys);
    if(this.id == MASTER_PLAYLIST_ID){
      _items.insertAll(0, iterable);
    }
    else{
      _items.addAll(keepCursors);
    }
  }

  @override
  void insert(int index, AudioCursor element){
    if(!_tracker.contains(element.id)){
      _items.insert(index, element);
    }
  }

  @override
  Iterator<AudioCursor> get iterator {
    return _items.iterator;
  }

  @override
  bool remove(dynamic cursorData){
    if(cursorData is String || cursorData is AudioCursor){
      int index = indexOf(cursorData);
      if(index != -1){
        AudioCursor c = removeAt(index);
        _tracker.remove(c.id);
        return true;
      }
      else { return false; }
    }
    else{
      throw UnimplementedError("AudioPlaylist.remove");
    }
  }

  @override
  AudioCursor removeAt(int index){
    AudioCursor removed = _items.removeAt(index);
    _tracker.remove(removed.id);
    return removed;
  }

  void reorder(int oldIndex, int newIndex){
    assert(newIndex >= 0 && newIndex < length, "newIndex must be within the playlist bounds");
    AudioCursor c = removeAt(oldIndex);
    insert(newIndex, c);
  }

  @override
  int indexOf(dynamic cursorData, [int start=0]){
    if(cursorData is String){
      return _items.indexWhere((element) => element.id == cursorData, start);
    }
    else if(cursorData is AudioCursor){
      return _items.indexOf(cursorData, start);
    }
    else{
      throw UnimplementedError("AudioPlaylist.indexOf");
    }
  }

  bool contains(dynamic variable){
    if(variable is String){
      return _tracker.contains(variable);
    }
    else if(variable is AudioCursor){
      return _tracker.contains(variable.id);
    }
    else{
      throw UnimplementedError("Contains must be called with a String or AudioCursor");
    }
  }


  AudioCursor operator [](int index){
    return _items[index];
  }

  void operator []= (int index, AudioCursor item){
    _items[index] = item;
  }

  static Future<List<AudioPlaylist>> loadPlaylists() async {
    //print((await getApplicationDocumentsDirectory()).path);
    Directory baseDir = await getExternalStorageDirectory();
    File masterPlaylistFile = File(path.join(baseDir.path, "playlists.json"));
    AudioPlaylist _master;
    List<AudioPlaylist> _users;
    if(await masterPlaylistFile.exists()){
      String data = await masterPlaylistFile.readAsString();
      List<Map<String, dynamic>> rawLists = List<Map<String, dynamic>>.from(jsonDecode(data)).toList();
      List<AudioPlaylist> playlists = rawLists.map<AudioPlaylist>((e) => AudioPlaylist.fromJson(e)).toList();
      print(playlists);
      _master = playlists.removeAt(0); //first playlist is always the master
      _users = playlists;
    }
    else{
      AudioPlaylist newMasterPlaylist = AudioPlaylist(title: "All Media", id: MASTER_PLAYLIST_ID);
      List<AudioPlaylist> playlists = [newMasterPlaylist];
      await masterPlaylistFile.writeAsString(jsonEncode(playlists));
      _master = newMasterPlaylist;
      _users = List<AudioPlaylist>();
    }

    return [_master]..addAll(_users);
  }

  static void setGlobalPlaylists(AudioPlaylist master, [List<AudioPlaylist> userPlaylists]){
    _masterPlaylist = master;
    _userPlaylists = userPlaylists ?? List<AudioPlaylist>();

    linkCursorReferences(master, userPlaylists);
  }

  factory AudioPlaylist.fromJson(dynamic json){
    String name = json["name"];
    String id = json["id"];
    List<dynamic> dynamicLists = List<dynamic>.from(json["items"] ?? const []);
    List<Map<String, dynamic>> rawLists = dynamicLists.map<Map<String, dynamic>>((dn) => Map<String,dynamic>.from(dn)).toList();
    List<AudioCursor> cursors = rawLists.map<AudioCursor>((Map<String, dynamic> item) => AudioCursor.fromJson(item)).toList();
    return AudioPlaylist(title: name, id: id, items: cursors);
  }

  MediaItem asMediaItem(){
    return MediaItem(
      id: id,
      title: name,
      album: "Playlist",
      playable: false
    );
  }

  List<MediaItem> toMediaItemList(){
    return _items.map<MediaItem>((AudioCursor c) => c.asMediaItem()).toList();
  }

  Map<String, dynamic> toJson(){
    return {
      "name": name,
      "id": id,
      "items": _items.map<Map<String, dynamic>>((AudioCursor c) => c.toJson()).toList()
    };
  }

  @override
  bool operator ==(Object other){
    return other is AudioPlaylist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString(){
    return toJson().toString();
  }


  static Map<String, AudioCursor> cursorListToMap(List<AudioCursor> list){
    return Map<String, AudioCursor>.fromIterable(list,
        key: (dynamic k) => (k as AudioCursor).id, value: (dynamic v) => v as AudioCursor
    );
  }

  static Future<void> writePlaylistsToDisk() async {
    Directory baseDir = await getExternalStorageDirectory();
    File masterPlaylistFile = File(path.join(baseDir.path, "playlists.json"));
    List<AudioPlaylist> lists = [masterPlaylist]..addAll(userPlaylists);
    List<Map<String, dynamic>> jsonList = lists.map<Map<String, dynamic>>((AudioPlaylist e) => e.toJson()).toList();
    String rawString = jsonEncode(jsonList);
    await masterPlaylistFile.writeAsString(rawString);
  }

  ///Replace "duplicate" [AudioCursor] references in [children] with the
  ///reference to the [AudioCursor] in the [master] playlist
  static void linkCursorReferences(AudioPlaylist master, Iterable<AudioPlaylist> children){
    for(AudioPlaylist playlist in children){
      for(int i = 0; i < playlist.length; i++){
        AudioCursor child = playlist[i];
        int masterIndex = master.indexOf(child.id);
        if(masterIndex != -1){
          playlist[i] = master[masterIndex];
        }
      }
    }
  }

}