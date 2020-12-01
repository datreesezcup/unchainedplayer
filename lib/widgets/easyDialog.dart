import 'package:flutter/material.dart';

typedef Widget DialogBuilder(BuildContext context, EasyDialog diag);

class EasyDialog extends StatefulWidget{
  final _EasyDialogState state;

  static const int PERSISTENCE_NONE = 0;
  static const int PERSISTENCE_ALL = 1;

  EasyDialog({Key key, Widget title, Widget content, List<Widget> actions, int persistence})
      : state = new _EasyDialogState(title, content, actions, persistence),
  super(key: key);

  void update({Widget title, Widget content, List<Widget> actions, int persistence}){
    state._update(newTitle: title, newContent: content, newActions: actions, persistence: persistence);
  }

  void setLoading({Widget title, Widget text}){
    update(
      title: title ?? Text("Loading"),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          CircularProgressIndicator(),
          text ?? Text("Please Wait...")
        ],
      ),
      actions: [],
      persistence: PERSISTENCE_ALL
    );
  }

  factory EasyDialog.textInput({Widget title, String initialText, InputDecoration decoration,
    String Function(String value) validator
  }){

  }

  factory EasyDialog.customLoading({Widget title, Widget text}){
    return new EasyDialog(
      title: title,
      persistence: PERSISTENCE_ALL,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          CircularProgressIndicator(),
          text
        ],
      ),
    );
  }

  factory EasyDialog.loading({Widget title, Widget text}){
    return new EasyDialog(
      title: title ?? Text("Loading"),
      persistence: PERSISTENCE_ALL,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          CircularProgressIndicator(),
          text ?? Text("Please Wait..")
        ],
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => state;
}

class _EasyDialogState<T> extends State<EasyDialog> {
  Widget _title;
  Widget _content;
  List<Widget> actions;
  int _persistence;

  _EasyDialogState(this._title, this._content, this.actions, [this._persistence = EasyDialog.PERSISTENCE_NONE]);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(_persistence != EasyDialog.PERSISTENCE_ALL),
        child: AlertDialog(
          title: _title ?? Text("Title"),
          content: _content,
          actions: actions,
        )
    );
  }

  void _update({Widget newTitle, Widget newContent, List<Widget> newActions, int persistence}){
    if(mounted) {
      setState(() {
        _title = newTitle ?? _title;
        _content = newContent ?? _content;
        actions = newActions ?? actions;
        _persistence = persistence ?? _persistence;
      });
    }
  }
}