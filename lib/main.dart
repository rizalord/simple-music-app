import 'dart:io';
import 'dart:math';

import 'package:audio_manager/audio_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:my_music/main_home.dart';
import 'package:redux/redux.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

enum Actions { Show, NotShow }

/*
  {
    show : false,
    play : true,
    image : null,
    title : null
  }
*/
Map reducerMusic(Map prevState, dynamic action) {
  if (action['status'] == 'show') {
    prevState['show'] = true;
    prevState['title'] = action['title'];
    prevState['image'] = action['image'];
    return prevState;
  } else if (action['status'] == 'play') {
    prevState['play'] = true;
    return prevState;
  } else if (action['status'] == 'pause') {
    prevState['play'] = false;
    return prevState;
  } else if (action['status'] == 'playpause') {
    prevState['play'] = !prevState['play'];
    return prevState;
  }

  return prevState;
}

void main() {
  final store = new Store<Map>(reducerMusic, initialState: {
    'show': false,
    'play': true,
    'image': null,
    'title': null,
  });

  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  final Store<Map> store;

  MyApp({this.store});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          textSelectionColor: Colors.black,
          primaryTextTheme: TextTheme(
            headline1: TextStyle(
                color: Colors.black,
                fontSize: 19.0,
                fontWeight: FontWeight.w400),
          ),
          accentColor: Colors.black,
          primaryColor: Colors.white,
        ),
        home: Home(),
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  Animation<double> animation, animationSlide;
  AnimationController animationController;
  AnimationController animationSlideController;

  final FlutterAudioQuery audioQuery = FlutterAudioQuery();
  List<SongInfo> songs = [];

  @override
  void initState() {
    super.initState();
    showAnimation();
    getMusic();
  }

  void searchMusic(String text) async {
    if (text.length > 0) {
      setState(() {
        songs = [];
        Future.delayed(Duration(milliseconds: 0), () async {
          List<SongInfo> tmp = await audioQuery.searchSongs(query: text);
          tmp = tmp // filter
              .where((SongInfo element) =>
                  element.isMusic &&
                  !element.isNotification &&
                  !element.isPodcast &&
                  !element.isRingtone &&
                  !element.isAlarm &&
                  !element.filePath
                      .contains('/storage/emulated/0/Android/data') &&
                  !element.filePath.contains('/storage/emulated/0/com.'))
              .toList()
              .reversed
              .toList();
          // tmp.forEach((element) {
          //   print(element.filePath);
          // });
          setState(() {
            songs = tmp;
          });
        });
      });
    } else {
      getMusic();
    }
  }

  void getMusic() async {
    Future.delayed(Duration(milliseconds: 0), () async {
      var tmp = await audioQuery.getSongs();
      tmp = tmp // filter
          .where((SongInfo element) =>
              element.isMusic &&
              !element.isNotification &&
              !element.isPodcast &&
              !element.isRingtone &&
              !element.isAlarm &&
              !element.filePath.contains('/storage/emulated/0/Android/data') &&
              !element.filePath.contains('/storage/emulated/0/com.'))
          .toList()
          .reversed
          .toList();
      // tmp.forEach((element) {
      //   print(element.filePath);
      // });
      setState(() {
        songs = tmp;
      });
    });
  }

  void showAnimation() {
    animationController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);

    animationSlideController = AnimationController(
        duration: Duration(milliseconds: 1000), vsync: this);

    animationSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationSlideController,
        curve: Curves.fastOutSlowIn,
      ),
    )..addListener(() {
        setState(() {});
      });

    animation = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(
      parent: animationController,
      curve: Interval(0.0, 1.0, curve: Curves.bounceIn),
    ))
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          animationSlideController.forward();
        }
        // else if (status == AnimationStatus.dismissed) {
        //   animationController.forward();
        // }
      });

    animationController.forward();
  }

  void shuffleList() {
    var tmp = songs;
    tmp.shuffle();
    setState(() {
      songs = [];
      Future.delayed(Duration(microseconds: 0), () {
        setState(() {
          songs = tmp;
        });
      });
    });
  }

  void reverseList() {
    var tmp = songs;
    tmp = tmp.reversed.toList();
    setState(() {
      songs = [];
      Future.delayed(Duration(microseconds: 0), () {
        setState(() {
          songs = tmp;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    final double itemHeight = (size.height - kToolbarHeight - 24) / 2.4;
    final double itemWidth = size.width / 2;

    return Stack(
      children: <Widget>[
        MainHome(
            itemWidth: itemWidth,
            itemHeight: itemHeight,
            all: this.songs,
            shuffle: this.shuffleList,
            reverse: this.reverseList,
            search: this.searchMusic),
        StoreConnector<Map, Map>(
          converter: (store) => store.state,
          builder: (context, state) {
            return state['show'] == true
                ? Positioned(
                    bottom: 0,
                    child: Container(
                      height: 62,
                      width: MediaQuery.of(context).size.width,
                      color: Colors.black.withOpacity(.18),
                      child: Stack(
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 58,
                            color: Colors.white,
                            margin: EdgeInsets.only(top: 5),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.only(left: 15),
                                    height: 45,
                                    // color: Colors.orange,
                                    child: Row(
                                      children: <Widget>[
                                        ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(7.5),
                                            child: StoreConnector<Map, String>(
                                              converter: (store) => store
                                                  .state['image']
                                                  .toString(),
                                              builder: (context, state) {
                                                return Image.file(
                                                    File(songs[AudioManager
                                                            .instance.curIndex]
                                                        .albumArtwork),
                                                    width: 45,
                                                    height: 45,
                                                    fit: BoxFit.cover);
                                              },
                                            )
                                            // Image.file(
                                            //     File(songs[AudioManager
                                            //             .instance.curIndex]
                                            //         .albumArtwork),
                                            //     width: 45,
                                            //     height: 45,
                                            //     fit: BoxFit.cover),
                                            ),
                                        Expanded(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: <Widget>[
                                                Text(
                                                  'PLAYING',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black
                                                          .withOpacity(.5)),
                                                ),
                                                StoreConnector<Map, String>(
                                                  converter: (store) => store
                                                      .state['title']
                                                      .toString(),
                                                  builder: (context, state) {
                                                    return Text(
                                                      AudioManager
                                                          .instance
                                                          .audioList[
                                                              AudioManager
                                                                  .instance
                                                                  .curIndex]
                                                          .title,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 100,
                                  height: 50,
                                  margin: EdgeInsets.only(right: 15),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                          child: StoreConnector<Map, bool>(
                                        converter: (store) {
                                          return store.state['play'];
                                        },
                                        builder: (context, dState) {
                                          return GestureDetector(
                                            onTap: () async {
                                              await AudioManager.instance
                                                  .playOrPause();
                                              setState(() {});
                                            },
                                            child: Icon(
                                              !AudioManager.instance.isPlaying
                                                  ? Icons.play_circle_filled
                                                  : Icons.pause_circle_filled,
                                              size: 50,
                                              color: Colors.black,
                                            ),
                                          );
                                        },
                                      )
                                          // Icon(
                                          //   state['play'] == false
                                          //       ? Icons.play_circle_filled
                                          //       : Icons.pause_circle_filled,
                                          //   size: 50,
                                          //   color: Colors.black,
                                          // ),
                                          ),
                                      TouchableOpacity(
                                        onTap: () {
                                          AudioManager.instance
                                              .next()
                                              .then((value) {
                                            setState(() {});
                                            Future.delayed(
                                                Duration(milliseconds: 0),
                                                () async {
                                              setState(() {});
                                              await AudioManager.instance
                                                  .playOrPause();
                                              await AudioManager.instance
                                                  .playOrPause();
                                              setState(() {});
                                            });
                                          });
                                          Future.delayed(
                                              Duration(milliseconds: 0),
                                              () async {
                                            await AudioManager.instance
                                                .playOrPause();
                                            await AudioManager.instance
                                                .playOrPause();
                                            setState(() {});
                                          });
                                        },
                                        child: Icon(
                                          Icons.skip_next,
                                          size: 35,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              height: 5,
                              color: Colors.lightBlue,
                              width: MediaQuery.of(context).size.width,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Container();
          },
        ),
        Transform.translate(
          offset: Offset(
              animationSlide.value * MediaQuery.of(context).size.width, 0),
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Color(0xFFECECEC),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Transform.scale(
                  scale: animation.value,
                  child: Image.asset(
                    'images/music_logo.jpg',
                    height: MediaQuery.of(context).size.width * .4,
                    width: MediaQuery.of(context).size.width * .4,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    animationSlideController.dispose();
    animationController.dispose();
    super.dispose();
  }
}
