import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';
import 'package:unchainedplayer/controllers/audio_master.dart';
import 'widgets/queue_drawer.dart';
import 'widgets/seekbar.dart';

class MediaPlayerScreen extends StatelessWidget {


  //final _MediaPlaybackStateController _stateController = Get.put(_MediaPlaybackStateController());
  //final _MediaMetadataStateController _metaController = Get.put(_MediaMetadataStateController());

  MediaPlayerScreen();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: QueueDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_downward_rounded),
          onPressed: Navigator.of(context).maybePop,
        ),
      ),
      body: GetBuilder<AudioMasterController>(
        id: "player",
        builder: (AudioMasterController master){
          bool hasMedia = master.mediaItem != null;
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Column(
              //crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 300,
                    height: 300,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: hasMedia ? CachedNetworkImage(
                      imageUrl: master.mediaItem.artUri.toString(),
                      useOldImageOnUrlChange: true,
                      fit: BoxFit.cover,
                    ) : Center(
                      child: Icon(
                          Icons.music_note
                      ),
                    )
                ),
                const SizedBox(height: 6),
                Text(hasMedia ? master.mediaItem.title : "No Media",
                  style: Get.textTheme.headline6,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(hasMedia ? "${master.mediaItem.artist}: ${master.mediaItem.album}" : "No Media",
                  textAlign: TextAlign.center,
                  style: Get.textTheme.caption,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    _getShuffleButton(context, master),
                    IconButton(
                      icon: Icon(Icons.skip_previous_rounded),
                      iconSize: 50,
                      onPressed: master.playbackActive ? master.playbackState.actions.contains(MediaAction.skipToPrevious) ?
                      AudioService.skipToPrevious : null : null,
                    ),
                    IconButton(
                      icon: Icon(master.playbackState?.playing ?? false ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      iconSize: 50,
                      onPressed: master.playbackActive ?  (){
                        if(master.playbackState.playing){
                          AudioService.pause();
                        }
                        else{
                          AudioService.play();
                        }
                      } : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next_rounded),
                      iconSize: 50,
                      onPressed: master.playbackActive ? master.playbackState.actions.contains(MediaAction.skipToPrevious)  ?
                      AudioService.skipToNext : null : null,
                    ),
                    _getRepeatButton(context, master)
                  ],
                ),
                StreamBuilder<Duration>(
                    stream: master.playbackActive ? master.positionStream : null,
                    builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                      if(snapshot.connectionState != ConnectionState.active || !snapshot.hasData){
                        return LinearProgressIndicator();
                      }
                      else{
                        return SeekBar(
                          position: snapshot.data,
                          duration: master.mediaItem.duration,
                          onChangeEnd: (Duration d){
                            AudioService.seekTo(d);
                          },
                        );
                      }
                    }
                )
              ],
            ),
          );
        },
      ),
    );
  }

  IconButton _getShuffleButton(BuildContext context, AudioMasterController master){
    bool playbackActive = master.playbackActive;
    AudioServiceShuffleMode _currShuffleMode = master.playbackState?.shuffleMode ?? AudioServiceShuffleMode.none;
    AudioServiceShuffleMode _nextShuffleMode = _currShuffleMode == AudioServiceShuffleMode.none ? AudioServiceShuffleMode.group :
        AudioServiceShuffleMode.none;
    IconData icon = _currShuffleMode == AudioServiceShuffleMode.none ? Icons.shuffle_rounded : Icons.shuffle_on;
    return IconButton(
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
      tooltip: "Shuffle Mode",
      onPressed: playbackActive ? (){
        AudioService.setShuffleMode(_nextShuffleMode);
      } : null,
    );
  }

  IconButton _getRepeatButton(BuildContext context, AudioMasterController master){
    bool playbackActive = master.playbackActive;
    AudioServiceRepeatMode _currRepeatMode = master.playbackState?.repeatMode ?? AudioServiceRepeatMode.group;
    AudioServiceRepeatMode _nextRepeatMode = _currRepeatMode == AudioServiceRepeatMode.group ? AudioServiceRepeatMode.one :
      AudioServiceRepeatMode.group;
    IconData icon = _currRepeatMode == AudioServiceRepeatMode.group ? Icons.repeat_rounded : Icons.repeat_one_rounded;
    return IconButton(
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
      tooltip: "Repeat Mode",
      onPressed: playbackActive ? () {
        AudioService.setRepeatMode(_nextRepeatMode);
      } : null,
    );
  }
}

class MiniMediaPlayerWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: Material(
        color: Theme.of(context).primaryColor,
          type: MaterialType.card,
          elevation: 8,
          child: GetBuilder<AudioMasterController>(
            id: "miniPlayer",
            builder: (AudioMasterController master){
              bool hasMedia = master.mediaItem != null;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if(hasMedia)
                    CachedNetworkImage(
                      imageUrl: master.mediaItem.artUri.toString(),
                      width: 100,
                      fit: BoxFit.fitHeight,
                    )
                  else
                    Container(width: 100),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(hasMedia ? master.mediaItem.title : "No Media",
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                          Text(hasMedia ? master.mediaItem.artist : "No Media",
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.caption,
                          ),
                          Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.skip_previous_rounded),
                                    onPressed: master.playbackActive ? master.playbackState.actions.contains(MediaAction.skipToPrevious) ?
                                    AudioService.skipToPrevious : null : null,
                                  ),
                                  IconButton(
                                    icon: Icon(master.playbackState?.playing ?? false ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                    onPressed: master.playbackActive ?  (){
                                      if(master.playbackState.playing){
                                        AudioService.pause();
                                      }
                                      else{
                                        AudioService.play();
                                      }
                                    } : null,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.skip_next_rounded),
                                    onPressed: master.playbackActive ? master.playbackState.actions.contains(MediaAction.skipToPrevious)  ?
                                    AudioService.skipToNext : null : null,
                                  )
                                ],
                              )
                          ),
                          StreamBuilder<Duration>(
                            stream: hasMedia ? master.positionStream : null,
                            builder: (BuildContext context, AsyncSnapshot<Duration> snap){
                              if(snap.connectionState != ConnectionState.active || !snap.hasData){
                                return LinearProgressIndicator();
                              }
                              else{
                                return LinearProgressIndicator(
                                  value: snap.data.inSeconds.toDouble() / master.mediaItem.duration.inSeconds.toDouble(),
                                  backgroundColor: Theme.of(context).accentColor.withAlpha(120),
                                );
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
          )
      ),
    );
  }

}

