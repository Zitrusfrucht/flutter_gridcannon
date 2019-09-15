import 'dart:math';

import 'package:flutter/material.dart';
import 'package:solitaire_flutter/playing_card.dart';

import 'card_stack.dart';

class GameScreenGC extends StatefulWidget {
  @override
  _GameScreenStateGC createState() => _GameScreenStateGC();
}

class Grid<T> {
  int width;
  int height;
  List<T> values;

  Grid(this.width, this.height, T Function(int index) initializer) {
    values = List.generate(width * height, initializer);
  }

  T getAt(int row, int col) {
    return values[row * width + col];
  }

  setAt(int row, int col, T value) {
    values[row * width + col] = value;
  }
}

class PlayingField {
  static const int gridWidth = 3;
  static const int gridHeight = 3;
  Random rng;

  List<List<CardStack>> enemyLines;
  Grid<CardStack> playerGrid;

  CardStack shameCards = CardStack();
  CardStack handCards = CardStack();

  List<List<PlayingCard>> playerCards =
      List.generate(gridWidth * gridHeight, (i) {
    return [];
  });

  PlayingField() {
    rng = Random();
    var deck = PlayingCard.getNewDeck();
    deck.shuffle(rng);

    playerGrid = Grid(gridWidth, gridHeight, (int i) => CardStack());
    List<PlayingCard> royalTemp = [];

    for (int i = 0; i < playerGrid.width; i++) {
      for (int j = 0; j < playerGrid.height; j++) {
        if (i != 1 || j != 1) {
          while (playerGrid.getAt(i, j).cards.isEmpty) {
            var card = deck.removeLast();
            if (card.cardType.index >= CardType.jack.index) {
              royalTemp.add(card);
            } else {
              card.faceUp = rng.nextInt(2) > 0;
              playerGrid.getAt(i, j).add(card);
            }
          }
        }
      }
    }

    handCards.addAll(royalTemp);
    handCards.addAll(deck);
  }
}

enum Direction { up, down, left, right }

class _GameScreenStateGC extends State<GameScreenGC> {
  PlayingField playingField;

  @override
  void initState() {
    super.initState();
    _initialiseGame();
  }

  void _initialiseGame() {
    setState(() {
      playingField = PlayingField();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          title: Text("Flutter Solitaire"),
          elevation: 0.0,
          backgroundColor: Colors.green,
          actions: <Widget>[
            InkWell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
              splashColor: Colors.white,
              onTap: () {
                _initialiseGame();
              },
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              Container(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: List.generate(9, (int i) {
                    return FittedBox(
                        fit: BoxFit.fitHeight,
                        child: playingField.playerGrid.values[i]
                            .getWidget(setState));
                  }),
                ),
              )
              ,
              playingField.handCards.getWidget(setState),
              SliverGrid.count()
            ],
          ),
        ));
  }
}
