import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unchainedplayer/controllers/audio_master.dart';
import 'package:unchainedplayer/screens/settings/app_settings_screen.dart';
import 'package:unchainedplayer/types/audio_cursor.dart';
import 'package:unchainedplayer/types/audio_playlist.dart';
import 'package:unchainedplayer/utility/extensions.dart';

class QueueDrawer extends StatelessWidget {


  QueueDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AudioMasterController>(
      id: "queue",
      builder: (AudioMasterController master){
        MediaItem currentItem = master.mediaItem;
        bool hasMedia = currentItem != null;
        List<MediaItem> queue = master.currentMediaQueue;
        bool hasQueue = queue != null;
        return Drawer(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DrawerHeader(
                  decoration: BoxDecoration(
                      color: Theme.of(context).accentColor.withAlpha(240),
                      image: hasMedia ? DecorationImage(
                          image: CachedNetworkImageProvider(currentItem.artUri),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.srcOver)
                      ) : null
                  ),
                  child: Column(
                    children: [
                      Text("Currently Playing:",
                        textAlign: TextAlign.center,
                        style: Get.theme.accentTextTheme.headline5
                      ),
                      Text(currentItem?.title ?? "No Media",
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: Get.theme.accentTextTheme.headline6,
                      ),
                      Text(currentItem?.artist ?? "No Media",
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: Get.theme.accentTextTheme.caption,
                      )
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text("Settings"),
                  onTap: (){
                    Get.to(AppSettingsScreen());
                  },
                  trailing: Icon(Icons.navigate_next),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    "Queue:",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: Divider.createBorderSide(context)
                      )
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index){
                      MediaItem buildingItem = queue[index];
                      bool thisItemPlaying = index == master.currentQueueIndex;
                      return ListTile(
                        title: Text(buildingItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text("${buildingItem.artist} | ${buildingItem.duration.runtimeString}"),
                        selected: thisItemPlaying,
                        onTap: thisItemPlaying ? null : () => AudioService.skipToQueueItem(buildingItem.id),
                      );
                    },
                    childCount: queue?.length ?? 0
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class _InternalTintedDrawerHeader extends StatelessWidget {
  /// Decoration for the main drawer header [Container]; useful for applying
  /// backgrounds.
  ///
  /// This decoration will extend under the system status bar.
  ///
  /// If this is changed, it will be animated according to [duration] and [curve].
  final Decoration decoration;

  /// The padding by which to inset [child].
  ///
  /// The [DrawerHeader] additionally offsets the child by the height of the
  /// system status bar.
  ///
  /// If the child is null, the padding has no effect.
  final EdgeInsetsGeometry padding;

  /// The margin around the drawer header.
  final EdgeInsetsGeometry margin;

  /// The duration for animations of the [decoration].
  final Duration duration;

  /// The curve for animations of the [decoration].
  final Curve curve;

  /// A widget to be placed inside the drawer header, inset by the [padding].
  ///
  /// This widget will be sized to the size of the header. To position the child
  /// precisely, consider using an [Align] or [Center] widget.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  ///The color that will be overlayed the decoration, if any
  final Color tint;

  _InternalTintedDrawerHeader({
    Key key,
    this.decoration,
    this.tint,
    this.margin = const EdgeInsets.only(bottom: 8.0),
    this.padding = const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.fastOutSlowIn,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    @override
    Widget build(BuildContext context) {
      assert(debugCheckHasMaterial(context));
      assert(debugCheckHasMediaQuery(context));
      final ThemeData theme = Theme.of(context);
      final double statusBarHeight = MediaQuery.of(context).padding.top;
      return Container(
        height: statusBarHeight + 161,
        margin: margin,
        decoration: BoxDecoration(
          border: Border(
            bottom: Divider.createBorderSide(context),
          ),
        ),
        child: AnimatedContainer(
          padding: padding.add(EdgeInsets.only(top: statusBarHeight)),
          decoration: decoration,
          duration: duration,
          curve: curve,
          child: child == null ? null : DefaultTextStyle(
            style: theme.textTheme.bodyText1,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ),
      );
    }
  }

}
