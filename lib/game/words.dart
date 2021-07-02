import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' as s;

import 'package:yaml/yaml.dart';
import 'package:just_audio/just_audio.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({Key? key}) : super(key: key);

  @override
  _WordsScreenState createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  bool playing = false;
  int lastScore = 0;
  int time = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Align(alignment: Alignment.topLeft, child: BackButton()),
              if (lastScore != 0) Text('poslední skóre $lastScore'),
              if (!playing)
                _Lobby(
                  initTime: time,
                  onStart: (int selectedTime) {
                    setState(() {
                      playing = true;
                      time = selectedTime;
                    });
                  },
                )
              else
                _Game(
                  time: time,
                  onFinish: (int score) async {
                    final player = AudioPlayer();
                    var _ = await player.setAsset('assets/alarm.wav');
                    player.play();

                    setState(() {
                      playing = false;
                      lastScore = score;
                    });
                  },
                ),
            ],
          )),
    );
  }
}

class _Lobby extends StatefulWidget {
  final int initTime;
  final void Function(int) onStart;

  const _Lobby({required this.initTime, required this.onStart, Key? key})
      : super(key: key);

  @override
  __LobbyState createState() => __LobbyState();
}

class __LobbyState extends State<_Lobby> {
  late double time;

  @override
  void initState() {
    super.initState();
    time = (widget.initTime / 10).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hra Kufr', style: Theme.of(context).textTheme.headline2),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Délka hry: ${time.toInt()}0 s'),
                Slider(
                  value: time,
                  onChanged: (newTime) {
                    setState(() {
                      time = newTime;
                    });
                  },
                  divisions: 17,
                  min: 1,
                  max: 18,
                  label: "${time.toInt()}0 s",
                )
              ],
            ),
          ),
          ElevatedButton(
            child: const Text('Zahájit hru'),
            onPressed: () {
              widget.onStart(time.toInt() * 10);
            },
          )
        ],
      ),
    );
  }
}

class _Game extends StatefulWidget {
  final void Function(int score) onFinish;
  final int time;

  const _Game({required this.time, required this.onFinish, Key? key})
      : super(key: key);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<_Game> {
  late int time;
  late Timer _timer;
  int score = 0;
  late List<String> words;
  String word = "";

  void startTimer() {
    time = widget.time;
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (time == 0) {
          setState(() {
            timer.cancel();
          });
          widget.onFinish(score);
        } else {
          setState(() {
            time--;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    startTimer();

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await setUpWords();
      setNextWord();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('čas: $time'),
          Text('skóre: $score'),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              word,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 100.0,
                height: 50.0,
                child: ElevatedButton(
                  child: const Text('špatně'),
                  style: ElevatedButton.styleFrom(primary: Colors.red),
                  onPressed: () => buttonClickedHandler(correct: false),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(),
              ),
              SizedBox(
                width: 100.0,
                height: 50.0,
                child: ElevatedButton(
                  child: const Text('správně'),
                  style: ElevatedButton.styleFrom(primary: Colors.blue),
                  onPressed: () => buttonClickedHandler(correct: true),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void buttonClickedHandler({required bool correct}) {
    if (correct) {
      setState(() {
        score++;
      });
    }

    setNextWord();
  }

  Future<void> setUpWords() async {
    final data = await s.rootBundle.loadString('assets/words.yaml');
    final mapData = loadYaml(data);

    words = <String>[];
    for (var item in mapData) {
      words.add(item);
    }
  }

  void setNextWord() {
    var random = Random();
    setState(() {
      word = words[random.nextInt(words.length)];
    });
  }
}
