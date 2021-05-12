import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:unchainedplayer/types/audio_interfaces.dart';

class AudioCursor {

  final String provider;

  String _title;
  String get title => _title;

  final String id;

  final String sourceID;

  String _artist;
  String get artist => _artist;

  String _album;
  String get album => _album;

  String _thumbnail;
  String get thumbnail => _thumbnail;

  final String filePath;

  final int milisecondsDuration;

  int _clipStart;
  int get clipStart => _clipStart;

  int _clipEnd;
  int get clipEnd => _clipEnd;

  Duration get trueDuration => Duration(milliseconds: milisecondsDuration);

  Duration get duration {
    return Duration(milliseconds: _clipEnd - _clipStart);
  }
  String get durationString {
    int totalSeconds = duration.inSeconds;
    int minutes = (totalSeconds / 60).floor();
    int remainingSeconds = totalSeconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, "0")}";

  }

  final DateTime uploadDate;
  String get uploadDateString {
    return "${uploadDate.month}-${uploadDate.day}-${uploadDate.year}";
  }

  AudioCursor({this.sourceID, String title, String artist, String album, this.uploadDate, String thumbnail, this.provider, this.filePath, this.milisecondsDuration,
      int clipStart, int clipEnd}) :
        _title = title, _artist = artist, _album = album, _thumbnail = thumbnail, _clipStart = clipStart ?? 0, _clipEnd = clipEnd ?? milisecondsDuration,
        this.id = hashList([provider, sourceID]).toString();

  factory AudioCursor.fromJson(dynamic json){
    return AudioCursor(
      sourceID: json["sourceID"],
      title: json["title"],
      artist: json["artist"],
      album: json["album"],
      provider: json["provider"],
      filePath: json["filepath"],
      thumbnail: json["thumbnail"],
      milisecondsDuration: json["duration"],
      clipStart: json["clipStart"],
      clipEnd: json["clipEnd"],
      uploadDate: DateTime.tryParse(json["uploadDate"] ?? "") ?? DateTime(1970)
    );
  }

  AudioCursor copyWith({String title, String artist, String album, String filePath, String thumbnail, DateTime uploadDate, int duration,
    int clipStart, int clipEnd
  }){
    return AudioCursor(
      sourceID: this.sourceID,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      provider: this.provider,
      filePath: filePath ?? this.filePath,
      thumbnail: thumbnail ?? this.thumbnail,
      uploadDate:  uploadDate ?? this.uploadDate,
      milisecondsDuration: duration ?? this.milisecondsDuration,
      clipStart: clipStart ?? this._clipStart,
      clipEnd: clipEnd ?? this._clipEnd
    );
  }

  void set({String title, String artist, String album, String thumbnail, int clipStart, int clipEnd}){
    if(title != null){ _title = title; }
    if(artist != null){ _artist = artist; }
    if(album != null){ _album = album; }
    if(thumbnail != null){ _thumbnail = thumbnail; }
    if(clipStart != null && clipEnd != null){ _clipStart = clipStart; _clipEnd = clipEnd; }
  }

  MediaItem asMediaItem(){
    return MediaItem(
      title: title,
      id: id,
      playable: true,
      artist: artist,
      artUri: Uri.parse(thumbnail),
      album: album ?? provider,
      duration: duration,
      extras: { "path": filePath, "clipStart": _clipStart, "clipEnd": _clipEnd }
    );
  }

  Map<String, dynamic> toJson(){
    return {
      "id": id,
      "sourceID": sourceID,
      "title": title,
      "artist": artist,
      "album": album,
      "provider": provider,
      "filepath": filePath,
      "thumbnail": thumbnail,
      "duration": milisecondsDuration,
      "uploadDate": uploadDate.toString(),
      "clipStart": _clipStart,
      "clipEnd": _clipEnd
    };
  }

}

///Defines an AudioCursor that points to a resource that will later be used
///to resolve a regular [AudioCursor].
///
/// An example is using an [IndirectAudioCursor] to point to a youtube video,
/// then later using that location to obtain the audio URL
class IndirectAudioCursor extends AudioCursor {

  IndirectAudioCursor({String sourceID, String title, String artist, String album, String provider, String filepath, String thumbnail, DateTime uploadDate, int duration}) :
      super(
        sourceID: sourceID,
        title: title,
        artist: artist,
        album: album,
        provider: provider,
        filePath: filepath,
        thumbnail: thumbnail,
        milisecondsDuration: duration,
        uploadDate: uploadDate
      );

  factory IndirectAudioCursor.fromJson(Map<String, dynamic> json){
    return IndirectAudioCursor(
      sourceID: json["sourceID"],
      title: json["title"],
      album: json["album"],
      artist: json["artist"],
      provider: json["provider"],
      filepath: json["filename"],
      thumbnail: json["thumbnail"],
      duration: json["duration"],
      uploadDate: json["upload"]
    );
  }

  Map<String, dynamic> toJson(){
    return {
      "title": title,
      "id": id,
      "sourceID": sourceID,
      "artist": artist,
      "album": album,
      "provider": provider,
      "filepath": filePath,
      "thumbnail": thumbnail,
      "duration": milisecondsDuration
    };
  }

} //literally just a blank definition to track later.