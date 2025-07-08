import 'package:playing_cards/playing_cards.dart';
import 'dart:ui';

enum Phase { idle, dealing, dealt, playing, collecting, collected }

class PlayedCardInfo {
  final PlayingCard card;
  final int player;
  final int trickIndex;
  PlayedCardInfo({
    required this.card,
    required this.player,
    required this.trickIndex,
  });
}

class GameState {
  final List<PlayingCard> deck;
  final List<List<PlayingCard>> hands;
  final int dealingStep;
  final Phase phase;
  final int? animDealingCardIndex;
  final int? animDealingCardHand;
  final Offset? animDealingTarget;
  final int? highlightedCardIdx;
  final int? playedCardIdx;
  final PlayingCard? playedCard;
  final double playedCardLeft;
  final double playedCardTop;
  final int currentCollected;
  final int currentPlayer;
  final List<PlayedCardInfo> trick;
  final int? trickWinner;

  GameState({
    required this.deck,
    required this.hands,
    required this.dealingStep,
    required this.phase,
    required this.animDealingCardIndex,
    required this.animDealingCardHand,
    required this.animDealingTarget,
    required this.highlightedCardIdx,
    required this.playedCardIdx,
    required this.playedCard,
    required this.playedCardLeft,
    required this.playedCardTop,
    required this.currentCollected,
    required this.currentPlayer,
    required this.trick,
    required this.trickWinner,
  });

  factory GameState.initial() => GameState(
    deck: standardFiftyTwoCardDeck(),
    hands: List.generate(4, (_) => <PlayingCard>[]),
    dealingStep: 0,
    phase: Phase.idle,
    animDealingCardIndex: null,
    animDealingCardHand: null,
    animDealingTarget: null,
    highlightedCardIdx: null,
    playedCardIdx: null,
    playedCard: null,
    playedCardLeft: 0,
    playedCardTop: 0,
    currentCollected: 0,
    currentPlayer: 1,
    trick: [],
    trickWinner: null,
  );

  GameState copyWith({
    List<PlayingCard>? deck,
    List<List<PlayingCard>>? hands,
    int? dealingStep,
    Phase? phase,
    int? animDealingCardIndex,
    int? animDealingCardHand,
    Offset? animDealingTarget,
    int? highlightedCardIdx,
    int? playedCardIdx,
    PlayingCard? playedCard,
    double? playedCardLeft,
    double? playedCardTop,
    int? currentCollected,
    int? currentPlayer,
    List<PlayedCardInfo>? trick,
    int? trickWinner,
  }) => GameState(
    deck: deck ?? this.deck,
    hands: hands ?? this.hands,
    dealingStep: dealingStep ?? this.dealingStep,
    phase: phase ?? this.phase,
    animDealingCardIndex: animDealingCardIndex,
    animDealingCardHand: animDealingCardHand,
    animDealingTarget: animDealingTarget ?? this.animDealingTarget,
    highlightedCardIdx: highlightedCardIdx ?? this.highlightedCardIdx,
    playedCardIdx: playedCardIdx ?? this.playedCardIdx,
    playedCard: playedCard ?? this.playedCard,
    playedCardLeft: playedCardLeft ?? this.playedCardLeft,
    playedCardTop: playedCardTop ?? this.playedCardTop,
    currentCollected: currentCollected ?? this.currentCollected,
    currentPlayer: currentPlayer ?? this.currentPlayer,
    trick: trick ?? this.trick,
    trickWinner: trickWinner ?? this.trickWinner,
  );
}
