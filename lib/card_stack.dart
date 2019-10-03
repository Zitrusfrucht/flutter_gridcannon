import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:solitaire_flutter/playing_card.dart';
import 'package:solitaire_flutter/settings.dart';

class CardStack extends ListBase<PlayingCard> {
  List<PlayingCard> cards = [];

  bool draggable;

  CardStack(
      {this.willAccept,
      this.onAccept,
      this.onDragCompleted,
      this.onDragStarted,
      this.onDragEnd,
      this.draggable = true,
      this.isHighlighted = false});

  bool Function(CardStack) willAccept = (_) => false;
  void Function(CardStack) onAccept = (_) {};
  void Function() onDragCompleted = () {};
  void Function() onDragStarted = () {};
  void Function(DraggableDetails details) onDragEnd = (_) {};

  int get totalValue {
    int total = 0;
    cards.forEach((c) {
      total = total + c.cardType.index;
    });
    return total;
  }

  Widget getWidget(void Function(VoidCallback) setState) => Center(
      child: DragTarget<CardStack>(
          builder: (a, b, c) {
            if ((cards.isEmpty)) {
              return makeHighlight(_emptyStack);
            } else if (draggable) {
              return Draggable(
                onDragStarted: this.onDragStarted,
                onDragEnd: this.onDragEnd,
                child: makeHighlight(cards.last.widget),
                maxSimultaneousDrags: 1,
                feedback: Material(
                  child: cards.last.widget,
                  color: Colors.transparent,
                ),
                childWhenDragging: cards.length > 1
                    ? cards[cards.length - 2].widget
                    : _emptyStack,
                data: this,
                onDragCompleted: onDragCompleted,
              );
            } else {
              return makeHighlight(cards.last.widget);
            }
          },
          onWillAccept: willAccept,
          onAccept: onAccept));

  get _emptyStack => Container(
    margin: EdgeInsets.all(10),
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

  bool isHighlighted;
  Color highlightColor = Colors.lightGreenAccent;

  void highlight({Color color}) {
    isHighlighted = true;
    if (color != null) {
      highlightColor = color;
    }
  }

  void unHighlight() {
    isHighlighted = false;
  }

  Widget makeHighlight(Widget child) {
    if (isHighlighted && Settings().showHighlights) {
      return Highlight(
        child: child,
        color: highlightColor,
      );
    } else {
      return child;
    }
  }

  highlightWidget({
    child,
    color = Colors.lightGreenAccent,
    opacity = 0.7,
  }) {
    return Stack(
      children: <Widget>[
        child,
        Positioned.fill(
            child: Container(
          color: color.withOpacity(opacity),
        ))
      ],
    );
  }
}

class Highlight extends StatelessWidget {
  final Widget child;
  final Color color;
  final double opacity;

  Highlight({
    this.child,
    this.color = Colors.lightGreenAccent,
    this.opacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        Positioned.fill(
            child: Container(
          color: color.withOpacity(opacity),
        ))
      ],
    );
  }
}
