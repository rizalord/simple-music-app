import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:touchable_opacity/touchable_opacity.dart';
import './../play_music.dart';

class CardMusic extends StatelessWidget {
  final SongInfo data;
  final List<SongInfo> playlist;
  final Function setState;

  const CardMusic({Key key, this.data, this.playlist, this.setState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TouchableOpacity(
      activeOpacity: 0.7,
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PlayMusic(
                      single : data,
                      playlist : playlist,
                      setState: setState
                    )));
      },
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 3,
                        offset: Offset(0, 5),
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: data.albumArtwork != null
                              ? Image.file(
                                  File(data.albumArtwork),
                                  fit: BoxFit.cover,
                                )
                              : Image.asset('images/music_logo.jpg',
                                  fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: Offset(0, 2),
                                  blurRadius: 1,
                                  spreadRadius: 1,
                                )
                              ]),
                          child: Icon(
                            Icons.play_arrow,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      )
                    ],
                  )),
            ),
            Text(
              data.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Shawn Mandes',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.black.withOpacity(0.4),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
