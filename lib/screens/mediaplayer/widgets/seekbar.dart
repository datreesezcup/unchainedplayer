import 'dart:math';

import 'package:flutter/material.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:get/get.dart';

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;

  SeekBar({
    @required this.duration,
    @required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _dragValue;
  bool _dragging = false;

  static const double REMAINING_TEXT_WIDTH = 100;

  static RegExp _durationExpr = RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$');

  @override
  Widget build(BuildContext context) {
    final value = min(_dragValue ?? widget.position?.inMilliseconds?.toDouble(),
        widget.duration.inMilliseconds.toDouble());
    if (_dragValue != null && !_dragging) {
      _dragValue = null;
    }

    Duration _currDur = Duration(milliseconds: value.toInt());
    return Stack(
      alignment: Alignment.centerLeft,
      clipBehavior: Clip.none,
      children: [
        Slider(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: value,
          onChanged: (value) {
            if (!_dragging) {
              _dragging = true;
            }
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd(Duration(milliseconds: value.round()));
            }
            _dragging = false;
          },
        ),
        Positioned(
          left: _calculateLeftOffset(context, REMAINING_TEXT_WIDTH, value / widget.duration.inMilliseconds),
          width: REMAINING_TEXT_WIDTH,
          top: 40,
          child: Container(
            width: REMAINING_TEXT_WIDTH,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: context.theme.accentColor,
            ),
            child: Text(
                  "${_durationExpr.firstMatch("$_currDur")?.group(1) ?? '$_currDur'}/${_durationExpr.firstMatch("${widget.duration}")?.group(1) ?? '${widget.duration}'}",
              textAlign: TextAlign.center,
              style: Theme.of(context).accentTextTheme.bodyText1,
            ),
          ),
        ),
      ],
    );
  }

  static double _calculateLeftOffset(BuildContext context, double desiredWidth, double value){
    double availableWidth = context.width - desiredWidth - 12 - 24;
    return 12 + (availableWidth * value);
  }

  Duration get _remaining => widget.duration - (_dragging ? Duration(milliseconds: _dragValue.toInt()) : widget.position ?? Duration.zero);
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

/*
class SeekBarWidget extends StatefulWidget {

  final Duration value;
  final Duration maximum;

  final ValueChanged<Duration> onEndSeek;

  final Duration scrubDebounceTime;

  SeekBarWidget({@required Duration value, @required this.onEndSeek, @required this.maximum, this.scrubDebounceTime = const Duration(milliseconds: 100)}) :
      this.value = Duration(seconds: min(value.inSeconds, maximum.inSeconds));

  @override
  State<StatefulWidget> createState() => _SeekBarWidgetState();

}

class _SeekBarWidgetState extends State<SeekBarWidget>{

  bool _isBeingDragged = false;

  double _saveVal = 0.0;

  static const String _SLIDE_DEBOUNCE_STRING = "seek";

  @override
  Widget build(BuildContext context) {
    if(widget.value == null || widget.maximum == null){
      return LinearProgressIndicator();
    }
    else{
      return Slider(
        value: _isBeingDragged ? _saveVal : widget.value.inMilliseconds.toDouble(),
        max: (widget.maximum.inMilliseconds + 10).toDouble(),
        onChangeStart: (double startVal){
          setState(() {
            _isBeingDragged = true;
          });
        },
        onChanged: (double val) async {
          setState(() {
            _saveVal = val;
          });
          if(_isBeingDragged){
            EasyDebounce.debounce(
                _SLIDE_DEBOUNCE_STRING,
                widget.scrubDebounceTime,
                    ()  {
                  widget.onEndSeek(Duration(seconds: val.round()));
                }
            );
          }
        },
        onChangeEnd: (double newVal){

          setState(() {
            _isBeingDragged = false;
          });
        },
      );
    }
  }
}
*/
