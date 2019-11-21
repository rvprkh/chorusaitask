import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

//PODO for transcripts
class Transcript {
  final String snippet;
  final String speaker;
  final String time;

  Transcript({this.snippet, this.speaker, this.time});

  factory Transcript.fromJSON(Map<String, dynamic> json) {
    return Transcript(
      snippet: json['snippet'].toString(),
      speaker: json['speaker'].toString(),
      time: json['time'].toString(),
    );
  }
}

//Mediator object to map the transcripts into a list
class TranscriptList {
  final List<Transcript> transcripts;

  TranscriptList({this.transcripts});

  factory TranscriptList.fromJSON(List<dynamic> json) {
    List<Transcript> trans = json.map((i) => Transcript.fromJSON(i)).toList();
    trans.sort((a,b) => double.parse(a.time).compareTo(double.parse(b.time)));
    return TranscriptList(
      transcripts: trans
    );
  }

  List<Transcript> getTranscripList(){
    return this.transcripts;
  }
}

//Http call to transcript api
Future<TranscriptList> fetchTranscript(String _url) async {
    final response =
        await http.get(_url);

    if (response.statusCode == 200) {
      return TranscriptList.fromJSON(json.decode(response.body));
    } else {
      throw Exception('Failed to load post');
    }
  }

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chorus AI Task',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Chorus AI Task'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/*First page to enter call id. It uses the id given in task requirement as a default.
  If an id is typed in, that id will be used in the video and transcript fetch calls*/
class _MyHomePageState extends State<MyHomePage> {
  String videoId = '4d79041e-f25f-421d-9e5f-3462459b9934';
  
  Widget footerContainer = Container(
    margin: EdgeInsets.fromLTRB(0, 30, 0, 0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        SvgPicture.asset(
          'assets/chorus-logo.svg'
        ),
        SizedBox(height: 30),
      ],
    ),

  );
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color.fromRGBO(0, 167, 209, 1),
              style: BorderStyle.solid,
              width: 5
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: TextField(
                onChanged: (text){
                  videoId = text;
                },
                decoration: InputDecoration(
                  hintText: videoId,
                ),
              ),
            ),
            Text(
              'Above default id will be used if no id is provided.'
            ),
            SizedBox(height: 30),
            RaisedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoTranscript(id: videoId),
                  ),
                );
              },
              child: const Text(
                'Get Details',
                style: TextStyle(fontSize: 20)
              ),
            ),
            footerContainer,
          ],
        ),
      ),
    );
  }
}

class VideoTranscript extends StatefulWidget {
  final String id;

  VideoTranscript({Key key, @required this.id}) : super(key: key);

  @override
  VideoTranscriptScreen createState()  => VideoTranscriptScreen(id: this.id);
}

class VideoTranscriptScreen extends State<VideoTranscript> {
  String id;
  List<Transcript> transcriptList;
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  VideoTranscriptScreen({Key key, @required this.id});
  
  @override
  void initState(){
    //Get the transcripts and saves to a local list varible
    fetchTranscript('https://static.chorus.ai/api/'+this.id+'.json').then((result) {
        setState(() {
          transcriptList = result.getTranscripList();
        });
      }
    );
    
    _controller = VideoPlayerController.network(
      'https://static.chorus.ai/api/'+this.id+'.mp4',
    );
    _initializeVideoPlayerFuture = _controller.initialize();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    Widget videoContainer = Container(
      width: MediaQuery.of(context).size.width * 0.6,
      child: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                FloatingActionButton(
                  backgroundColor: Color.fromRGBO(0, 0, 0, 0),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                  child: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );

    Widget transcriptContainer = Container(
      width: MediaQuery.of(context).size.width * 0.65,
      height: MediaQuery.of(context).size.height * 0.2,
      child: Row(
        children: <Widget>[
          Flexible(
            fit: FlexFit.loose,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: transcriptList != null ? transcriptList.length : 0,
              itemBuilder: (context, position){
                return Container(
                  margin: EdgeInsets.fromLTRB(0, 8, 0, 6),
                  child: Row(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.all(5),
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: transcriptList[position].speaker == 'Cust' ? Color.fromRGBO(238, 110, 255, 1) : Color.fromRGBO(0, 167, 209, 1),
                              ),
                              color: transcriptList[position].speaker == 'Cust' ? Color.fromRGBO(238, 110, 255, 0.1) : Color.fromRGBO(0, 167, 209, 0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                transcriptList[position].speaker,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color.fromRGBO(51, 51, 51, 1)
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.all(5),
                                padding: EdgeInsets.all(5),
                                width: MediaQuery.of(context).size.width * 0.5,
                                color: Color.fromRGBO(247, 247, 247, 1),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      transcriptList[position].snippet
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    Widget mainContainer = Container(
      margin: EdgeInsets.fromLTRB(50, 100, 50, 50),
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.6,
      color: Color.fromRGBO(255, 255, 255, 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            children: <Widget>[
              SizedBox(height: 10),
              Text(
                'Chorus AI Task Video',
                style: TextStyle(
                  color: Color.fromRGBO(51, 51, 51, 1.0),
                  fontFamily: 'NotoSans-Regular',
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              videoContainer,
              SizedBox(height: 30),
              transcriptContainer,
            ],
          ),
        ],
      )
    );

    Widget footerContainer = Container(
      margin: EdgeInsets.fromLTRB(0, 80, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          SvgPicture.asset(
            'assets/chorus-logo.svg'
          ),
          SizedBox(height: 30),
        ],
      ),

    );

    return Scaffold(
      backgroundColor: Color.fromRGBO(247, 247, 247, 1.0),
      body: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color.fromRGBO(0, 167, 209, 1),
              style: BorderStyle.solid,
              width: 5
            ),
          ),
        ),
        child: Column(
          children: <Widget>[
            mainContainer,
            footerContainer,
          ],
        ),
      ),
    );
  }
}
