import 'dart:core';

import 'package:flutter/foundation.dart';
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

const Map<CardType, int> _CardValues = {
  CardType.joker: 0,
  CardType.ace: 1,
  CardType.two: 2,
  CardType.three: 3,
  CardType.four: 4,
  CardType.five: 5,
  CardType.six: 6,
  CardType.seven: 7,
  CardType.eight: 8,
  CardType.nine: 9,
  CardType.ten: 10,
  CardType.jack: 11,
  CardType.queen: 12,
  CardType.king: 13
};

int valueOf(CardType type) => _CardValues[type];

// Simple playing card model
class PlayingCard {
  static const double height = 60.0;
  static const width = 40.0;

  CardSuit cardSuit;
  CardType cardType;
  bool faceUp;

  PlayingCard({
    @required this.cardSuit,
    @required this.cardType,
    this.faceUp = false,
  });

  Color get cardColor {
    if (cardSuit == CardSuit.hearts || cardSuit == CardSuit.diamonds) {
      return Colors.red;
    } else {
      return Colors.black;
    }
  }

  get value => valueOf(cardType);

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
    return '${describeEnum(cardType)} of ${describeEnum(cardSuit)}';
  }

  get widget {
    return Container(
      margin: EdgeInsets.all(10),
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
