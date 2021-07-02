import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' as s;

import 'package:yaml/yaml.dart';
import 'package:just_audio/just_audio.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({Key? key}) : super(key: key);

  @override
  _TopicsScreenState createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  bool playing = false;
  int time = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const Align(alignment: Alignment.topLeft, child: BackButton()),
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
                  onFinish: () async {
                    final player = AudioPlayer();
                    var _ = await player.setAsset('assets/alarm.wav');
                    player.play();

                    setState(() {
                      playing = false;
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
          Text('Hra Témata', style: Theme.of(context).textTheme.headline2),
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
                  divisions: 15,
                  min: 3,
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
  final void Function() onFinish;
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
  late List<String> topics;
  String topic = "";

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
          widget.onFinish();
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
      await setUpTopics();
      setNextTopic();
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
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              topic,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline2,
            ),
          ),
          ElevatedButton(
            child: const Text('Ukončit'),
            style: ElevatedButton.styleFrom(primary: Colors.purple),
            onPressed: () => buttonClickedHandler(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void buttonClickedHandler() {
    widget.onFinish();
  }

  Future<void> setUpTopics() async {
    final data = await s.rootBundle.loadString('assets/topics.yaml');
    final mapData = loadYaml(data);

    topics = <String>[];
    for (var item in mapData) {
      topics.add(item);
    }
  }

  void setNextTopic() {
    var random = Random();
    setState(() {
      topic = topics[random.nextInt(topics.length)];
    });
  }
}
