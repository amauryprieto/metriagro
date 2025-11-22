part of 'conversation_bloc.dart';

enum ConversationStatus { initializing, ready, processing, analyzing, searchingTreatment, validating, success, error }

class ConversationState extends Equatable {
  final ConversationStatus status;
  final ConversationResponse? lastResponse;
  final String? errorMessage;
  final bool isListening;
  final String? progressMessage;

  const ConversationState({
    required this.status,
    this.lastResponse,
    this.errorMessage,
    required this.isListening,
    this.progressMessage,
  });

  const ConversationState.initial()
    : status = ConversationStatus.initializing,
      lastResponse = null,
      errorMessage = null,
      isListening = false,
      progressMessage = null;

  ConversationState copyWith({
    ConversationStatus? status,
    ConversationResponse? lastResponse,
    String? errorMessage,
    bool? isListening,
    String? progressMessage,
  }) {
    return ConversationState(
      status: status ?? this.status,
      lastResponse: lastResponse ?? this.lastResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      isListening: isListening ?? this.isListening,
      progressMessage: progressMessage ?? this.progressMessage,
    );
  }

  @override
  List<Object?> get props => [status, lastResponse, errorMessage, isListening, progressMessage];
}
