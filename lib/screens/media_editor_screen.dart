import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unchainedplayer/types/audio_cursor.dart';
import 'package:unchainedplayer/types/audio_playlist.dart';
import 'package:unchainedplayer/widgets/easyDialog.dart';
import 'package:unchainedplayer/controllers/audio_master.dart';
import 'package:unchainedplayer/utility/extensions.dart';
import 'dart:math';

class MediaInfoEditorScreen extends StatefulWidget {

  final AudioCursor sourceCursor;

  MediaInfoEditorScreen({Key key, @required this.sourceCursor}) : super(key: key);

  @override
  _MediaInfoEditorScreenState createState() => _MediaInfoEditorScreenState();
}

enum _DialogOption{
  Cancel,
  Discard,
  Save
}

class _MediaInfoEditorScreenState extends State<MediaInfoEditorScreen> {

  TextEditingController _titleController;

  TextEditingController _artistController;

  TextEditingController _albumController;

  TextEditingController _albumArtController;

  bool _hasUnsavedChanges = false;

  //RangeValues _clipRange;

  ValueNotifier<RangeValues> _clipRange;

  int _clipStart;
  int _clipEnd;

  AudioMasterController masterController = Get.find();

  bool _currentEditIsPlaying = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.sourceCursor.title);
    _artistController = TextEditingController(text: widget.sourceCursor.artist);
    _albumController = TextEditingController(text: widget.sourceCursor.album);
    _albumArtController = TextEditingController(text: widget.sourceCursor.thumbnail);

    _clipRange = ValueNotifier<RangeValues>(RangeValues(widget.sourceCursor.clipStart.toDouble(), widget.sourceCursor.clipEnd.toDouble()));

    _clipStart = widget.sourceCursor.clipStart;
    _clipEnd = widget.sourceCursor.clipEnd;
    _currentEditIsPlaying = masterController.mediaItem?.id == widget.sourceCursor.id;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if(_hasUnsavedChanges){
          return await _showExitingDialog(context);
        }
        else{ return true; }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Edit Media"),
        ),
        body: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _hasUnsavedChanges = true,
              validator: (String text){
                if(text.trim() == ""){
                  return "Must not be blank";
                }
                else{ return null; }
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: "Artist",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _hasUnsavedChanges = true,
              validator: (String text){
                if(text.trim() == ""){
                  return "Must not be blank";
                }
                else{ return null; }
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _albumController,
              decoration: InputDecoration(
                  labelText: "Album",
                  border: OutlineInputBorder()
              ),
              onChanged: (_) => _hasUnsavedChanges = true,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _albumArtController,
              decoration: InputDecoration(
                labelText: "Album Art URL",
                border: OutlineInputBorder()
              ),
              onChanged: (_) => _hasUnsavedChanges = true,
              autocorrect: false,
              enableSuggestions: false,
              validator: (String value){
                if(!value.startsWith("http")){
                  return "Must be a valid URL";
                }
                else { return null; }
              },
            ),
            const SizedBox(height: 8),
            Container(
              child: Text("Audio Clip${_currentEditIsPlaying ? " (Cannot edit audio clip while this media is playing)" : ""}"),
            ),
            /*Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                        labelText: "Clip Start",
                        enabled: !_currentEditIsPlaying,
                        border: OutlineInputBorder()
                    ),
                    child: GestureDetector(

                      onTap: !_currentEditIsPlaying ? () async {
                        int newVal = await _showWheelSelectorDialog(context, _clipStart, 0, _clipEnd, title: "Clip Start");
                        if(newVal != null){
                          setState(() {
                            _clipStart = newVal;
                          });
                        }
                      } : null,
                      child: Text(Duration(milliseconds: _clipStart).runtimeString),

                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                        labelText: "Clip End",
                        enabled: !_currentEditIsPlaying,
                        border: OutlineInputBorder()
                    ),
                    child: GestureDetector(

                      onTap: !_currentEditIsPlaying ? () async {
                        int newVal = await _showWheelSelectorDialog(context, _clipEnd, _clipStart, widget.sourceCursor.milisecondsDuration, title: "Clip End");
                        if(newVal != null){
                          setState(() {
                            _clipEnd = newVal;
                          });
                        }
                      } : null,
                      child: Text(Duration(milliseconds: _clipEnd).runtimeString),
                    ),
                  ),
                )
              ],
            ),*/
            ValueListenableBuilder<RangeValues>(
              valueListenable: _clipRange,
              builder: (BuildContext context, RangeValues value, Widget child){
                return RangeSlider(
                  values: value,
                  onChanged: !_currentEditIsPlaying ? (RangeValues newValues){
                    _clipRange.value = newValues;
                  } : null,
                  onChangeEnd: (RangeValues endValues){
                    _hasUnsavedChanges = true;
                  },
                  max: widget.sourceCursor.milisecondsDuration.toDouble(),
                  divisions: Duration(milliseconds: widget.sourceCursor.milisecondsDuration).inSeconds,
                  min: 0,
                  labels: RangeLabels(
                      Duration(milliseconds: value.start.toInt()).runtimeString,
                      Duration(milliseconds: value.end.toInt()).runtimeString
                  ),
                );
              },
            ),
            Container(
              child: Text("Additional Info (Read-Only)"),
              padding: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: Divider.createBorderSide(context)
                  )
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: "Youtube",
                    decoration: InputDecoration(
                        labelText: "Media Source",
                        border: OutlineInputBorder()
                    ),
                    readOnly: true,
                    enabled: false,
                    enableInteractiveSelection: false,
                    toolbarOptions: ToolbarOptions(),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextFormField(
                    initialValue: widget.sourceCursor.sourceID,
                    decoration: InputDecoration(
                      labelText: "Source ID",
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    enabled: false,
                    enableInteractiveSelection: false,
                    toolbarOptions: ToolbarOptions(),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.sourceCursor.durationString,
              decoration: InputDecoration(
                labelText: "Duration",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              enabled: false,
              enableInteractiveSelection: false,
              toolbarOptions: ToolbarOptions(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.sourceCursor.filePath,
              decoration: InputDecoration(
                  labelText: "Filepath",
                  border: OutlineInputBorder()
              ),
              readOnly: true,
              enableInteractiveSelection: false,
              toolbarOptions: ToolbarOptions(),
            )
          ],
        ),
      ),
    );
  }

  Future<int> _showWheelSelectorDialog(BuildContext context, int currentValue, int millisecondsMin, int millisecondsMax,
      {String title}) async
  {
    Duration minDur = Duration(milliseconds: millisecondsMin);
    Duration maxDur = Duration(milliseconds:  millisecondsMax);
    Duration currDur = Duration(milliseconds: currentValue);

    List<int> minuteValues = List<int>.generate(maxDur.inMinutes - minDur.inMinutes, (index) => index + minDur.inMinutes);
    List<int> secondValues = List<int>.generate(min(maxDur.inSeconds, 60), (index) => index);

    List<FixedExtentScrollController> _controllers = [
      FixedExtentScrollController(initialItem: currDur.inMinutes),
      FixedExtentScrollController(initialItem: currDur.inSeconds % 60)
    ];

    Widget _txt(int val, {bool pad = false}){
      return Center(
        child: Text(
          val.toString().padLeft(pad ? 2 : 0, "0"),
          style: TextStyle(fontSize: 28),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      );
    }

    const double extent = 29;

    return await showDialog<int>(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text(title ?? "Clip"),
          content: SizedBox(
            height: 85,
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView(
                    itemExtent: extent,
                    squeeze: 0.8,
                    physics: FixedExtentScrollPhysics(),
                    controller: _controllers[0],
                    children: minuteValues.map<Widget>(_txt).toList(),
                  ),
                ),
                Text(":",
                  style: Get.textTheme.headline4,
                ),
                Expanded(
                  child: ListWheelScrollView(
                    itemExtent: extent,
                    squeeze: 0.8,
                    physics: FixedExtentScrollPhysics(),
                    controller: _controllers[1],
                    children: secondValues.map<Widget>((e) => _txt(e, pad: true)).toList(),
                  ),
                )
              ],
            ),
          ),
          actions: [
            FlatButton(
              child: Text("Cancel"),
              onPressed: Navigator.of(context).pop,
            ),
            FlatButton(
              child: Text("Accept"),
              onPressed: (){
                int val = (_controllers[0].selectedItem * Duration.millisecondsPerMinute) +
                    (_controllers[1].selectedItem * Duration.millisecondsPerSecond);
                Navigator.of(context).pop(val);
              },
            )
          ],
        );
      }
    );
  }

  Future<bool> _showExitingDialog(BuildContext context) async {

    EasyDialog _dialogContent;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context){
        return _dialogContent = EasyDialog(
          title: Text("Attention"),
          persistence: EasyDialog.PERSISTENCE_ALL,
          content: Text("You may have unsaved changes!"),
          actions: [
            FlatButton(
              child: Text("Discard"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            FlatButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FlatButton(
              child: Text("Save"),
              onPressed: () async => Navigator.of(context).pop(await _saveChanges(_dialogContent)),
            )
          ],
        );
      }
    );
  }

  Future<bool> _saveChanges(EasyDialog dialog) async {
    dialog.setLoading(
      title: Text("Saving")
    );
    AudioCursor modifiedCursor = widget.sourceCursor.copyWith(
      title: _titleController.text,
      artist: _artistController.text,
      album: _albumController.text,
      thumbnail: _albumArtController.text,
      clipStart: _clipRange.value.start.toInt(),
      clipEnd: _clipRange.value.end.toInt()
    );


    await masterController.modifySaveAudioCursor(modifiedCursor);
    return true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _clipRange.dispose();
    super.dispose();
  }
}

