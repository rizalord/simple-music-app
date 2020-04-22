import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:audio_manager/audio_manager.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:marquee/marquee.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Actions { Show, NotShow }

class PlayMusic extends StatefulWidget {
  final SongInfo single;
  final List<SongInfo> playlist;
  final Function setState;
  final Map secondData;

  PlayMusic(
      {this.single = null,
      this.playlist,
      this.setState,
      this.secondData = null});

  @override
  _PlayMusicState createState() => _PlayMusicState();
}

class _PlayMusicState extends State<PlayMusic> {
  String _platformVersion = 'Unknown', image, title;
  bool isPlaying = false;
  Duration _duration;
  Duration _position;
  double _slider;
  double _sliderVolume;
  String _error;
  num curIndex = 0;
  PlayMode playMode = AudioManager.instance.playMode;
  bool liked = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    setMusic();
    saveToHistory();
    getLikeStatus();
  }

  void getLikeStatus() async {
    Map singleData = {
      'path': widget.playlist[curIndex].filePath,
      'title': widget.playlist[curIndex].title,
      'image': widget.playlist[curIndex].albumArtwork,
      'artist': widget.playlist[curIndex].artist,
      'album': widget.playlist[curIndex].album
    };

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> prevData = prefs.getStringList('history');

    if (prevData != null) {
      if (prevData.indexOf(json.encode(singleData)) > 0) {
        setState(() {
          liked = true;
        });
      } else {
        setState(() {
          liked = false;
        });
      }
    }
  }

  void saveToHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> prevData = prefs.getStringList('history');

    Map singleData = {
      'path': widget.single != null
          ? widget.single.filePath
          : widget.secondData['path'],
      'title': widget.single != null
          ? widget.single.title
          : widget.secondData['title'],
      'image': widget.single != null
          ? widget.single.albumArtwork
          : widget.secondData['image'],
      'artist': widget.single != null
          ? widget.single.artist
          : widget.secondData['artist'],
      'album': widget.single != null
          ? widget.single.album
          : widget.secondData['album']
    };

    if (prevData == null) {
      // jika kosong
      List<String> newData = [];
      newData.add(json.encode(singleData));
      prefs.setStringList('history', newData);
    } else {
      int idx = prevData.indexOf(json.encode(singleData));
      // jika ada
      if (idx < 0) {
        // tidak ada yang sama
        prevData.insert(0, json.encode(singleData));
      } else {
        prevData.removeAt(idx);
        prevData.insert(0, json.encode(singleData));
      }
      prefs.setStringList('history', prevData);
    }
  }

  void setMusic() {
    if (AudioManager.instance.curIndex == 0 &&
        AudioManager.instance.audioList.length == 0) {
      loadFile();
      setupAudio();
    } else if (widget.playlist.indexOf(widget.single) !=
        AudioManager.instance.curIndex) {
      loadFile();
      setupAudio();
    } else {
      loadFile();
      setState(() {
        _duration = AudioManager.instance.duration;
        _position = AudioManager.instance.position;
        isPlaying = AudioManager.instance.isPlaying;
      });
      AudioManager.instance.onEvents((events, args) {
        print("$events, $args");
        switch (events) {
          case AudioManagerEvents.start:
            print("start load data callback");
            _position = AudioManager.instance.position;
            _duration = AudioManager.instance.duration;
            _slider = 0;
            setState(() {});
            break;
          case AudioManagerEvents.ready:
            print("ready to play");
            _error = null;
            _sliderVolume = AudioManager.instance.volume;
            _position = AudioManager.instance.position;
            _duration = AudioManager.instance.duration;
            title = widget.playlist[AudioManager.instance.curIndex].title;
            image =
                widget.playlist[AudioManager.instance.curIndex].albumArtwork;
            setState(() {
              title = widget.playlist[AudioManager.instance.curIndex].title;
              image =
                  widget.playlist[AudioManager.instance.curIndex].albumArtwork;
            });
            AudioManager.instance.seekTo(Duration(microseconds: 1));
            break;
          case AudioManagerEvents.seekComplete:
            _position = AudioManager.instance.position;
            _slider = _position.inMilliseconds / _duration.inMilliseconds;
            setState(() {});
            print("seek event is completed. position is [$args]/ms");
            break;
          case AudioManagerEvents.buffering:
            print("buffering $args");
            break;
          case AudioManagerEvents.playstatus:
            isPlaying = AudioManager.instance.isPlaying;
            setState(() {});
            break;
          case AudioManagerEvents.timeupdate:
            _position = AudioManager.instance.position;
            _slider = _position.inMilliseconds / _duration.inMilliseconds;
            setState(() {});
            AudioManager.instance.updateLrc(args["position"].toString());
            break;
          case AudioManagerEvents.error:
            _error = args;
            setState(() {});
            break;
          case AudioManagerEvents.ended:
            AudioManager.instance.next();
            break;
          case AudioManagerEvents.volumeChange:
            _sliderVolume = AudioManager.instance.volume;
            setState(() {});
            break;
          default:
            break;
        }
      });
    }
  }

  @override
  void dispose() {
    // AudioManager.instance.stop();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  void setupAudio() {
    // List<AudioInfo> _list = [];
    // list.forEach(
    //   (item) => _list.add(
    //     AudioInfo(
    //       item["url"],
    //       title: item["title"],
    //       desc: item["desc"],
    //       coverUrl: item["coverUrl"],
    //     ),
    //   ),
    // );

    // AudioManager.instance.audioList = _list;
    // AudioManager.instance.start(
    //   list.first['url'],
    //   list.first['title'],
    //   desc: list.first['desc'],
    //   cover: list.first['coverUrl'],
    //   auto: true
    // );
    AudioManager.instance.intercepter = true;
    print("masih berjalan : ${AudioManager.instance.isPlaying}");
    print('list data ');
    print(AudioManager.instance.audioList);
    AudioManager.instance.play(auto: true, index: curIndex);
    // AudioManager.instance.next();
    // AudioManager.instance.previous();

    AudioManager.instance.onEvents((events, args) {
      print("$events, $args");
      switch (events) {
        case AudioManagerEvents.start:
          print("start load data callback");
          _position = AudioManager.instance.position;
          _duration = AudioManager.instance.duration;
          _slider = 0;
          setState(() {});
          break;
        case AudioManagerEvents.ready:
          print("ready to play");
          _error = null;
          _sliderVolume = AudioManager.instance.volume;
          _position = AudioManager.instance.position;
          _duration = AudioManager.instance.duration;
          setState(() {});
          AudioManager.instance.seekTo(Duration(microseconds: 1));
          break;
        case AudioManagerEvents.seekComplete:
          _position = AudioManager.instance.position;
          _slider = _position.inMilliseconds / _duration.inMilliseconds;
          setState(() {});
          print("seek event is completed. position is [$args]/ms");
          break;
        case AudioManagerEvents.buffering:
          print("buffering $args");
          break;
        case AudioManagerEvents.playstatus:
          isPlaying = AudioManager.instance.isPlaying;
          setState(() {});
          break;
        case AudioManagerEvents.timeupdate:
          _position = AudioManager.instance.position;
          _slider = _position.inMilliseconds / _duration.inMilliseconds;
          setState(() {});
          AudioManager.instance.updateLrc(args["position"].toString());
          break;
        case AudioManagerEvents.error:
          _error = args;
          setState(() {});
          break;
        case AudioManagerEvents.ended:
          AudioManager.instance.next();
          break;
        case AudioManagerEvents.volumeChange:
          _sliderVolume = AudioManager.instance.volume;
          setState(() {});
          break;
        default:
          break;
      }
    });
  }

  void loadFile() async {
    // Multiple Add

    if (AudioManager.instance.audioList.length == 0) {
      widget.playlist.forEach((element) {
        AudioInfo info = AudioInfo("file://${element.filePath}",
            title: element.title,
            desc: element.artist,
            coverUrl: element.albumArtwork);
        AudioManager.instance.audioList.add(info);
      });
      // list.add(info.toJson());
    }

    if (widget.single != null) {
      curIndex = widget.playlist.indexOf(widget.single);
      image = widget.playlist[curIndex].albumArtwork;
      title = widget.playlist[curIndex].title;
    } else {
      widget.playlist.forEach((element) {
        if (element.title == widget.secondData['title']) {
          curIndex = widget.playlist.indexOf(element);
        }
      });
      image = widget.playlist[curIndex].albumArtwork;
      title = widget.playlist[curIndex].title;
    }
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await AudioManager.instance.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void setFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> prevData = prefs.getStringList('liked');

    Map singleData = {
      'path': widget.playlist[curIndex].filePath,
      'title': widget.playlist[curIndex].title,
      'image': widget.playlist[curIndex].albumArtwork,
      'artist': widget.playlist[curIndex].artist,
      'album': widget.playlist[curIndex].album
    };

    if (prevData == null) {
      // jika kosong
      List<String> newData = [];
      newData.add(json.encode(singleData));
      prefs.setStringList('liked', newData);
    } else {
      int idx = prevData.indexOf(json.encode(singleData));
      // jika ada
      if (idx < 0) {
        // tidak ada yang sama
        prevData.insert(0, json.encode(singleData));
        setState(() {
          liked = true;
        });
      } else {
        prevData.removeAt(idx);
        setState(() {
          liked = false;
        });
      }

      prefs.setStringList('liked', prevData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              children: <Widget>[
                Container(
                  height: 60,
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.chevron_left,
                            color: Colors.black, size: 30),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        // child: Marquee(
                        //   text: title,
                        // style: TextStyle(
                        //   color: Colors.black.withOpacity(0.8),
                        //   fontSize: 20,
                        //   fontWeight: FontWeight.w500,
                        // ),
                        //   blankSpace: 20.0,
                        //   pauseAfterRound: Duration(seconds: 2),
                        //   velocity: 40.0,
                        // ),
                        child: LayoutBuilder(
                          builder: (context, size) {
                            var span = TextSpan(
                              text: widget
                                  .playlist[AudioManager.instance.curIndex]
                                  .title,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.8),
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                              ),
                            );

                            var tp = TextPainter(
                                maxLines: 1,
                                textAlign: TextAlign.left,
                                textDirection: TextDirection.ltr,
                                text: span);

                            tp.layout(maxWidth: size.maxWidth);

                            var exceeded = tp.didExceedMaxLines;

                            return exceeded
                                ? Marquee(
                                    text: widget
                                        .playlist[
                                            AudioManager.instance.curIndex]
                                        .title,
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.8),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    blankSpace: 20.0,
                                    pauseAfterRound: Duration(seconds: 2),
                                    velocity: 40.0,
                                  )
                                : Container(
                                    margin: EdgeInsets.only(right: 30),
                                    alignment: Alignment.center,
                                    child: Text(
                                      widget
                                          .playlist[
                                              AudioManager.instance.curIndex]
                                          .title,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.8),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 25),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(17),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.15),
                                    offset: Offset(0, 8),
                                    blurRadius: 2,
                                    spreadRadius: 0,
                                  )
                                ]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Image.file(
                                  File(widget
                                      .playlist[AudioManager.instance.curIndex]
                                      .albumArtwork),
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  height:
                                      MediaQuery.of(context).size.width * 0.8,
                                  fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(45),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(.1),
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    spreadRadius: 3,
                                  )
                                ],
                              ),
                              child: IconButton(
                                onPressed: () {
                                  this.setFavorite();
                                },
                                icon: Icon(
                                  !this.liked
                                      ? Icons.favorite_border
                                      : Icons.favorite,
                                  color: Colors.pink,
                                ),
                                iconSize: 30,
                              ),
                            ),
                            bottom: 0,
                          ),
                        ],
                      ),
                      bottomPanel()
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget bottomPanel() {
    return Column(children: <Widget>[
      songProgress(context),
      Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
                icon: getPlayModeIcon(playMode),
                onPressed: () {
                  playMode = AudioManager.instance.nextMode();
                  setState(() {});
                }),
            IconButton(
                iconSize: 36,
                icon: Icon(
                  Icons.skip_previous,
                  color: Colors.black,
                ),
                onPressed: () => AudioManager.instance.previous()),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(70), color: Colors.black),
              child: StoreConnector<Map, List<VoidCallback>>(
                converter: (store) {
                  List<void Function()> func = [
                    () => store.dispatch({
                          'status': 'show',
                          'title': AudioManager.instance
                              .audioList[AudioManager.instance.curIndex].title,
                          'image': AudioManager
                              .instance
                              .audioList[AudioManager.instance.curIndex]
                              .coverUrl
                        }),
                    () => store.dispatch({'status': 'play'}),
                    () => store.dispatch({'status': 'pause'}),
                  ];
                  return func;
                },
                builder: (context, callback) {
                  callback[0]();
                  return IconButton(
                    onPressed: () async {
                      bool playing = await AudioManager.instance.playOrPause();
                      playing == true ? callback[1]() : callback[2]();
                      print("await -- $playing");
                    },
                    padding: const EdgeInsets.all(0.0),
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48.0,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              // child: IconButton(
              //   onPressed: () async {
              //     bool playing = await AudioManager.instance.playOrPause();

              //     print("await -- $playing");
              //   },
              //   padding: const EdgeInsets.all(0.0),
              //   icon: Icon(
              //     isPlaying ? Icons.pause : Icons.play_arrow,
              //     size: 48.0,
              //     color: Colors.white,
              //   ),
              // ),
            ),
            IconButton(
                iconSize: 36,
                icon: Icon(
                  Icons.skip_next,
                  color: Colors.black,
                ),
                onPressed: () => AudioManager.instance.next()),
            IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Colors.black.withOpacity(.5),
                ),
                onPressed: () {
                  print("click menu");
                }),
          ],
        ),
      ),
    ]);
  }

  Widget getPlayModeIcon(PlayMode playMode) {
    switch (playMode) {
      case PlayMode.sequence:
        return Icon(
          Icons.repeat,
          color: Colors.black.withOpacity(.5),
        );
      case PlayMode.shuffle:
        return Icon(
          Icons.shuffle,
          color: Colors.black.withOpacity(.5),
        );
      case PlayMode.single:
        return Icon(
          Icons.repeat_one,
          color: Colors.black.withOpacity(.5),
        );
    }
    return Container();
  }

  Widget songProgress(BuildContext context) {
    var style = TextStyle(color: Colors.black);
    return Column(
      children: <Widget>[
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbColor: Colors.blueAccent,
            overlayColor: Colors.blue,
            thumbShape: RoundSliderThumbShape(
              disabledThumbRadius: 8,
              enabledThumbRadius: 8,
            ),
            overlayShape: RoundSliderOverlayShape(
              overlayRadius: 10,
            ),
            activeTrackColor: Colors.blueAccent,
            inactiveTrackColor: Colors.grey,
          ),
          child: Slider(
            value: _slider ?? 0,
            onChanged: (value) {
              setState(() {
                _slider = value;
              });
            },
            onChangeEnd: (value) {
              if (_duration != null) {
                Duration msec = Duration(
                    milliseconds: (_duration.inMilliseconds * value).round());
                AudioManager.instance.seekTo(msec);
              }
            },
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _formatDuration(_position),
                style: style,
              ),
              Text(
                _formatDuration(_duration),
                style: style,
              ),
            ],
          ),
        )
      ],
    );
  }

  String _formatDuration(Duration d) {
    if (d == null) return "--:--";
    int minute = d.inMinutes;
    int second = (d.inSeconds > 60) ? (d.inSeconds % 60) : d.inSeconds;
    String format = ((minute < 10) ? "0$minute" : "$minute") +
        ":" +
        ((second < 10) ? "0$second" : "$second");
    return format;
  }

  Widget volumeFrame() {
    return Row(children: <Widget>[
      IconButton(
          padding: EdgeInsets.all(0),
          icon: Icon(
            Icons.audiotrack,
            color: Colors.black,
          ),
          onPressed: () {
            AudioManager.instance.setVolume(0);
          }),
      Expanded(
          child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 0),
              child: Slider(
                value: _sliderVolume ?? 0,
                onChanged: (value) {
                  setState(() {
                    _sliderVolume = value;
                    AudioManager.instance.setVolume(value, showVolume: true);
                  });
                },
              )))
    ]);
  }
}
