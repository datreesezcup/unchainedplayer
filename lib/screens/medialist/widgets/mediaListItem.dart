import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unchainedplayer/controllers/audio_master.dart';
import 'package:unchainedplayer/screens/media_editor_screen.dart';
import 'package:unchainedplayer/types/audio_cursor.dart';
import 'package:unchainedplayer/types/audio_interfaces.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unchainedplayer/types/audio_playlist.dart';

class MediaListItem extends StatefulWidget {

  final AudioCursor source;

  final bool isSaved;

  final bool showCacheBarIfSaved;

  final Widget trailing;

  MediaListItem({@required this.source, this.isSaved=false, this.showCacheBarIfSaved=true, this.trailing});

  @override
  _MediaListItemState createState() => _MediaListItemState();
}

class _MediaListItemState extends State<MediaListItem> {

  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 120,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CachedNetworkImage(
                imageUrl: widget.source.thumbnail,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.passthrough,
                  alignment: Alignment.centerRight,
                  children: [
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                          padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
                          child: Text(
                            widget.source.title,
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                            style: Theme.of(context).textTheme.headline6.copyWith(
                                fontSize: 15
                            ),
                          )
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8).add(const EdgeInsets.only(bottom: 4)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                "${widget.source.artist} | ${widget.source.album ?? widget.source.uploadDateString}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8).add(const EdgeInsets.only(bottom: 4)),
                        child: Text(
                          "${widget.source.durationString}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                      Spacer(),
                      if(widget.isSaved && widget.showCacheBarIfSaved)
                        Stack(
                          fit: StackFit.passthrough,
                          alignment: Alignment.bottomCenter,
                          children: [
                            LinearProgressIndicator(
                              value: _progress,
                              minHeight: 10,
                            ),
                            Positioned.fill(
                              child: Text(
                                "CACHED",
                                textAlign: TextAlign.center,
                                style: Theme.of(context).accentTextTheme.bodyText1.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            )
                          ],
                        )
                    ],
                  ),
                    Positioned(
                      right: 0,
                      child: widget.trailing ?? IconButton(
                        icon: Icon(Icons.more_vert_rounded),
                        padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                        onPressed: () async {
                          await _showOptionsDialog(context, widget.source);
                        },
                      ),
                    )
                  ],
                ),
              ),
            ],
          )
      ),
    );
  }

  Future<void> _showOptionsDialog(BuildContext context, AudioCursor source) async {

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
            if(widget.isSaved)
              SimpleDialogOption(
                child: _makeText("Edit Metadata"),
                onPressed: (){Get.off(MediaInfoEditorScreen(sourceCursor: source));},
              ),
            SimpleDialogOption(
              child: _makeText("Add to Playlist"),
              onPressed: () async {
                var playlist = await _addToPlaylistDialog(context);
                if(playlist != null){
                  AudioMasterController audioMaster = Get.find();
                  await audioMaster.addCursorToUserPlaylist(playlist, source);
                  await AudioPlaylist.writePlaylistsToDisk();
                }
              },
            ),
            SimpleDialogOption(
              child: _makeText("Delete Cached File",
                style: TextStyle(color: Colors.red)
              ),
              onPressed: (){},
            )
          ],
        );
      }
    );
  }

  Future<AudioPlaylist> _addToPlaylistDialog(BuildContext context) async {
    return await showDialog<AudioPlaylist>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text("Add to Playlist"),
          content: ListView.separated(
            shrinkWrap: true,
            itemCount: AudioPlaylist.userPlaylists.length,
            separatorBuilder: (c, i) => Divider(),
            itemBuilder: (BuildContext context, int index){
              AudioPlaylist playlist = AudioPlaylist.userPlaylists[index];
              return ListTile(
                title: Text(playlist.name),
                onTap: (){
                  Navigator.of(context).pop(playlist);
                },
              );
            },
          ),
          actions: [
            FlatButton(
              child: Text("Cancel"),
              onPressed: Navigator.of(context).pop,
            ),
          ],
        );
      }
    );
  }
}
