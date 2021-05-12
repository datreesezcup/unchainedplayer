import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unchainedplayer/controllers/audio_master.dart';
import 'package:unchainedplayer/types/audio_playlist.dart';
import 'package:unchainedplayer/types/audio_cursor.dart';
import 'package:unchainedplayer/types/audio_interfaces.dart';
import 'package:unchainedplayer/types/mediasource/baseMediaSource.dart';
import 'package:unchainedplayer/widgets/easyDialog.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'widgets/mediaListItem.dart';

class MediaListScreen extends StatefulWidget {

  final AudioPlaylist playlist;

  final MediaSource cursorSource;

  MediaListScreen._({this.cursorSource, this.playlist});

  factory MediaListScreen.playlist({@required AudioPlaylist playlist}) {
    return MediaListScreen._(playlist: playlist);
  }

  factory MediaListScreen.sourceSearch({@required MediaSource source}){
    return MediaListScreen._(cursorSource: source);
  }


  @override
  _MediaListScreenState createState() {
    if(playlist != null){
      return _AudioPlaylistScreenState();
    }
    else{
      return _SourceSearchScreenState();
    }
  }
}

abstract class _MediaListScreenState extends State<MediaListScreen> {}

class _AudioPlaylistScreenState extends _MediaListScreenState {

  AudioMasterController audioMaster = Get.find();

  Set<String> _selectedItems = {};

  bool _inSelectionMode = false;
  bool get inSelectionMode => _inSelectionMode;

  bool _didMakeEdits = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async {
        if(_inSelectionMode){
          setState(() {
            _inSelectionMode = false;
            _selectedItems.clear();
          });

          return false;
        }
        else{

          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.playlist.name),
          actions: () sync* {
            if(inSelectionMode){
              if(_selectedItems.length > 0){
                yield IconButton(
                  icon: Icon(Icons.delete_rounded),
                  onPressed: () async {
                    List<AudioCursor> cursors = List<AudioCursor>();
                    for(int i = 0; i < _selectedItems.length; i++){
                      cursors.add(widget.playlist[i]);
                    }
                    await audioMaster.removeCursorsFromUserPlaylist(widget.playlist, cursors);
                  },
                );
              }

              yield IconButton(
                icon: Icon(Icons.check_rounded),
                onPressed: (){
                  setState(() {
                    _selectedItems.clear();
                    _inSelectionMode = false;
                  });
                },
              );
            }
            else{
              yield IconButton(
                icon: Icon(Icons.edit_rounded),
                onPressed: (){
                  setState(() {
                    _inSelectionMode = true;
                  });
                },
              );
            }
          }().toList(),
        ),
        body: (){
          if(widget.playlist.length == 0){
            if(widget.playlist.id == AudioPlaylist.masterPlaylist.id){
              return Center(
                child: Text("No Media saved to device. Search for some tunes!"),
              );
            }
            else{
              return Center(
                child: Text("This playlist is empty"),
              );
            }
          }
          return ListView.builder(
            itemCount: widget.playlist.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemBuilder: (BuildContext context, int index){
              final int i = index;
              AudioCursor cursor = widget.playlist[i];
              bool hasMediaSaved = AudioPlaylist.masterPlaylist.contains(cursor.id);

              return GestureDetector(

                onTap: () async {
                  if(!inSelectionMode){
                    await audioMaster.playPlaylistItem(widget.playlist, i);
                  }
                  else{
                    if(_selectedItems.contains(cursor.id)){
                      setState(() {
                        _selectedItems.remove(cursor.id);
                      });
                    }
                    else{
                      setState(() {
                        _selectedItems.add(cursor.id);
                      });
                    }
                  }
                },

                onLongPress: (){
                  if(!inSelectionMode){
                    Feedback.forLongPress(context);
                    setState(() {
                      _inSelectionMode = true;
                      _selectedItems.add(cursor.id);
                    });
                  }
                },

                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: _selectedItems.contains(cursor.id) ? Theme.of(context).accentColor.withAlpha(127) : null,
                  child: Row(
                    children: [
                      if(inSelectionMode)
                        _getSelectionModeColumn(context, index, widget.playlist.length),
                      Expanded(
                        child: MediaListItem(
                          source: cursor,
                          isSaved: hasMediaSaved,
                          showCacheBarIfSaved: false,
                          trailing: inSelectionMode ? SizedBox() : null,
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        }(),
      ),
    );
  }

  Widget _getSelectionModeColumn(BuildContext context, int thisIndex, int length){
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        width: 70,
        height: 120,
        child: Column(
          children: [
            Expanded(
              child: RaisedButton(
                  child: Icon(Icons.arrow_upward_rounded),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  onPressed: thisIndex == 0 ? null : () async {
                    await audioMaster.reorderItems(widget.playlist, thisIndex, thisIndex - 1);
                    setState(() {_didMakeEdits = true; });
                  },
                  visualDensity: VisualDensity.compact
              ),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: RaisedButton(
                  child: Icon(Icons.arrow_downward_rounded),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  onPressed: thisIndex == length - 1 ? null : () async {
                    await audioMaster.reorderItems(widget.playlist, thisIndex, thisIndex + 1);
                    setState(() {_didMakeEdits = true; });
                  },
                  visualDensity: VisualDensity.compact
              ),
            )
          ],
        )
    );
  }
}

class _SourceSearchScreenState extends _MediaListScreenState {


  PagingController<int, Video> _pagingController = PagingController(firstPageKey: 1);

  AudioMasterController audioMasterController = Get.find();

  void requestNextPage(int page) async {

  }

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(requestNextPage);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AudioCursor>>(
        stream: _cursorStream.stream,
        builder: (BuildContext context,
            AsyncSnapshot<List<AudioCursor>> snap) {
          if (snap.hasError) {
            return Center(
              child: Text("ERROR:\n${snap.error.toString()}"),
            );
          }
          else if (snap.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            );
          }
          else {
            return ListView.builder(
              itemCount: snap.data.length + (!_finishedLoading ? 1 : 0),
              padding: const EdgeInsets.all(8),
              itemBuilder: (BuildContext context, int index) {
                if(!_finishedLoading && index >= snap.data.length){
                  requestNextPage();
                  return CircularProgressIndicator();
                }
                IndirectAudioCursor cCursor = snap.data[index];
                bool hasMediaSaved = AudioPlaylist.masterPlaylist.contains(cCursor.id);


                return GestureDetector(

                  onTap: () async {
                    if(!hasMediaSaved) {
                      Stream<DownloadProgress> progStream = widget.cursorSource.downloadMedia(cCursor,
                          onDownloadComplete: _completeCursorDownload,
                          onError: (e){
                        Get.back();
                        print("DOWNLOAD ERROR: $e");
                      }
                      );

                      _showDownloadDialog(context, progStream);
                    }
                    else{
                      int index = AudioPlaylist.masterPlaylist.indexOf(cCursor.id);
                      audioMasterController.playPlaylistItem(AudioPlaylist.masterPlaylist, index);
                    }
                  },

                  child: MediaListItem(source: cCursor, isSaved: hasMediaSaved),
                );
              },
            );
          }
        }
    );
  }

  void _completeCursorDownload(AudioCursor cursor) async {
    await audioMasterController.addCursorToMasterPlaylist(cursor);
    await AudioPlaylist.writePlaylistsToDisk();
    await audioMasterController.playPlaylistItem(AudioPlaylist.masterPlaylist, AudioPlaylist.masterPlaylist.length - 1);
    Get.back();
  }

  @override
  void dispose() {
    _cursorStream.close();
    super.dispose();
  }

  Future<void> _showDownloadDialog(BuildContext context, Stream<DownloadProgress> progressStream){

    Widget _getView(double progress){
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(progress == null ? "Preparing Download" : progress < 1 ? "Downloading: ${(progress * 100).round()}%" :
              "Writing to device"
          ),
          LinearProgressIndicator(
            value: progress,
          )
        ],
      );
    }

    EasyDialog dialog = EasyDialog(
      title: Text("Downloading"),
      persistence: EasyDialog.PERSISTENCE_ALL,
      content: StreamBuilder<DownloadProgress>(
        stream: progressStream,
        builder: (BuildContext context, AsyncSnapshot<DownloadProgress> snapshot){
          if(snapshot.connectionState != ConnectionState.active){
            return _getView(null);
          }
          else{
            return _getView(snapshot.data.progress);
          }
        },
      ),
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context){
        return dialog;
      }
    );
  }
}
