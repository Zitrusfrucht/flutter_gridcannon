import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:solitaire_flutter/playing_card.dart';

class CardStack extends ListBase<PlayingCard> {
  List<PlayingCard> cards = [];

  Widget getWidget(void Function(VoidCallback) setState) => Center(
    child: DragTarget<PlayingCard>(
        builder: (a, b, c) {
          if ((cards.isEmpty)) {
            return _emptyStack;
          } else {
            return Draggable(
              child: cards.last.widget,
              maxSimultaneousDrags: 1,
              feedback: cards.last.widget,
              childWhenDragging: cards.length > 1
                  ? cards[cards.length - 2].widget
                  : _emptyStack,
              data: this.last,
              onDragCompleted: () => {
                this.removeLast()
              },
            );
          }
        },
        onWillAccept: (PlayingCard card) {
          return this.isEmpty || this.last.faceUp ==  card.faceUp;
          return card.cardColor != this.last.cardColor;
        },
        onAccept: (PlayingCard card) {
          setState(() {
            cards.add(card);
          });
        }
    ),
  );

  get _emptyStack => Container(
      width: PlayingCard.width,
      height: PlayingCard.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.all(Radius.circular(4)),
        color: Colors.white.withOpacity(.6),
      ));

  @override
  int get length => cards.length;

  @override
  set length(int newLength) => cards.length = newLength;

  @override
  PlayingCard operator [](int index) => cards[index];

  @override
  void operator []=(int index, PlayingCard value) => cards[index] = value;
}
