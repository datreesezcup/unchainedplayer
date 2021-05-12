import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:unchainedplayer/globals.dart';
import 'dart:io';
import 'package:unchainedplayer/types/audio_cursor.dart';
import 'package:unchainedplayer/types/audio_playlist.dart';
import 'package:unchainedplayer/types/mediasource/youtubesource.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' show DownloadProgress;

export 'youtubesource.dart';
export 'package:flutter_cache_manager/src/result/download_progress.dart';



abstract class IndirectCursorSource {

  Future<AudioCursor> prepareCursor(IndirectAudioCursor cursor);

}

abstract class IRequiresPreparationForSearch {

  Future<void> prepareSearch(String query);

}


class SearchedVideoProvider<SourceVideoType> {

  String _query;
  String get query => _query;

  int _currPage;
  int get currentPage => _currPage;

  List<AudioCursor> lastRequestResult;

  dynamic _tracker;
  dynamic get tracker => _tracker;

  Future<List<SourceVideoType>> Function(String query, int page, dynamic tracker) _nextPageFunc;

  Future<List<AudioCursor>> getNextPage() async {
    List<SourceVideoType> results = await _nextPageFunc(_query, _currPage, _tracker);
    _currPage += 1;
    lastRequestResult = results.map<AudioCursor>(_convertSourceVideoType).toList();
    return lastRequestResult;
  }

  SearchedVideoProvider({@required String query, @required List<AudioCursor> firstPageResult, int page, dynamic tracker}){
    _query = query;
    _currPage = page ?? 1;
    lastRequestResult = firstPageResult;
    _tracker = tracker;
  }

  void setPageGetterFunction(Future<List<SourceVideoType>> Function(String query, int page, dynamic tracker) getPage){
    _nextPageFunc = getPage;
  }

  void setVideoTypeConvertFunc(AudioCursor Function(SourceVideoType vid) convertFunc){
    _convertSourceVideoType = convertFunc;
  }

  AudioCursor Function(SourceVideoType video) _convertSourceVideoType;

}

abstract class MediaSource {

  static const Map<String, MediaSource> sources = {
    "youtube": YoutubeMediaSource()
  };

  String get name;
  String get id => name.toLowerCase().replaceAll(" ", "");

  bool get hasAutoComplete;

  Future<List<String>> getAutoCompleteSuggestions(String query);

  const MediaSource();

  Future<SearchedVideoProvider> getVideosForSearch(String query);

  //Future<AudioCursor> prepareCursor(AudioCursor indirect);

  Stream<DownloadProgress> downloadMedia(AudioCursor onlineCursor,
  {
    void Function(AudioCursor endFile) onDownloadComplete,
    void Function(dynamic error) onError
  }) async* {
    if(!onlineCursor.filePath.startsWith("http")){
      onDownloadComplete(onlineCursor);
      return;
    }

    AudioCursor targetCursor;
    if(this is IndirectCursorSource){
      assert(onlineCursor is IndirectAudioCursor, "Must be an Indirect Cursor");
      targetCursor = await (this as IndirectCursorSource).prepareCursor(onlineCursor);
    }
    else{
      targetCursor = onlineCursor;
    }

    try {
      //StreamController<DownloadProgress> _progressController = StreamController<DownloadProgress>();

      /*
      http.Request request = http.Request(
          "GET", Uri.parse(onlineCursor.filePath));

      request.headers["Keep-Alive"] = "timeout=240, max=2000";
      request.headers["Connection"] = "Keep-Alive";
      http.StreamedResponse streamedResponse = await request.send();

      List<int> receivedBytes = [];
      int contentLength = streamedResponse.contentLength;
      await for (List<int> bytes in streamedResponse.stream) {
        receivedBytes += bytes;
        yield DownloadProgress(
            onlineCursor.filePath, contentLength, receivedBytes.length);
      }
       */
      http.Response response = await http.get(Uri.parse(targetCursor.filePath));/*http.Response.bytes(
          receivedBytes, streamedResponse.statusCode,
          request: streamedResponse.request,
          headers: streamedResponse.headers,
          isRedirect: streamedResponse.isRedirect,
          persistentConnection: streamedResponse.persistentConnection,
          reasonPhrase: streamedResponse.reasonPhrase
      );*/

      String filetype = response.headers["content-type"].split("/")[1];
      File endpoint = File(path.join(
          Globals.baseDirectory.path, onlineCursor.provider,
          "${onlineCursor.id}.$filetype"));
      await endpoint.create(recursive: true);
      AudioCursor newCursor = onlineCursor.copyWith(
          filePath: endpoint.path
      );

      await endpoint.writeAsBytes(response.bodyBytes);
      onDownloadComplete(newCursor);
    }
    catch(e){
      onError(e);
    }
  }
}