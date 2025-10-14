part of 'conversation_bloc.dart';

enum ConversationStatus { initializing, ready, processing, success, error }

class ConversationState extends Equatable {
  final ConversationStatus status;
  final ConversationResponse? lastResponse;
  final String? errorMessage;
  final bool isListening;

  const ConversationState({required this.status, this.lastResponse, this.errorMessage, required this.isListening});

  const ConversationState.initial()
    : status = ConversationStatus.initializing,
      lastResponse = null,
      errorMessage = null,
      isListening = false;

  ConversationState copyWith({
    ConversationStatus? status,
    ConversationResponse? lastResponse,
    String? errorMessage,
    bool? isListening,
  }) {
    return ConversationState(
      status: status ?? this.status,
      lastResponse: lastResponse ?? this.lastResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      isListening: isListening ?? this.isListening,
    );
  }

  @override
  List<Object?> get props => [status, lastResponse, errorMessage, isListening];
}
