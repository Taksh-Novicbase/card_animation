import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:playing_cards/playing_cards.dart';

import 'card_event.dart';
import 'card_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(GameState.initial()) {
    on<ResetGame>((event, emit) => emit(GameState.initial()));
    on<StartDealing>(onStartDealing);
    on<DealNextCard>(onDealNextCard);
    on<HighlightCard>(
      (event, emit) => emit(state.copyWith(highlightedCardIdx: event.idx)),
    );
    on<PlayCard>(onPlayCard);
    on<PlayAI>(onPlay);
    on<FinishTrick>(onFinish);
  }

  Future<void> onStartDealing(
    StartDealing event,
    Emitter<GameState> emit,
  ) async {
    List<PlayingCard> deck = List.of(standardFiftyTwoCardDeck());
    deck.shuffle();
    List<List<PlayingCard>> hands = List.generate(4, (_) => []);
    emit(
      state.copyWith(
        deck: deck,
        hands: hands,
        dealingStep: 0,
        phase: Phase.dealing,
        animDealingCardIndex: 0,
        animDealingCardHand: 0,
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
      ),
    );
    add(DealNextCard());
  }

  Future<void> onDealNextCard(
    DealNextCard event,
    Emitter<GameState> emit,
  ) async {
    final step = state.dealingStep;
    if (step >= 52) {
      emit(
        state.copyWith(
          phase: Phase.dealt,
          animDealingCardIndex: null,
          animDealingCardHand: null,
        ),
      );
      return;
    }

    int handIdx = step % 4;
    PlayingCard card = state.deck[step];
    List<List<PlayingCard>> newHands = state.hands
        .map((h) => List<PlayingCard>.from(h))
        .toList();

    // The card is not added to hand until after the animation!

    emit(
      state.copyWith(animDealingCardIndex: step, animDealingCardHand: handIdx),
    );

    await Future.delayed(const Duration(milliseconds: 220));

    newHands[handIdx].add(card);
    emit(
      state.copyWith(
        hands: newHands,
        dealingStep: step + 1,
        animDealingCardIndex: null,
        animDealingCardHand: null,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 30));
    add(DealNextCard());
  }

  Future<void> onPlayCard(PlayCard event, Emitter<GameState> emit) async {
    if (!(state.phase == Phase.dealt || state.phase == Phase.playing) ||
        state.playedCardIdx != null)
      return;
    if (state.currentPlayer != 1) return;

    if (state.highlightedCardIdx == event.idx) {
      final card = state.hands[1][event.idx];
      List<List<PlayingCard>> newHands = state.hands
          .map((h) => List<PlayingCard>.from(h))
          .toList();
      newHands[1].removeAt(event.idx);

      final List<PlayedCardInfo> newTrick = List<PlayedCardInfo>.from(
        state.trick,
      );
      newTrick.add(
        PlayedCardInfo(card: card, player: 1, trickIndex: newTrick.length),
      );

      emit(
        state.copyWith(
          hands: newHands,
          trick: newTrick,
          playedCardIdx: null,
          highlightedCardIdx: null,
          playedCard: null,
          playedCardLeft: 0,
          playedCardTop: 0,
          currentPlayer: (state.currentPlayer + 1) % 4,
        ),
      );

      add(PlayAI());
    } else {
      emit(state.copyWith(highlightedCardIdx: event.idx));
    }
  }

  Future<void> onPlay(PlayAI event, Emitter<GameState> emit) async {
    if (state.trick.length >= 4) {
      add(FinishTrick());
      return;
    }
    var currentPlayer = state.currentPlayer;
    while (currentPlayer != 1 && state.trick.length < 4) {
      if (state.hands[currentPlayer].isEmpty) {
        currentPlayer = (currentPlayer + 1) % 4;
        continue;
      }
      int cardIdx = 0;
      final card = state.hands[currentPlayer][cardIdx];
      List<List<PlayingCard>> newHands = state.hands
          .map((h) => List<PlayingCard>.from(h))
          .toList();
      newHands[currentPlayer].removeAt(cardIdx);

      final List<PlayedCardInfo> newTrick = List<PlayedCardInfo>.from(
        state.trick,
      );
      newTrick.add(
        PlayedCardInfo(
          card: card,
          player: currentPlayer,
          trickIndex: newTrick.length,
        ),
      );
      emit(
        state.copyWith(
          hands: newHands,
          trick: newTrick,
          playedCardIdx: null,
          playedCard: null,
          playedCardLeft: 0,
          playedCardTop: 0,
          currentPlayer: (currentPlayer + 1) % 4,
        ),
      );
      currentPlayer = (currentPlayer + 1) % 4;
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (state.trick.length == 4) {
      add(FinishTrick());
    }
  }

  Future<void> onFinish(FinishTrick event, Emitter<GameState> emit) async {
    int winner = state.trick[0].player;
    int highest = state.trick[0].card.value.index;
    for (var i = 1; i < state.trick.length; i++) {
      final value = state.trick[i].card.value.index;
      if (value > highest) {
        highest = value;
        winner = state.trick[i].player;
      }
    }
    emit(state.copyWith(phase: Phase.collecting, trickWinner: winner));
    await Future.delayed(const Duration(milliseconds: 800));

    emit(
      state.copyWith(
        trick: [],
        trickWinner: null,
        phase: Phase.dealt,
        currentPlayer: winner,
      ),
    );

    if (state.hands.every((hand) => hand.isEmpty)) {
      emit(state.copyWith(phase: Phase.collected));
    } else if (winner != 1) {
      Future.delayed(const Duration(milliseconds: 100), () {
        add(PlayAI());
      });
    }
  }
}
