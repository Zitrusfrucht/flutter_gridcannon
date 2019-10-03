import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:solitaire_flutter/playing_card.dart';
import 'package:solitaire_flutter/settings.dart';

import 'card_stack.dart';
import 'package:url_launcher/url_launcher.dart';

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

enum Direction { up, down, left, right }

Direction intToDir(int i) {
  switch (i) {
    case 0:
      return Direction.up;
    case 1:
      return Direction.down;
    case 2:
      return Direction.left;
    case 3:
      return Direction.right;
    default:
      throw ArgumentError("no direction for that value");
  }
}

class _GameScreenStateGC extends State<GameScreenGC> {
  static const int gridWidth = 3;
  static const int gridHeight = 3;
  Random rng;

  List<List<CardStack>> enemyLines;
  Grid<CardStack> playerGrid;

  CardStack shameCards;
  CardStack handCards;
  CardStack goneCards;

  @override
  void initState() {
    super.initState();
    _initialiseGame();
  }

  bool isLastCard(CardStack card) => card.length == 1 && goneCards.isEmpty;

  void errorCheck() {
    int cardCount = 0;
    List<PlayingCard> allCards = [];
    enemyLines.forEach((List<CardStack> stacks) {
      stacks.forEach((stack) {
        allCards.addAll(stack);
        cardCount += stack.length;
      });
    });

    playerGrid.values.forEach((CardStack stack) {
      allCards.addAll(stack);
      cardCount += stack.length;
    });

    allCards.addAll(shameCards);
    allCards.addAll(handCards);
    allCards.addAll(goneCards);

    cardCount += shameCards.length + handCards.length + goneCards.length;

    assert(allCards.length == cardCount, "allcarss wrong!");
    assert(cardCount == PlayingCard.getNewDeck().length,
        "There should be ${PlayingCard.getNewDeck().length} cards but there are $cardCount cards!!\n");

    assert(allCards.length == allCards.toSet().toList().length,
        "None unique cards!");
  }

  List<CardStack> validTargets;

  List<CardStack> getValidTargets(CardStack source) {
    if (validTargets == null) {
      validTargets = [];

      if (shameCards.willAccept(source)) {
        validTargets.add(shameCards);
      }

      playerGrid.values.forEach((CardStack pcs) {
        if (pcs.willAccept(source)) {
          validTargets.add(pcs);
        }
      });

      enemyLines.forEach((List<CardStack> line) {
        line.forEach((CardStack ecs) {
          if (ecs.willAccept(source)) {
            validTargets.add(ecs);
          }
        });
      });
    }
    return validTargets;
  }

  void _initialiseGame() {
    rng = Random();
    List<PlayingCard> deck = PlayingCard.getNewDeck();
    deck.shuffle(rng);

    goneCards = CardStack(draggable: false);

    shameCards = CardStack(
        willAccept: (CardStack source) {
          var willAccept =
              source.last.value < CardType.jack.index && !(isLastCard(source));

          return willAccept;
        },
        onAccept: (CardStack source) {
          setState(() {
            shameCards.add(source.last);
          });
        },
        onDragCompleted: () {
          setState(() {
            shameCards.removeLast();
          });
          errorCheck();
        },
        draggable: false);

    playerGrid = Grid(gridWidth, gridHeight, (int i) {
      return CardStack(
          draggable: false,
          willAccept: (CardStack source) {
            bool willaccept;
            int srcVal = source.last.value;
            if (srcVal >= CardType.jack.index) {
              willaccept = false;
            } else if (isLastCard(source)) {
              willaccept = true;
            } else {
              willaccept = playerGrid.values[i].isEmpty ||
                  srcVal >= playerGrid.values[i].last.value ||
                  srcVal == CardType.ace.index ||
                  srcVal == CardType.joker.index;
            }

            return willaccept;
          },
          onAccept: (CardStack source) {
            setState(() {
              int cardVal = source.last.value;
              var targetStack = playerGrid.values[i];

              if (cardVal == CardType.ace.index ||
                  cardVal == CardType.joker.index) {
                targetStack.forEach((c) => c.faceUp = false);
                goneCards.addAll(targetStack);
                targetStack.clear();
              } else if (isLastCard(source)) {
                var top = targetStack.removeLast();
                shameCards.add(top);
                targetStack.shuffle(rng);
                handCards.addAll(targetStack);
                targetStack.clear();
              }
              targetStack.add(source.last);

              hitCheck(i);
              endCheck();
            });
          },
          onDragCompleted: () {
            errorCheck();
          });
    });

    enemyLines = List.generate(
        4,
        (int i) => List.generate(
            3,
            (int j) => CardStack(
                draggable: false,
                willAccept: (CardStack source) {
                  bool willAccept;
                  if (enemyLines[i][j].isEmpty) {
                    if (source.last.value >= CardType.jack.index) {
                      List<PlayingCard> fitlist = findLargestFit(source.last);
                      print("fitlist is $fitlist");
                      CardStack neighbor = findInsideNeighbor(intToDir(i), j);
                      willAccept = (fitlist.contains(neighbor.last));
                    } else {
                      willAccept = false;
                    }
                  } else {
                    willAccept = enemyLines[i][j].last.faceUp &&
                        source.last.value <= CardType.jack.index &&
                        source.last.value > CardType.ace.index &&
                        enemyLines[i][j].totalValue + source.last.value <= 20;
                  }

                  return willAccept;
                },
                onAccept: (CardStack source) =>
                    {enemyLines[i][j].add(source.last)},
                onDragCompleted: () {
                  setState(() {
                    enemyLines[i][j].removeLast();
                  });
                  errorCheck();
                })));

    // Initial card dealout
    List<PlayingCard> royalTemp = [];
    for (int row = 0; row < playerGrid.width; row++) {
      for (int col = 0; col < playerGrid.height; col++) {
        if (row != 1 || col != 1) {
          while (playerGrid.getAt(row, col).cards.isEmpty) {
            PlayingCard card = deck.removeLast();
            if (card.value >= CardType.jack.index) {
              royalTemp.add(card);
            } else {
              card.faceUp = true; //rng.nextInt(2) > 0;
              playerGrid.getAt(row, col).add(card);
            }
          }
        }
      }
    }

    handCards = CardStack(
        willAccept: (CardStack src) => false,
        onAccept: (CardStack src) => {},
        onDragStarted: () {
          var validTargets = getValidTargets(handCards);
          setState(() {
            validTargets.forEach((CardStack target) {
              target.highlight();
            });
          });
        },
        onDragEnd: (_) {
          setState(() {
            unHighlightAll();
          });
        },
        onDragCompleted: () {
          setState(() {
            handCards.removeLast();
            if (handCards.isEmpty) {
              if (goneCards.isEmpty) {
                print("Game over");
                _showDialog(
                    "Oh oh",
                    "you played all your cards without killing the enemies. You lost",
                    "Try Again",
                    _initialiseGame);
              } else {
                goneCards.forEach((c) => (c.faceUp = true));
                goneCards.shuffle(rng);
                handCards.addAll(goneCards);
                goneCards.clear();
              }
            }
          });
          errorCheck();
        });

    handCards.addAll(deck);
    handCards.addAll(royalTemp);

    handCards.forEach((card) => card.faceUp = true);

    setState(() {});
  }

  List<PlayingCard> findLargestFit(PlayingCard card) {
    PlayingCard bestMatch;

    playerGrid.values.forEach((stack) {
      if (stack.isNotEmpty) {
        PlayingCard curr = stack.last;
        if (curr.cardSuit == card.cardSuit &&
            (bestMatch == null || bestMatch.value < curr.value)) {
          List<CardStack> neighbors =
              findOutsideNeighbors(playerGrid.values.indexOf(stack));
          if (neighbors.any((cardStack) => cardStack.isEmpty)) {
            bestMatch = curr;
          }
        }
      }
    });

    if (bestMatch != null) {
      return [bestMatch];
    }

    playerGrid.values.forEach((stack) {
      if (stack.isNotEmpty) {
        PlayingCard curr = stack.last;
        if (curr.cardColor == card.cardColor &&
            (bestMatch == null || bestMatch.value < curr.value)) {
          List<CardStack> neighbors =
              findOutsideNeighbors(playerGrid.values.indexOf(stack));
          if (neighbors.any((cardStack) => cardStack.isEmpty)) {
            bestMatch = curr;
          }
        }
      }
    });

    if (bestMatch != null) {
      return [bestMatch];
    }

    List<PlayingCard> matchList = [];
    playerGrid.values.forEach((stack) {
      if (stack.isNotEmpty) {
        PlayingCard curr = stack.last;
        if (bestMatch == null) {
          List<CardStack> neighbors =
              findOutsideNeighbors(playerGrid.values.indexOf(stack));
          if (neighbors.any((cardStack) => cardStack.isEmpty)) {
            bestMatch = curr;
            matchList = [curr];
          }
        } else if (curr.value > bestMatch.value) {
          List<CardStack> neighbors =
              findOutsideNeighbors(playerGrid.values.indexOf(stack));
          if (neighbors.any((cardStack) => cardStack.isEmpty)) {
            bestMatch = curr;
            matchList = [curr];
          }
        } else if (curr.value == bestMatch.value) {
          matchList.add(curr);
        }
      }
    });
    return matchList;
  }

  void hitCheck(int i) {
    switch (i) {
      case 0:
        check(1, 2, Direction.right, 0);
        check(3, 6, Direction.down, 0);
        break;
      case 1:
        check(4, 7, Direction.down, 1);
        break;
      case 2:
        check(1, 0, Direction.left, 0);
        check(5, 8, Direction.down, 2);
        break;
      case 3:
        check(4, 5, Direction.right, 1);
        break;
      case 4:
        break;
      case 5:
        check(4, 3, Direction.left, 1);
        break;
      case 6:
        check(7, 8, Direction.right, 2);
        check(3, 0, Direction.up, 0);
        break;
      case 7:
        check(4, 1, Direction.up, 1);
        break;
      case 8:
        check(7, 6, Direction.left, 2);
        check(5, 2, Direction.up, 2);
        break;
      default:
        break;
    }
  }

  CardStack findInsideNeighbor(Direction dir, int i) {
    switch (dir) {
      case Direction.up:
        return playerGrid.values[i];
      case Direction.down:
        return playerGrid.values[i + 6];
      case Direction.left:
        return playerGrid.values[i * 3];
      case Direction.right:
        return playerGrid.values[i * 3 + 2];
      default:
        throw ArgumentError("invalid direction given");
    }
  }

  List<CardStack> findOutsideNeighbors(int i) {
    switch (i) {
      case 0:
        return [
          enemyLines[Direction.left.index][0],
          enemyLines[Direction.up.index][0]
        ];
      case 1:
        return [enemyLines[Direction.up.index][1]];
      case 2:
        return [
          enemyLines[Direction.right.index][0],
          enemyLines[Direction.up.index][2]
        ];
      case 3:
        return [enemyLines[Direction.left.index][1]];
      case 4:
        return [];
      case 5:
        return [enemyLines[Direction.right.index][1]];
      case 6:
        return [
          enemyLines[Direction.left.index][2],
          enemyLines[Direction.down.index][0]
        ];
      case 7:
        return [enemyLines[Direction.down.index][1]];
      case 8:
        return [
          enemyLines[Direction.right.index][2],
          enemyLines[Direction.down.index][2]
        ];
      default:
        throw ArgumentError("invalid index, 0-8 allowed");
    }
  }

  void check(int card1index, int card2index, Direction attackedDir,
      int attackedIndex) {
    CardStack attackedStack = enemyLines[attackedDir.index][attackedIndex];
    if (attackedStack.isEmpty ||
        !attackedStack.last.faceUp ||
        playerGrid.values[card1index].isEmpty ||
        playerGrid.values[card2index].isEmpty) {
      return;
    }
    PlayingCard card1 = playerGrid.values[card1index].last;
    PlayingCard card2 = playerGrid.values[card2index].last;
    int defence = attackedStack.totalValue;
    int power;

    PlayingCard attackedCard = attackedStack.first;
    if (attackedCard.cardType == CardType.jack) {
      power = card1.cardType.index + card2.cardType.index;
    } else if (attackedCard.cardType == CardType.queen) {
      power = (card1.cardColor == attackedCard.cardColor ? card1.value : 0) +
          (card2.cardColor == attackedCard.cardColor ? card2.value : 0);
    } else if (attackedCard.cardType == CardType.king) {
      power = (card1.cardSuit == attackedCard.cardSuit ? card1.value : 0) +
          (card2.cardSuit == attackedCard.cardSuit ? card2.value : 0);
    }
    if (power >= defence) {
      //kill
      attackedStack.forEach((card) => card.faceUp = false);
    }
  }

  _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        title: Text("Grid Cannon"),
        elevation: 0.0,
        backgroundColor: Colors.green,
        actions: <Widget>[
          Switch(
            value: Settings().showHighlights,
            onChanged: (bool enabled) {
              setState(() {
                return Settings().showHighlights = enabled;
              });
            },
          ),
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
          ),
          InkWell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.info,
                color: Colors.white,
              ),
            ),
            splashColor: Colors.white,
            onTap: () {
              _showDialog(
                  "Gridcannon",
                  "The game is called Gridcannon and was designed by Tom Francis, more info on his Website",
                  "Open Website", () {
                _launchUrl(
                    "https://www.pentadact.com/2019-08-20-gridcannon-a-single-player-game-with-regular-playing-cards/");
              });
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Container(
            child: Column(
              children: List.generate(5, (int row) {
                return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (int col) {
                      return (row > 0 && row < 4 && col > 0 && col < 4)
                          ? playerGrid
                              .getAt(row - 1, col - 1)
                              .getWidget(setState)
                          : enemyLineWidget(row, col);
                    }));
              }),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: handCards.getWidget(setState),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: shameCards.getWidget(setState),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: goneCards.getWidget(setState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  enemyLineWidget(int row, int col) {
    if (row == 0 && col == 0 ||
        row == 4 && col == 4 ||
        row == 0 && col == 4 ||
        row == 4 && col == 0) {
      return Container();
    } else {
      Direction dir;
      int index;
      if (row == 0) {
        dir = Direction.up;
        index = col - 1;
      } else if (row == 4) {
        dir = Direction.down;
        index = col - 1;
      } else if (col == 0) {
        dir = Direction.left;
        index = row - 1;
      } else if (col == 4) {
        dir = Direction.right;
        index = row - 1;
      }
      return enemyLines[dir.index][index].getWidget(setState);
    }
  }

  void endCheck() {
    if (enemyLines.every((List<CardStack> line) => line
        .every((CardStack stack) => stack.isNotEmpty && !stack.last.faceUp))) {
      int score = 0;
      shameCards.forEach((card) => score += card.value);
      _showDialog(
          "congratulations",
          "all enemies killed! Your score is $score Points (less is better)",
          "replay",
          _initialiseGame);
      print(
          "congratulations all enemies killed! Your score is $score Points (less is better)");
    }
  }

  void _showDialog(String titleText, String contentText, String buttonText,
      Function onButton) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(titleText),
            content: Text(contentText),
            actions: <Widget>[
              FlatButton(
                child: Text(buttonText),
                onPressed: onButton,
              )
            ],
          );
        });
  }

  void unHighlightAll() {
    validTargets = null;
    shameCards.unHighlight();

    playerGrid.values.forEach((CardStack pcs) {
      pcs.unHighlight();
    });

    enemyLines.forEach((List<CardStack> line) {
      line.forEach((CardStack ecs) {
        ecs.unHighlight();
      });
    });
    if (handCards.isNotEmpty) {
      handCards.highlight();
    }
  }
}
