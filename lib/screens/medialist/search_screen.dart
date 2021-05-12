import 'package:flutter/material.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:get/get.dart';
import 'package:unchainedplayer/screens/medialist/medialist.dart';
import 'package:unchainedplayer/types/mediasource/youtubesource.dart';

class MediaSearchScreen extends StatelessWidget {

  static const String EASYDEBOUNCE_KEY = "mediasearch";

  MediaSearchScreen();

  final MediaSearchController _mediaSearchController = Get.find();

  /*@override
  _MediaSearchScreenState createState() => _MediaSearchScreenState();
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Container(
          height: 40,
          child: TextFormField(
            focusNode: _mediaSearchController.searchFocus,
            controller: _mediaSearchController.textController,
            onTap: (){
              _mediaSearchController.searchFocus.requestFocus();
            },
            onChanged: (String newVal){
              EasyDebounce.debounce(
                  "mediasearch",
                  const Duration(milliseconds: 300),
                      (){
                    _mediaSearchController.suggestionFuture = YoutubeMediaSource().getAutoCompleteSuggestions(_mediaSearchController.query);
                  }
              );
            },
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (String val){
              _mediaSearchController.searchFocus.unfocus();
              _mediaSearchController.isSearchingVideos = true;
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintMaxLines: 1,
              filled: true,
              contentPadding: EdgeInsets.zero,
              fillColor: Colors.white24,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20)
              ),
              hintText: "Search Youtube Videos",
            ),
          ),
        ),
      ),
      body: GetBuilder<MediaSearchController>(
        builder: (MediaSearchController search){
          if(search.isSearchingVideos && !search.isEditingText){
            return MediaListScreen.cursorStream(
                source: YoutubeMediaSource(),
                stream: YoutubeMediaSource().getVideosForSearch(search.query)
            );
          }
          else{
            if(search.query.trim() == ""){
              if(search.history.isEmpty){
                return Center(
                  child: Text("Search for a video to get started!"),
                );
              }
              else{
                return ListView.separated(
                  itemCount: search.history.length,
                  separatorBuilder: (b, i) => Divider(),
                  itemBuilder: (BuildContext context, int index){
                    String suggest = search.history[index];
                    return GestureDetector(

                      onTap: (){
                        _mediaSearchController.isSearchingVideos = true;
                        search.searchFocus.unfocus();
                        _mediaSearchController.query = suggest;
                      },

                      child: getSuggestion(suggest, isHistory: true),
                    );
                  },
                );
              }
            }
            else{
              return FutureBuilder<List<String>>(
                future: search.suggestionFuture,
                builder: (BuildContext context, AsyncSnapshot<List<String>> snap){
                  if(snap.connectionState != ConnectionState.done){
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  else if(snap.hasError){
                    return Center(
                      child: Text("An Error occurred while getting suggestions. Please try again later"),
                    );
                  }
                  else{
                    List<String> suggestions = snap.data;
                    if(suggestions.length == 0){
                      return Center(
                        child: Text("No Suggestions Found"),
                      );
                    }
                    else{
                      return ListView.separated(
                        itemCount: suggestions.length,
                        separatorBuilder: (b, i) => Divider(),
                        itemBuilder: (BuildContext context, int index){
                          String suggest = suggestions[index];
                          return GestureDetector(
                            onTap: (){
                              search.isSearchingVideos = true;
                              search.searchFocus.unfocus();
                              search.query = suggest;
                              search.isSearchingVideos = true;
                            },
                            child: getSuggestion(suggest),
                          );
                        },
                      );
                    }
                  }
                },
              );
            }
          }
        },
      ),
    );
  }

  Widget getSuggestion(String suggestion, {bool isHistory=false}){
    return ListTile(
      title: Text(suggestion),
      leading: isHistory ? Icon(Icons.history_rounded) : null,
    );
  }
}

/*class _MediaSearchScreenState {

  MediaSearchController _mediaSearchController;

  List<String> history = List<String>();

  FocusNode _searchNode = FocusNode();

  Future<List<String>> _suggestionFuture;

  @override
  void initState() {
    super.initState();
    _mediaSearchController = Get.put(MediaSearchController());
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Container(
          height: 40,
          child: TextFormField(
            focusNode: _searchNode,
            controller: controller,
            onTap: (){
              _searchNode.requestFocus();
              setState(() {
                _mediaSearchController.isEditingText = true;
              });
            },
            onChanged: (String newVal){
              EasyDebounce.debounce(
                  "mediasearch",
                  const Duration(milliseconds: 300),
                      (){
                    _mediaSearchController.query = newVal;
                    _suggestionFuture = YoutubeMediaSource().getAutoCompleteSuggestions(_mediaSearchController.query);
                  }
              );
            },
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (String val){
              FocusScope.of(context).unfocus();
              _mediaSearchController.query = val;
              _mediaSearchController.isEditingText = false;
              _mediaSearchController.isSearchingVideos = true;
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintMaxLines: 1,
              filled: true,
              contentPadding: EdgeInsets.zero,
              fillColor: Colors.white24,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20)
              ),
              hintText: "Search Youtube Videos",
            ),
          ),
        ),
      ),
      body: GetBuilder<MediaSearchController>(
        builder: (MediaSearchController search){
          if(search.query.trim() == ""){
            if(history.isEmpty){
              return Center(
                child: Text("Search for a video to get started!"),
              );
            }
            else{
              return ListView.separated(
                itemCount: history.length,
                separatorBuilder: (b, i) => Divider(),
                itemBuilder: (BuildContext context, int index){
                  String suggest = history[index];
                  return GestureDetector(

                    onTap: (){
                      _mediaSearchController.isSearchingVideos = true;
                      _searchNode.unfocus();
                      _mediaSearchController.isEditingText = false;
                      _mediaSearchController.query = suggest;
                      controller.text = suggest;
                    },

                    child: getSuggestion(suggest, isHistory: true),
                  );
                },
              );
            }
          }
          else{
            return FutureBuilder<List<String>>(
              future: _suggestionFuture,
              builder: (BuildContext context, AsyncSnapshot<List<String>> snap){
                if(snap.connectionState != ConnectionState.done){
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                else if(snap.hasError){
                  return Center(
                    child: Text("An Error occurred while getting suggestions. Please try again later"),
                  );
                }
                else{
                  List<String> suggestions = snap.data;
                  if(suggestions.length == 0){
                    return Center(
                      child: Text("No Suggestions Found"),
                    );
                  }
                  else{
                    return ListView.separated(
                      itemCount: suggestions.length,
                      separatorBuilder: (b, i) => Divider(),
                      itemBuilder: (BuildContext context, int index){
                        String suggest = suggestions[index];
                        return GestureDetector(
                          onTap: (){
                            search.isSearchingVideos = true;
                            _searchNode.unfocus();
                            search.isEditingText = false;
                            search.query = suggest;
                            controller.text = suggest;
                            history.insert(0, suggest);
                            Get.to(MediaListScreen.cursorStream(
                              source: YoutubeMediaSource(),
                              stream: YoutubeMediaSource().getVideos(search.query),
                            ),
                              id: 1
                            );
                          },

                          child: getSuggestion(suggest),
                        );
                      },
                    );
                  }
                }
              },
            );
          }
        },
      )
    );
  }
  */


/*
  @override
  Widget build(BuildContext context) {
    //super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Container(
          height: 40,
          child: TextFormField(
            focusNode: _searchNode,
            controller: controller,
            onTap: (){
              _searchNode.requestFocus();
              setState(() {
                _mediaSearchController.isEditingText = true;
              });
            },
            onChanged: (String newVal){
              EasyDebounce.debounce(
                  "mediasearch",
                  const Duration(milliseconds: 300),
                      (){
                    _mediaSearchController.query = newVal;
                    _suggestionFuture = YoutubeMediaSource().getAutoCompleteSuggestions(_mediaSearchController.query);
                  }
              );
            },
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (String val){
              FocusScope.of(context).unfocus();
              _mediaSearchController.query = val;
              _mediaSearchController.isEditingText = false;
              _mediaSearchController.isSearchingVideos = true;
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintMaxLines: 1,
              filled: true,
              contentPadding: EdgeInsets.zero,
              fillColor: Colors.white24,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20)
              ),
              hintText: "Search Youtube Videos",
            ),
          ),
        ),
      ),
      body: GetBuilder<MediaSearchController>(
        builder: (MediaSearchController searchController){
          if(_mediaSearchController.isSearchingVideos && !_mediaSearchController.isEditingText){
            return MediaListScreen.cursorStream(
              source: YoutubeMediaSource(),
              stream: YoutubeMediaSource().getVideos(_mediaSearchController.query)
            );
          }
          else{
            if(_mediaSearchController.query.trim() == ""){
              if(history.isEmpty){
                return Center(
                  child: Text("Search for a video to get started!"),
                );
              }
              else{
                return ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (b, i) => Divider(),
                  itemBuilder: (BuildContext context, int index){
                    String suggest = history[index];
                    return GestureDetector(

                      onTap: (){
                        _mediaSearchController.isSearchingVideos = true;
                        _searchNode.unfocus();
                        _mediaSearchController.isEditingText = false;
                        _mediaSearchController.query = suggest;
                        controller.text = suggest;
                      },

                      child: getSuggestion(suggest, isHistory: true),
                    );
                  },
                );
              }
            }
            else{
              return FutureBuilder<List<String>>(
                future: _suggestionFuture,
                builder: (BuildContext context, AsyncSnapshot<List<String>> snap){
                  if(snap.connectionState != ConnectionState.done){
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  else if(snap.hasError){
                    return Center(
                      child: Text("An Error occurred while getting suggestions. Please try again later"),
                    );
                  }
                  else{
                    List<String> suggestions = snap.data;
                    if(suggestions.length == 0){
                      return Center(
                        child: Text("No Suggestions Found"),
                      );
                    }
                    else{
                      return ListView.separated(
                        itemCount: suggestions.length,
                        separatorBuilder: (b, i) => Divider(),
                        itemBuilder: (BuildContext context, int index){
                          String suggest = suggestions[index];
                          return GestureDetector(
                            onTap: (){
                              _mediaSearchController.isSearchingVideos = true;
                              _searchNode.unfocus();
                              _mediaSearchController.isEditingText = false;
                              _mediaSearchController.query = suggest;
                              controller.text = suggest;
                              history.insert(0, suggest);
                            },

                            child: getSuggestion(suggest),
                          );
                        },
                      );
                    }
                  }
                },
              );
            }
          }
        },
      )
    );
  }

  
  Widget getSuggestion(String suggestion, {bool isHistory=false}){
    return ListTile(
      title: Text(suggestion),
      leading: isHistory ? Icon(Icons.history_rounded) : null,
    );
  }
}
*/


class MediaSearchController extends GetxController {

  List<String> _history = List<String>();
  List<String> get history => _history;

  TextEditingController _searchController;
  TextEditingController get textController => _searchController;

  FocusNode _searchFocus;
  FocusNode get searchFocus => _searchFocus;

  //RxBool _isEditingText = false.obs;
  bool get isEditingText => _searchFocus.hasPrimaryFocus;
  //set isEditingText(bool editing){ _isEditingText.value = editing; update(); }

  RxBool _isSearchingVideos = false.obs;
  bool get isSearchingVideos => _isSearchingVideos.value;
  set isSearchingVideos(bool searching) { _isSearchingVideos.value = searching; update(); }

  String get query => _searchController.value.text;
  set query(String q) {
    _searchController.text = q;
    update();
  }

  Future<List<String>> _suggestionFuture;
  Future<List<String>> get suggestionFuture => _suggestionFuture;
  set suggestionFuture(Future<List<String>> future) {_suggestionFuture = future; update(); }



  @override
  void onInit() {
    super.onInit();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
  }

  @override
  void onClose() {
    _searchController?.dispose();
    _searchFocus?.dispose();
    super.onClose();
  }


}
