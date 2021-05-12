import 'package:flutter/material.dart';
import 'package:unchainedplayer/types/audio_cursor.dart';
import 'package:unchainedplayer/types/audio_interfaces.dart';
import 'package:unchainedplayer/types/mediasource/baseMediaSource.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:convert' show json;

export 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeMediaSource extends MediaSource implements IndirectCursorSource, IRequiresPreparationForSearch {

  @override
  String get name => "Youtube";

  @override
  bool get hasAutoComplete => true;

  const YoutubeMediaSource();

  static SearchList _memorizedStream;
  static String _lastQuery;

  static SearchList _searchList;

  @override
  Future<List<String>> getAutoCompleteSuggestions(String query) async {
    String url = "http://suggestqueries.google.com/complete/search?client=youtube&ds=yt&alt=json&q=${Uri.encodeComponent(query)}";
    var response = await http.get(Uri.parse(url));
    if(response.statusCode != 200){
      throw Exception("Bad status code: ${response.statusCode}");
    }

    String body = response.body;
    body = body.substring("window.google.ac.h(".length, body.length - 1);
    List<dynamic> allResults = json.decode(body);
    List<List<dynamic>> suggestionPairs = List<List<dynamic>>.from(List<dynamic>.from(allResults[1]));
    return suggestionPairs.map((List<dynamic> element) => element[0] as String).toList();
  }

  @override
  Future<AudioCursor> prepareCursor(IndirectAudioCursor indirect) async {
    var manifest = await YoutubeExplode().videos.streamsClient.getManifest(indirect.filePath);
    //var audioLists = manifest.audioOnly.sortByBitrate();

    return indirect.copyWith(
      filePath: manifest.audioOnly.withHighestBitrate().url.toString()//audioLists.elementAt(audioLists.length - 2).url.toString()
    );
  }

  @override
  Future<void> prepareSearch(String query) async {
    _searchList = await YoutubeExplode().search.getVideos(query);
  }

  AudioCursor _convertYoutubeVideotoUnchained(Video vid){
    return IndirectAudioCursor(
      title: vid.title,
      artist: vid.author,
      sourceID: vid.id.value,
      provider: name,
      duration: vid.duration.inMilliseconds,
      filepath: vid.id.value
    );
  }

  Future<SearchedVideoProvider<Video>> getVideosForSearch(String query) async {

    var searchList = await YoutubeExplode().search.getVideos(query);

    SearchedVideoProvider<Video> searchProvider = SearchedVideoProvider(
      query: query,
      firstPageResult: searchList.map<AudioCursor>(_convertYoutubeVideotoUnchained).toList(),
      tracker: searchList
    );

    searchProvider.setPageGetterFunction((query, page, tracker) {
      return (tracker as SearchList).nextPage() ?? [];
    });

    searchProvider.setVideoTypeConvertFunc(_convertYoutubeVideotoUnchained);

    List<Video> _vids;
    if(page == 1){
      _vids = _searchList.toList();
    }
    else{
      _vids = (await _searchList.nextPage()).toList();
    }

    return _vids.map((v) => IndirectAudioCursor(
        title: v.title,
        artist: v.author,
        sourceID: v.id.value,
        thumbnail: v.thumbnails.lowResUrl,
        uploadDate: v.uploadDate,
        provider: "youtube",
        filepath: v.url,
        duration: v.duration.inMilliseconds
    )).toList();


  }

  void printVideoData(Video data) async {
    var yt = YoutubeExplode();
    var manifest = await yt.videos.streamsClient.getManifest(data.id);
    var audioData = manifest.audioOnly.withHighestBitrate();
    print("[AUDIO:URL] ${audioData.url.toString()}");
    print("[AUDIO:CONTAINER] ${audioData.container.name}");
    print("[AUDIO:SIZE] ${audioData.size.totalMegaBytes} MB");
    print("[AUDIO:CODEC] ${audioData.audioCodec}");
    //yt.close();
  }
}

