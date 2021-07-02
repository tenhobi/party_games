import 'package:flutter/material.dart';
import 'package:party_games/game/tasks.dart';
import 'package:party_games/game/topics.dart';
import 'package:party_games/game/words.dart';

void main() {
  runApp(const PartyGamesApp());
}

class Game {
  final String title;
  final int id;

  Game(this.title, this.id);
}

class PartyGamesApp extends StatefulWidget {
  const PartyGamesApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PartyGamesAppState();
}

class _PartyGamesAppState extends State<PartyGamesApp> {
  Game? _selectedGame;

  List<Game> games = [
    Game('Kufr', 1),
    Game('Úkoly', 2),
    Game('Témata', 3),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Party Games',
      home: Navigator(
        pages: [
          MaterialPage(
            key: const ValueKey('GamesListPage'),
            child: GamesListScreen(
              games: games,
              onTapped: _handleGameTapped,
            ),
          ),
          if (_selectedGame != null) GameDetailsPage(game: _selectedGame!)
        ],
        onPopPage: (route, result) {
          if (!route.didPop(result)) {
            return false;
          }

          setState(() {
            _selectedGame = null;
          });

          return true;
        },
      ),
    );
  }

  void _handleGameTapped(Game game) {
    setState(() {
      _selectedGame = game;
    });
  }
}

class GameDetailsPage extends Page {
  final Game game;

  GameDetailsPage({
    required this.game,
  }) : super(key: ValueKey(game));

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
      settings: this,
      builder: (BuildContext context) {
        switch (game.id) {
          case 1:
            return const WordsScreen();
          case 2:
            return const TasksScreen();
          case 3:
            return const TopicsScreen();
          default:
            return const Text("Unknown game");
        }
      },
    );
  }
}

class GamesListScreen extends StatelessWidget {
  final List<Game> games;
  final ValueChanged<Game> onTapped;

  const GamesListScreen({
    required this.games,
    required this.onTapped,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Párty hry'),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.center,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var game in games)
              ListTile(
                title: Center(child: Text(game.title)),
                onTap: () => onTapped(game),
              )
          ],
        ),
      ),
    );
  }
}
