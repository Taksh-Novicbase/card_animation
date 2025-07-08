abstract class GameEvent {}

class ResetGame extends GameEvent {}

class StartDealing extends GameEvent {}

class DealNextCard extends GameEvent {}

class HighlightCard extends GameEvent {
  final int idx;
  HighlightCard(this.idx);
}

class PlayCard extends GameEvent {
  final int idx;
  PlayCard(this.idx);
}

class FinishTrick extends GameEvent {}

class PlayAI extends GameEvent {}
