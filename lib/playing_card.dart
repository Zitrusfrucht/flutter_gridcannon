import 'dart:core';

import 'package:flutter/material.dart';

enum CardSuit {
  spades,
  hearts,
  diamonds,
  clubs,
}

enum CardType {
  joker, // 0
  ace,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king // 13
}

// Simple playing card model
class PlayingCard {
  static const double height = 60.0;
  static const aspectRatio = 2/3;
  static double get width => height * aspectRatio;

  CardSuit cardSuit;
  CardType cardType;
  bool faceUp;

  PlayingCard({
    @required this.cardSuit,
    @required this.cardType,
    this.faceUp = false,
  });

  int get value => cardType.index;

  Color get cardColor {
    if (cardSuit == CardSuit.hearts || cardSuit == CardSuit.diamonds) {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }

  static List<PlayingCard> getNewDeck() {
    List<PlayingCard> deck = new List<PlayingCard>();
    deck.add(PlayingCard(cardSuit: CardSuit.hearts, cardType: CardType.joker));
    deck.add(PlayingCard(cardSuit: CardSuit.spades, cardType: CardType.joker));
    for (CardSuit suit in CardSuit.values) {
      for (int i = 1; i < CardType.values.length; i++) {
        deck.add(PlayingCard(cardSuit: suit, cardType: CardType.values[i]));
      }
    }
    return deck;
  }

  @override
  String toString() {

    return '$cardType of $cardSuit';
  }

  get widget {
    return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.all(Radius.circular(4)),
            color: Colors.white,
            image: faceUp
                ? null
                : DecorationImage(
                    image: AssetImage("images/back_side_owl.jpg"))),
        child: faceUp
            ? Padding(
                padding: EdgeInsets.only(top: 4),
                child: Column(
                  children: <Widget>[
                    Image(
                      image: AssetImage(cardImage),
                      height: height / 5 * 3,
                      width: width / 5 * 3,
                    ),
                    Text(typeName,
                        style:
                            TextStyle(color: cardColor, fontSize: height / 4)),
                  ],
                ))
            : Container());
  }

  get cardImage {
    switch (cardSuit) {
      case CardSuit.hearts:
        return ('images/hearts.png');
      case CardSuit.diamonds:
        return ('images/diamonds.png');
      case CardSuit.clubs:
        return ('images/clubs.png');
      case CardSuit.spades:
        return ('images/spades.png');
      default:
        return null;
    }
  }

  get typeName {
    switch (cardType) {
      case CardType.ace:
        return "A";
      case CardType.joker:
        return ":D";
      case CardType.jack:
        return "J";
        break;
      case CardType.queen:
        return "Q";
      case CardType.king:
        return "K";
      default:
        return value.toString();
    }
  }
}
