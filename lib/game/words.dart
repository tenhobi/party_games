import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class WordsScreen extends StatefulWidget {
  const WordsScreen({Key? key}) : super(key: key);

  @override
  _WordsScreenState createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  bool playing = false;
  int lastScore = 0;
  int? time;

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
                _Lobby(onStart: (int selectedTime) {
                  setState(() {
                    playing = true;
                    time = selectedTime;
                  });
                })
              else
                _Game(
                  time: time ?? 30,
                  onFinish: (int score) {
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
  final void Function(int) onStart;

  const _Lobby({required this.onStart, Key? key}) : super(key: key);

  @override
  __LobbyState createState() => __LobbyState();
}

class __LobbyState extends State<_Lobby> {
  double time = 3;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Kufr', style: Theme.of(context).textTheme.headline2),
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
                  divisions: 9,
                  min: 1,
                  max: 12,
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
          widget.onFinish(3);
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
    startTimer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text('$time');
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
