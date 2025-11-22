part of 'conversation_bloc.dart';

@immutable
abstract class ConversationEvent extends Equatable {
  const ConversationEvent();
}

class ConversationStarted extends ConversationEvent {
  const ConversationStarted();

  @override
  List<Object?> get props => [];
}

class ConversationSubmitted extends ConversationEvent {
  final ConversationRequest request;
  const ConversationSubmitted(this.request);

  @override
  List<Object?> get props => [request];
}

class ConversationListenToggled extends ConversationEvent {
  final CropType? expectedCropType;
  const ConversationListenToggled({this.expectedCropType});

  @override
  List<Object?> get props => [expectedCropType];
}
