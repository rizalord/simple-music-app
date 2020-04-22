import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:my_music/play_music.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  List<String> data = [];
  List<SongInfo> songs = [];
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();

  @override
  void initState() {
    super.initState();
    getHistory();
    getMusic();
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
      tmp.forEach((element) {
        print(element.filePath);
      });
      setState(() {
        songs = tmp;
      });
    });
  }

  void getHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> prevData = prefs.getStringList('history');
    setState(() {
      data = prevData != null ? prevData : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.chevron_left,
              color: Colors.black,
              size: 30,
            ),
          ),
          title: Text(
            'Terkini',
            style: TextStyle(
              color: Colors.black.withOpacity(.8),
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: MainHistory(data: data, songs: songs),
      ),
    );
  }
}

class MainHistory extends StatefulWidget {
  final List<String> data;
  final List<SongInfo> songs;

  MainHistory({this.data, this.songs});

  @override
  _MainHistoryState createState() => _MainHistoryState();
}

class _MainHistoryState extends State<MainHistory> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.data.length,
      itemBuilder: (ctx, idx) => ListTile(
        onTap: () {
          Map data = json.decode(widget.data[idx]);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PlayMusic(
                setState: this.setState,
                playlist: widget.songs,
                secondData: data,
              ),
            ),
          );
        },
        contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        title: Text(
          json.decode(widget.data[idx])['title'],
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          json.decode(widget.data[idx])['artist'] +
              ' | ' +
              json.decode(widget.data[idx])['album'],
          overflow: TextOverflow.ellipsis,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.4),
            ),
            child: Image.file(
              File(
                json.decode(widget.data[idx])['image'],
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
