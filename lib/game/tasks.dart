import 'dart:async';
import 'dart:collection';

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
  List<String> players = [];
  int taskCount = 50;

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
                  players: players,
                  onStart: (int newTasksCount, List<String> newPlayers) {
                    setState(() {
                      players = newPlayers;
                      taskCount = newTasksCount;
                      playing = true;
                    });
                  },
                )
              else
                _Game(
                  taskCount: taskCount,
                  players: players,
                  onFinish: () async {
                    setState(() {
                      playing = false;
                    });

                    final player = AudioPlayer();
                    var _ = await player.setAsset('assets/alarm.wav');
                    player.play();
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
  late final playersController =
      TextEditingController(text: widget.players.join(', '));

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hra Úkoly', style: Theme.of(context).textTheme.headline2),
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
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Column(
              children: [
                const Text('Hráči:'),
                TextField(
                  controller: playersController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Hráči odděleni čárkou',
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            child: const Text('Zahájit hru'),
            onPressed: () {
              List<String> players =
                  playersController.text.replaceAll(' ', '').split(',');
              widget.onStart(tasksCount.toInt() * 10, players);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    playersController.dispose();
    super.dispose();
  }
}

class _Game extends StatefulWidget {
  final int taskCount;
  final void Function() onFinish;
  final List<String> players;

  const _Game({
    required this.taskCount,
    required this.players,
    required this.onFinish,
    Key? key,
  }) : super(key: key);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<_Game> {
  late Queue<Task> tasks;
  Task task = Task(type: 'task', value: 'loading...');
  int round = 0;

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
          Text('$round / ${widget.taskCount}'),
          TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(task.getTitle()),
                      content: Text(task.getHint()),
                    );
                  },
                );
              },
              child: Text(task.getTitle())),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(
              task.value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 50.0,
                child: ElevatedButton(
                  child: const Text('Další úkol'),
                  style: ElevatedButton.styleFrom(primary: Colors.blue),
                  onPressed: () => setNextTask(),
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
    final yamlData = loadYaml(data);

    final tasksList = <Task>[];
    for (YamlMap item in yamlData) {
      final List<String> playersShuffle = List.from(widget.players);
      playersShuffle.shuffle();

      if (item.containsKey('task')) {
        final value =
            _replaceReferences(item['task'].toString(), playersShuffle);
        tasksList.add(Task(type: 'task', value: value));
      }
      if (item.containsKey('question')) {
        final value =
            _replaceReferences(item['question'].toString(), playersShuffle);
        tasksList.add(Task(type: 'question', value: value));
      }
      if (item.containsKey('vote')) {
        final value =
            _replaceReferences(item['vote'].toString(), playersShuffle);
        tasksList.add(Task(type: 'vote', value: value));
      }
      if (item.containsKey('never')) {
        final value =
            _replaceReferences(item['never'].toString(), playersShuffle);
        tasksList.add(Task(type: 'never', value: value));
      }
      if (item.containsKey('carousel')) {
        final value =
            _replaceReferences(item['carousel'].toString(), playersShuffle);
        tasksList.add(Task(type: 'carousel', value: value));
      }
    }

    tasksList.shuffle();
    tasks = Queue.from(tasksList);
  }

  String _replaceReferences(String text, List<String> players) {
    if (!text.contains('\$')) return text;

    if (text.contains('\$')) {
      int i = -1;
      text = text.replaceAllMapped('\$', (Match match) {
        i++;
        return players[i];
      });
    }

    return text;
  }

  void setNextTask() {
    if (round >= widget.taskCount) {
      widget.onFinish();
    }

    Task selectedTask = tasks.first;
    tasks.removeFirst();

    setState(() {
      task = selectedTask;
      round++;
    });
  }
}

class Task {
  String type;
  String value;

  Task({required this.type, required this.value});

  String getHint() {
    switch (type) {
      case 'task':
        return 'Hráč jednoduše musí splnit zadaný úkol.';
      case 'question':
        return 'Hráči se musí shodnout na jednom hráči, na kterého otázka nejvíce sedí.';
      case 'vote':
        return 'Hráči dají jednu pěst před sebe a po odpočtu 3, 2, 1, teď hlasují palcem nahoru pro první variantu a palcem dolu pro druhou variantu. Menšina po hlasování se jednou napije.';
      case 'never':
        return 'Přečtěte větu začínající slovy "nikdy jsem..." a nějaká činnost. Pokud jste to dělali, napijte se.';
      case 'carousel':
        return 'Dle zadaného tématu hráči postupně říkají své odpovědi. Hra probíhá po směru hodinových ručiček. Hráč, který nedokáže do 5 sekund odpovědět pije dle zadání.';
      default:
        return 'Neznámý typ úkolu.';
    }
  }

  String getTitle() {
    switch (type) {
      case 'task':
        return 'ÚKOL';
      case 'question':
        return 'OTÁZKA';
      case 'vote':
        return 'CO BYS RADŠI?';
      case 'never':
        return 'NIKDY JSEM';
      case 'carousel':
        return 'KOLOTOČ';
      default:
        return 'Neznámý typ úkolu.';
    }
  }
}
