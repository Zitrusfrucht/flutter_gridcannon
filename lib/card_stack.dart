import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:solitaire_flutter/playing_card.dart';

class CardStack extends ListBase<PlayingCard> {
  List<PlayingCard> cards = [];

  bool draggable;


  CardStack({this.willAccept, this.onAccept, this.onDragCompleted, this.draggable= true});
  bool Function(CardStack) willAccept;
  void Function(CardStack) onAccept;
  void Function() onDragCompleted;

  int get totalValue{
    int total = 0;
    cards.forEach((c){
      total = total + c.cardType.index;
    });
    return total;
  }

  Widget getWidget(void Function(VoidCallback) setState) => Center(
      child: DragTarget<CardStack>(
          builder: (a, b, c) {
            if ((cards.isEmpty)) {
              return _emptyStack;
            } else if(draggable) {
              return Draggable(
                child: cards.last.widget,
                maxSimultaneousDrags: 1,
                feedback: cards.last.widget,
                childWhenDragging: cards.length > 1
                    ? cards[cards.length - 2].widget
                    : _emptyStack,
                data: this,
                onDragCompleted: onDragCompleted,
              );
            } else{
              return cards.last.widget;
            }
          },
          onWillAccept: willAccept,
          onAccept: onAccept));

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
