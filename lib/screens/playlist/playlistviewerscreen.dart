import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unchainedplayer/controllers/audio_master.dart';
import 'package:unchainedplayer/screens/medialist/medialist.dart';
import 'package:unchainedplayer/types/audio_cursor.dart';
import 'package:unchainedplayer/types/audio_playlist.dart';
import 'package:unchainedplayer/utility/extensions.dart';

class PlaylistViewerScreen extends StatefulWidget {

  final List<AudioPlaylist> playlists;

  PlaylistViewerScreen({@required this.playlists});

  @override
  _PlaylistViewerScreenState createState() => _PlaylistViewerScreenState();
}

class _PlaylistViewerScreenState extends State<PlaylistViewerScreen> {

  static const double ITEM_HEIGHT = 60;

  AudioMasterController audioMaster = Get.find();

  @override
  Widget build(BuildContext context) {

    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("My Playlists"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              String newName = await _displayPlaylistNameDialog(context, widget.playlists);
              if(newName != null){
                AudioPlaylist newPlaylist = AudioPlaylist(title: newName);
                await audioMaster.addNewUserPlaylist(newPlaylist);
                await AudioPlaylist.writePlaylistsToDisk();
              }
            },
          )
        ],
      ),
      body: widget.playlists.length == 0 ? Center(child: Text("You don't have any playlists")) :
        ListView.builder(
          itemCount: widget.playlists.length,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemBuilder: (BuildContext context, int index){
            AudioPlaylist playlist = widget.playlists[index];
            return Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ITEM_HEIGHT / 2)
              ),
              child: InkWell(

                onTap: (){
                  Get.to(MediaListScreen.playlist(playlist: playlist));
                },

                onLongPress: () async {
                  await _showDetailsDialog(context, playlist);
                },

                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: ITEM_HEIGHT / 2, top: 8, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(playlist.name,
                              style: theme.textTheme.headline6,
                            ),
                            const SizedBox(height: 2),
                            Text("${playlist.length} item${playlist.length == 1 ? "" : "s"} | ${_getRuntimeStr(playlist)}",
                              style: theme.textTheme.caption,
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(ITEM_HEIGHT / 2),
                        color: theme.accentColor,
                      ),
                      width: ITEM_HEIGHT,
                      height: ITEM_HEIGHT,
                      child: IconButton(
                        icon: Icon((audioMaster.playbackState?.playing ?? false) && audioMaster.currentPlaylist == playlist ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        color: theme.primaryColor,
                        iconSize: 40,
                        onPressed: (){
                          if(audioMaster.playbackActive){
                            if(audioMaster.currentPlaylist == playlist){
                              if(audioMaster.playbackState.playing){
                                AudioService.pause();
                              }
                              else{
                                AudioService.play();
                              }
                            }
                            else{
                              audioMaster.playPlaylistItem(playlist, 0);
                            }
                          }
                          else{
                            audioMaster.playPlaylistItem(playlist, 0);
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        )
    );
  }

  Future<String> _displayPlaylistNameDialog(BuildContext context, List<AudioPlaylist> otherPlaylists) async {

    String playlistName = await showDialog<String>(
      context: context,
      builder: (BuildContext context){
        return _PlaylistNameDialog(otherPlaylists: otherPlaylists);
      }
    );

    return playlistName;
  }

  Future<void> _showDetailsDialog(BuildContext context, AudioPlaylist playlist) async {
    Widget _makeText(String text, {TextStyle style}){
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Text(
          text,
          style: style != null ? style.merge(TextStyle(fontSize: 16)) : TextStyle(fontSize: 16),
        ),
      );
    }

    return await showDialog<void>(
      context: context,
      builder: (BuildContext context){
        return SimpleDialog(
          children: [
            SimpleDialogOption(
              child: _makeText("Play"),
              onPressed: () {
                audioMaster.playPlaylistItem(playlist, 0);
                Navigator.of(context).pop();
              },
            ),
            SimpleDialogOption(
              child: _makeText("Export Playlist"),
              onPressed: Navigator.of(context).pop,
            ),
            SimpleDialogOption(
              child: _makeText("Delete Playlist"),
              onPressed: () async {
                await audioMaster.deleteUserPlaylist(playlist);
                await AudioPlaylist.writePlaylistsToDisk();
                Navigator.of(context).pop();
              },
            )
          ],
        );
      }
    );
  }
  
  String _getRuntimeStr(AudioPlaylist playlist){
    return playlist.fold<Duration>(Duration.zero, (Duration previous, AudioCursor element) => previous + element.duration).runtimeString;
  }
}

//region stupid stateful just to dispose texteditor

class _PlaylistNameDialog extends StatefulWidget {

  final List<AudioPlaylist> otherPlaylists;

  _PlaylistNameDialog({@required this.otherPlaylists});

  @override
  __PlaylistNameDialogState createState() => __PlaylistNameDialogState();
}

class __PlaylistNameDialogState extends State<_PlaylistNameDialog> {

  TextEditingController _textEditor;

  @override
  void initState() {
    super.initState();
    _textEditor = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("New Playlist"),
      actions: [
        FlatButton(
          child: Text("Cancel"),
          onPressed: Navigator.of(context).pop,
        ),
        FlatButton(
          child: Text("Accept"),
          onPressed: (){
            if(_validateText(_textEditor.text) == null){
              Navigator.of(context).pop(_textEditor.text);
            }
          },
        )
      ],
      content: TextFormField(
        controller: _textEditor,
        autofocus: true,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: _validateText,
        decoration: InputDecoration(
            hintText: "Playlist Name"
        ),
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.words,
        onFieldSubmitted: (String value){
          if(_validateText(value) == null){
            Navigator.of(context).pop(value);
          }
        },
      ),
    );
  }

  String _validateText(String val){
    String trimVal = val.trim();
    if(trimVal == ""){
      return "Please input a playlist name";
    }
    else if(widget.otherPlaylists.any((AudioPlaylist element) => element.name.toLowerCase() == trimVal.toLowerCase())){
      return "Playlist Already Exists";
    }
    else{ return null; }
  }

  @override
  void dispose() {
    _textEditor.dispose();
    super.dispose();
  }
}


//endregion