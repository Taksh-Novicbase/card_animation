import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playing_cards/playing_cards.dart';

import '../bloc/card_bloc.dart';
import '../bloc/card_event.dart';
import '../bloc/card_state.dart';

// The animation widget is defined below this file for single-file usage.

class HomePage extends StatelessWidget {
  static const double boxWidth = 400;
  static const double boxHeight = 500;
  static const double userCardWidth = 80;
  static const double userCardHeight = 100;
  static const double otherCardWidth = 60;
  static const double otherCardHeight = 80;
  static const double offsetFull = 18.0;
  static const double offsetPeek = 14.0;
  static const double handMargin = 20;
  static const int handCount = 4;
  static const int cardsPerHand = 13;

  const HomePage({super.key});

  static Offset cardFinalPosition(
    int handIndex,
    int cardInHandIndex,
    int totalCards,
  ) {
    double spread = handIndex == 1 ? offsetFull : offsetPeek;
    double cardW = handIndex == 1 ? userCardWidth : otherCardWidth;
    double cardH = handIndex == 1 ? userCardHeight : otherCardHeight;
    double left = 0, top = 0;
    switch (handIndex) {
      case 0:
        double totalWidth = cardW + spread * (totalCards - 1);
        left = (boxWidth - totalWidth) / 2 + cardInHandIndex * spread;
        top = handMargin;
        break;
      case 1:
        double totalWidth = cardW + spread * (totalCards - 1);
        left = (boxWidth - totalWidth) / 2 + cardInHandIndex * spread;
        top = boxHeight - cardH - handMargin;
        break;
      case 2:
        double totalHeight = cardH + spread * (totalCards - 1);
        left = handMargin;
        top = (boxHeight - totalHeight) / 2 + cardInHandIndex * spread;
        break;
      case 3:
        double totalHeight = cardH + spread * (totalCards - 1);
        left = boxWidth - cardW - handMargin;
        top = (boxHeight - totalHeight) / 2 + cardInHandIndex * spread;
        break;
    }
    return Offset(left, top);
  }

  static Offset trickCardPosition(int player) {
    const spacing = 110.0;
    switch (player) {
      case 0:
        return Offset(
          (boxWidth - otherCardWidth) / 2,
          (boxHeight / 2) - spacing,
        );
      case 1:
        return Offset(
          (boxWidth - userCardWidth) / 2,
          (boxHeight / 2) + spacing - userCardHeight,
        );
      case 2:
        return Offset(
          (boxWidth / 2) - spacing,
          (boxHeight - otherCardHeight) / 2,
        );
      case 3:
        return Offset(
          (boxWidth / 2) + spacing - otherCardWidth,
          (boxHeight - otherCardHeight) / 2,
        );
      default:
        return Offset(
          (boxWidth - userCardWidth) / 2,
          (boxHeight - userCardHeight) / 2,
        );
    }
  }

  double trickCardAngle(int trickIdx) {
    return [-0.19, 0.11, -0.08, 0.16][trickIdx % 4];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameBloc(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Card Distribution Animation')),
        body: SafeArea(
          child: Center(
            child: SizedBox(
              width: boxWidth,
              height: boxHeight,
              child: BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  List<Widget> stackChildren = [];

                  // --- Always build hands (player cards) ---
                  for (int handIdx = 0; handIdx < handCount; handIdx++) {
                    int totalCards = state.hands[handIdx].length;
                    for (int i = 0; i < totalCards; i++) {
                      final card = state.hands[handIdx][i];
                      final pos = cardFinalPosition(handIdx, i, totalCards);
                      final isBottom = handIdx == 1;
                      final isLifted =
                          isBottom && state.highlightedCardIdx == i;

                      Widget cardWidget = PlayedCardView(
                        card: card,
                        showBack: handIdx != 1,
                        width: isBottom ? userCardWidth : otherCardWidth,
                        height: isBottom ? userCardHeight : otherCardHeight,
                        lifted: isLifted,
                      );

                      if (isBottom &&
                          state.phase == Phase.dealt &&
                          handIdx == state.currentPlayer &&
                          state.trick.length < handCount) {
                        cardWidget = GestureDetector(
                          onTap: () =>
                              context.read<GameBloc>().add(PlayCard(i)),
                          child: cardWidget,
                        );
                      }
                      stackChildren.add(
                        Positioned(
                          left: pos.dx,
                          top: pos.dy - (isLifted ? 14 : 0),
                          child: cardWidget,
                        ),
                      );
                    }
                  }

                  // --- Trick display OR trick collect animation ---
                  if (state.phase == Phase.collecting &&
                      state.trickWinner != null &&
                      state.trick.isNotEmpty) {
                    // 1. Trick card positions
                    final trickFromPositions = state.trick
                        .map((info) => trickCardPosition(info.player))
                        .toList();

                    // 2. Winner's hand for animation end
                    final winner = state.trickWinner!;
                    final handLen = state.hands[winner].length;
                    final toPos = cardFinalPosition(
                      winner,
                      handLen,
                      HomePage.cardsPerHand,
                    );

                    // 3. Card widgets for animation
                    final trickCards = state.trick.asMap().entries.map((entry) {
                      final info = entry.value;
                      return PlayedCardView(
                        card: info.card,
                        showBack: false,
                        width: info.player == 1
                            ? userCardWidth
                            : otherCardWidth,
                        height: info.player == 1
                            ? userCardHeight
                            : otherCardHeight,
                        lifted: true,
                      );
                    }).toList();

                    // 4. Add the animation widget!
                    stackChildren.add(
                      TrickCollectAnimation(
                        cardWidgets: trickCards,
                        fromPositions: trickFromPositions,
                        toPosition: toPos,
                        duration: const Duration(milliseconds: 900),
                        onEnd: () {
                          // After animation, dispatch FinishTrick
                          context.read<GameBloc>().add(FinishTrick());
                        },
                      ),
                    );

                    // Winner text overlay (optional)
                    stackChildren.add(
                      Positioned(
                        left: (boxWidth / 2) - 90,
                        top: (boxHeight / 2) - 65,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[200]!.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade900,
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            winner == 1
                                ? "You win the round!"
                                : "Player ${winner + 1} wins!",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Normal trick display (center trick cards)
                    for (int i = 0; i < state.trick.length; i++) {
                      final info = state.trick[i];
                      final card = info.card;
                      final pos = trickCardPosition(info.player);
                      final winner =
                          state.trickWinner != null &&
                          info.player == state.trickWinner;
                      final rotation = trickCardAngle(i);

                      stackChildren.add(
                        Positioned(
                          left: pos.dx,
                          top: pos.dy,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (info.player == 0) ...[
                                _playerLabel(info, winner),
                                const SizedBox(height: 2),
                              ],
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: rotation,
                                    child: PlayedCardView(
                                      card: card,
                                      showBack: false,
                                      width: info.player == 1
                                          ? userCardWidth
                                          : otherCardWidth,
                                      height: info.player == 1
                                          ? userCardHeight
                                          : otherCardHeight,
                                      lifted: winner,
                                    ),
                                  ),
                                ],
                              ),
                              if (info.player != 0) ...[
                                const SizedBox(height: 2),
                                _playerLabel(info, winner),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                  }

                  // DEALING animation overlays (only if dealing phase)
                  if (state.phase == Phase.dealing) {
                    // Deck stack at center
                    for (
                      int i =
                          state.dealingStep +
                          (state.animDealingCardIndex != null ? 1 : 0);
                      i < state.deck.length;
                      i++
                    ) {
                      stackChildren.add(
                        Positioned(
                          left: (boxWidth - userCardWidth) / 2,
                          top:
                              (boxHeight - userCardHeight) / 2 +
                              (i - state.dealingStep) * 0.2,
                          child: PlayedCardView(
                            card: state.deck[i],
                            showBack: true,
                            width: userCardWidth,
                            height: userCardHeight,
                          ),
                        ),
                      );
                    }
                    // Animated flying card
                    if (state.animDealingCardIndex != null &&
                        state.animDealingCardHand != null) {
                      int handIdx = state.animDealingCardHand!;
                      int dealt = state.animDealingCardIndex!;
                      if (dealt < state.deck.length) {
                        final card = state.deck[dealt];
                        final from = Offset(
                          (boxWidth - userCardWidth) / 2,
                          (boxHeight - userCardHeight) / 2,
                        );
                        final to = cardFinalPosition(
                          handIdx,
                          state.hands[handIdx].length,
                          cardsPerHand,
                        );
                        stackChildren.add(
                          _DealAnimatedCard(
                            from: from,
                            to: to,
                            card: card,
                            showBack: handIdx != 1,
                            width: handIdx == 1
                                ? userCardWidth
                                : otherCardWidth,
                            height: handIdx == 1
                                ? userCardHeight
                                : otherCardHeight,
                          ),
                        );
                      }
                    }
                  }

                  // PHASE: IDLE (show deck + deal button)
                  if (state.phase == Phase.idle) {
                    for (var card in state.deck) {
                      stackChildren.add(
                        Positioned(
                          left: (boxWidth - userCardWidth) / 2,
                          top: (boxHeight - userCardHeight) / 2,
                          child: PlayedCardView(
                            card: card,
                            showBack: true,
                            width: userCardWidth,
                            height: userCardHeight,
                          ),
                        ),
                      );
                    }
                    stackChildren.add(
                      Positioned(
                        left: (boxWidth / 2) + 40,
                        top: (boxHeight / 2) - 24,
                        child: ElevatedButton(
                          onPressed: () =>
                              context.read<GameBloc>().add(StartDealing()),
                          child: const Text('Deal'),
                        ),
                      ),
                    );
                    stackChildren.add(
                      Positioned(
                        left: (boxWidth / 2) - 120,
                        top: (boxHeight / 2) + 60,
                        child: Container(
                          width: 240,
                          padding: const EdgeInsets.all(8),
                          color: Colors.yellow[200],
                          child: const Text('Click Deal to start the game.'),
                        ),
                      ),
                    );
                  }

                  // PHASE: COLLECTED
                  if (state.phase == Phase.collected) {
                    stackChildren.add(
                      Center(
                        child: Container(
                          height: 120,
                          padding: const EdgeInsets.all(10),
                          child: Center(
                            child: Image.network(
                              "https://media.tenor.com/fAw8OmhI1WYAAAAj/game-over-game.gif",
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Stack(children: stackChildren);
                },
              ),
            ),
          ),
        ),
        floatingActionButton: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            return state.phase != Phase.idle
                ? FloatingActionButton(
                    onPressed: () => context.read<GameBloc>().add(ResetGame()),
                    child: const Icon(Icons.refresh),
                  )
                : const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _playerLabel(PlayedCardInfo info, bool winner) => Text(
    info.player == 1 ? "You" : "Player ${info.player + 1}",
    style: TextStyle(
      color: winner ? Colors.orange[900] : Colors.grey[800],
      fontWeight: winner ? FontWeight.bold : FontWeight.normal,
      fontSize: 14,
      shadows: winner ? [const Shadow(color: Colors.amber, blurRadius: 8)] : [],
    ),
  );
}

class PlayedCardView extends StatelessWidget {
  final PlayingCard card;
  final bool showBack;
  final double width;
  final double height;
  final bool lifted;

  const PlayedCardView({
    required this.card,
    this.showBack = true,
    required this.width,
    required this.height,
    this.lifted = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: EdgeInsets.only(bottom: lifted ? 6 : 0),
        child: PlayingCardView(card: card, showBack: showBack),
      ),
    );
  }
}

// Animated card that moves from deck to the correct hand
class _DealAnimatedCard extends StatefulWidget {
  final Offset from;
  final Offset to;
  final PlayingCard card;
  final bool showBack;
  final double width;
  final double height;

  const _DealAnimatedCard({
    required this.from,
    required this.to,
    required this.card,
    required this.showBack,
    required this.width,
    required this.height,
  });

  @override
  State<_DealAnimatedCard> createState() => _DealAnimatedCardState();
}

class _DealAnimatedCardState extends State<_DealAnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final dx =
            widget.from.dx + (widget.to.dx - widget.from.dx) * _animation.value;
        final dy =
            widget.from.dy + (widget.to.dy - widget.from.dy) * _animation.value;
        return Positioned(
          left: dx,
          top: dy,
          child: PlayedCardView(
            card: widget.card,
            showBack: widget.showBack,
            width: widget.width,
            height: widget.height,
          ),
        );
      },
    );
  }
}

// -------- TrickCollectAnimation Widget --------
class TrickCollectAnimation extends StatefulWidget {
  final List<Widget> cardWidgets;
  final List<Offset> fromPositions;
  final Offset toPosition;
  final Duration duration;
  final VoidCallback? onEnd;

  const TrickCollectAnimation({
    super.key,
    required this.cardWidgets,
    required this.fromPositions,
    required this.toPosition,
    this.duration = const Duration(milliseconds: 700),
    this.onEnd,
  });

  @override
  State<TrickCollectAnimation> createState() => _TrickCollectAnimationState();
}

class _TrickCollectAnimationState extends State<TrickCollectAnimation>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.cardWidgets.length, (i) {
      return AnimationController(vsync: this, duration: widget.duration)
        ..forward();
    });
    _animations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOutQuad))
        .toList();

    _controllers.last.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onEnd?.call();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.cardWidgets.length, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            final t = _animations[i].value;
            final dx =
                widget.fromPositions[i].dx +
                (widget.toPosition.dx - widget.fromPositions[i].dx) * t;
            final dy =
                widget.fromPositions[i].dy +
                (widget.toPosition.dy - widget.fromPositions[i].dy) * t;
            return Positioned(left: dx, top: dy, child: child!);
          },
          child: widget.cardWidgets[i],
        );
      }),
    );
  }
}
