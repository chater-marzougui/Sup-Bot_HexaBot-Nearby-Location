part of 'structs.dart';

class ChatMessage {
  final String message;
  final bool isUser;
  final String? imageUrl;
  final DateTime timestamp;
  final String? senderName;
  final List<Place>? places;
  final LatLng? position;

  ChatMessage({
    required this.message,
    required this.isUser,
    this.imageUrl,
    DateTime? timestamp,
    this.places,
    this.position,
    this.senderName,
  }) : timestamp = timestamp ?? DateTime.now();
}