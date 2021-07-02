import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' as s;

import 'package:yaml/yaml.dart';
import 'package:just_audio/just_audio.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool playing = false;
  int lastScore = 0;
  List<String> players = [];

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
                  players: players,
                  onStart: (int tasksCount, List<String> players) {
                    // TODO
                    setState(() {
                      playing = true;
                    });
                  },
                )
              else
                _Game(
                  players: players,
                  onFinish: (int score) async {
                    final player = AudioPlayer();
                    var _ = await player.setAsset('assets/alarm.wav');
                    player.play();

                    setState(() {
                      // TODO: players passing
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
  final List<String> players;
  final void Function(int tasksCount, List<String> players) onStart;

  const _Lobby({required this.players, required this.onStart, Key? key})
      : super(key: key);

  @override
  __LobbyState createState() => __LobbyState();
}

class __LobbyState extends State<_Lobby> {
  double tasksCount = 5.0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hra Úkoly', style: Theme.of(context).textTheme.headline2),
          // TODO: add players
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Počet úkolů ve hře: ${tasksCount.toInt()}0'),
                Slider(
                  value: tasksCount,
                  onChanged: (newCount) {
                    setState(() {
                      tasksCount = newCount;
                    });
                  },
                  divisions: 10,
                  min: 5,
                  max: 15,
                  label: "${tasksCount.toInt()}0",
                )
              ],
            ),
          ),
          ElevatedButton(
            child: const Text('Zahájit hru'),
            onPressed: () {
              widget.onStart(
                  tasksCount.toInt() * 10, <String>['players']); // TODO
            },
          ),
        ],
      ),
    );
  }
}

class _Game extends StatefulWidget {
  final void Function(int score) onFinish;
  final List<String> players;

  const _Game({required this.players, required this.onFinish, Key? key})
      : super(key: key);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<_Game> {
  late List<String> tasks;
  String task = "";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      await setUpTasks();
      setNextTask();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              task,
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

  void buttonClickedHandler({required bool correct}) {
    setNextTask();
  }

  Future<void> setUpTasks() async {
    final data = await s.rootBundle.loadString('assets/tasks.yaml');
    final mapData = loadYamlDocuments(data);

    tasks = <String>[];
    for (var item in mapData) {
      //tasks.add(item);
    }
    print(mapData);
  }

  void setNextTask() {
    var random = Random();
    setState(() {
      task = tasks[random.nextInt(tasks.length)];
    });
  }
}
