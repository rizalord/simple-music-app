import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:my_music/pages/favorite.dart';
import 'package:my_music/pages/history.dart';
import 'package:my_music/play_music.dart';
import 'package:touchable_opacity/touchable_opacity.dart';
import 'dart:io';
import 'component/card_music.dart';

class MainHome extends StatefulWidget {
  final List<SongInfo> all;
  final Function shuffle, reverse, search;

  const MainHome(
      {Key key,
      @required this.itemWidth,
      @required this.itemHeight,
      this.all,
      this.shuffle,
      this.reverse,
      this.search})
      : super(key: key);

  final double itemWidth;
  final double itemHeight;

  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> with TickerProviderStateMixin {
  Animation showSearchAnimation, showSearchNextAnimation;
  AnimationController animSearchController, animSearchNextController;
  bool showSearch = false;
  bool isGrid = true;
  TextEditingController _controller = TextEditingController();

  void initState() {
    super.initState();
    setAnimation();
  }

  void setAnimation() {
    // set controller
    animSearchController =
        AnimationController(duration: Duration(milliseconds: 250), vsync: this);
    animSearchNextController =
        AnimationController(duration: Duration(milliseconds: 250), vsync: this);

    // set animation 2
    showSearchNextAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: animSearchNextController, curve: Curves.fastOutSlowIn),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          animSearchController.reverse();
        }
      });
    // set animation 1
    showSearchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animSearchController,
        curve: Curves.easeOut,
      ),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          animSearchNextController.forward();
        }
      });
  }

  void showingSearch() {
    if (showSearch == false) {
      animSearchController.forward();
    } else {
      animSearchNextController.reverse();
    }
    showSearch = !showSearch;
  }

  void changeGrid() {
    setState(() {
      isGrid = !isGrid;
    });
  }

  void boilerSearch() {
    widget.search(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HomeHeader(searchCallback: this.showingSearch),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15),
              margin: EdgeInsets.only(top: 10),
              width: MediaQuery.of(context).size.width,
              height: showSearchAnimation.value * 50,
              child: Form(
                child: Transform.translate(
                  offset: Offset(
                      MediaQuery.of(context).size.width *
                          showSearchNextAnimation.value,
                      0),
                  child: Container(
                    width: MediaQuery.of(context).size.width * .7,
                    decoration: BoxDecoration(
                        color: Theme.of(context).accentColor.withOpacity(.9),
                        borderRadius: BorderRadius.circular(15)),
                    child: TextFormField(
                      controller: _controller,
                      onEditingComplete: this.boilerSearch,
                      style: TextStyle(color: Theme.of(context).primaryColor),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 13),
                        border: InputBorder.none,
                        hintText: 'Cari lagu di perangkat',
                        hintStyle: TextStyle(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            FeatureWidget(),
            ShuffleSetting(
                shuffle: widget.shuffle,
                reverse: widget.reverse,
                changeGrid: this.changeGrid),
            CustomDivider(),
            !isGrid
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: widget.all.length,
                    itemBuilder: (cntx, idx) {
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayMusic(
                                    single: widget.all[idx],
                                    playlist: widget.all,
                                    setState: this.setState),
                              ));
                        },
                        title: Text(
                          widget.all[idx].title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          (widget.all[idx].artist != null
                                  ? widget.all[idx].artist
                                  : 'Artis tak diketahui') +
                              ' | ' +
                              (widget.all[idx].album != null
                                  ? widget.all[idx].album
                                  : 'Artis tak diketahui'),
                          overflow: TextOverflow.ellipsis,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 2, horizontal: 15),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.4),
                            ),
                            child:
                                Image.file(File(widget.all[idx].albumArtwork)),
                          ),
                        ),
                      );
                    },
                  )
                : Flexible(
                    fit: FlexFit.loose,
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: (widget.itemWidth / widget.itemHeight),
                      children: widget.all.length != 0
                          ? widget.all
                              .map(
                                (e) => GridTile(
                                  child: CardMusic(
                                      data: e,
                                      playlist: widget.all,
                                      setState: this.setState),
                                ),
                              )
                              .toList()
                          : [],
                      padding: EdgeInsets.only(
                          left: 15, right: 15, bottom: 10, top: 0),
                      mainAxisSpacing: 13.0,
                      crossAxisSpacing: 10.0,
                    ),
                  )
          ],
        ),
      ),
    ));
  }
}

class HomeHeader extends StatelessWidget {
  final Function searchCallback;

  const HomeHeader({Key key, this.searchCallback}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            onPressed: () {
              Fluttertoast.showToast(
                msg: 'Feature disabled!',
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black,
                textColor: Colors.white,
                fontSize: 16.0
              );
            },
            icon: Icon(Icons.sort, color: Theme.of(context).accentColor),
          ),
          Text('Music', style: Theme.of(context).primaryTextTheme.headline1),
          IconButton(
            onPressed: () {
              this.searchCallback();
            },
            icon: Icon(Icons.search, color: Theme.of(context).accentColor),
          ),
        ],
      ),
    );
  }
}

class FeatureWidget extends StatelessWidget {
  const FeatureWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 100,
      // color: Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          TouchableOpacity(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => HistoryPage()));
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Icon(
                      Icons.access_time,
                      size: 30,
                      color: Colors.redAccent,
                    ),
                  ),
                  Text(
                    'Terkini',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TouchableOpacity(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => FavoritePage()));
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child:
                        Icon(Icons.favorite, size: 30, color: Colors.redAccent),
                  ),
                  Text(
                    'Favorit',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  )
                ],
              ),
            ),
          ),
          TouchableOpacity(
            onTap: () {
              Fluttertoast.showToast(
                msg: 'Feature disabled!',
                toastLength: Toast.LENGTH_SHORT,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.black,
                textColor: Colors.white,
                fontSize: 16.0
              );
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Icon(Icons.library_music,
                        size: 30, color: Colors.redAccent),
                  ),
                  Text(
                    'Playlist',
                    style: TextStyle(
                      color: Colors.redAccent,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CustomDivider extends StatelessWidget {
  const CustomDivider({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      height: 40,
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'Lagu',
            style:
                TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 8),
              height: 1,
              color: Colors.black.withOpacity(0.2),
            ),
          )
        ],
      ),
    );
  }
}

class ShuffleSetting extends StatelessWidget {
  final Function shuffle, reverse, changeGrid;

  const ShuffleSetting({Key key, this.shuffle, this.reverse, this.changeGrid})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 30,
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TouchableOpacity(
            activeOpacity: 0.8,
            onTap: () {
              this.shuffle();
            },
            child: Container(
              height: 30,
              padding: EdgeInsets.only(left: 10, right: 12),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(MediaQuery.of(context).size.width),
                color: Colors.black.withOpacity(0.7),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.shuffle,
                    color: Theme.of(context).primaryColor,
                    size: 15,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 5),
                    child: Text(
                      'Acak daftar',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Container(
            height: 30,
            width: 30 * 2.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TouchableOpacity(
                  child: Icon(Icons.swap_vert),
                  onTap: () {
                    this.reverse();
                  },
                  activeOpacity: 0.8,
                ),
                TouchableOpacity(
                  child: Icon(Icons.format_list_bulleted),
                  onTap: () {
                    this.changeGrid();
                  },
                  activeOpacity: 0.8,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
