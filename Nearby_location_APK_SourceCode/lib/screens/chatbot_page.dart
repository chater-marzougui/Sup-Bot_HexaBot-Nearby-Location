import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../Widgets/widgets.dart';
import '../structures/place_model.dart';
import '../structures/structs.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();
  Position? _currentPosition;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _handleSubmitted(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        message: text,
        isUser: true,
      ));
      _messageController.clear();
      _scrollToBottom();
    });

    if (_currentPosition != null) {
      try {
        setState(() {
          _messages.add(ChatMessage(
            message: "Searching for places nearby...",
            isUser: false,
          ));
        });

        final keyword = PlacesService.extractAmenityFromMessage(text);
        final places = await PlacesService.searchNearbyPlaces(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          keyword,
        );

        if (places.isEmpty) {
          setState(() {
            _messages.add(ChatMessage(
              message: "I couldn't find any matching places nearby.",
              isUser: false,
            ));
          });
        } else {
          setState(() {
            _messages.add(ChatMessage(
              message: "I found ${places.length} places nearby:",
              isUser: false,
              places: places,
              position: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
            ));
            _showMap = true;
          });
        }
      } catch (e) {
        setState(() {
          _messages.add(ChatMessage(
            message: "Sorry, I encountered an error while searching for places.",
            isUser: false,
          ));
        });
      }

      _scrollToBottom();
    } else {
      setState(() {
        _messages.add(ChatMessage(
          message: "I need your location to search for places nearby. Please enable location services.",
          isUser: false,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(width: 16.0,),
            Text('Hexa'),
            Icon(Icons.my_location),
            Text("Finder"),
            SizedBox(width: 16.0,)
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: MessageList(messages: _messages, scrollController: _scrollController,),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              onSubmitted: _handleSubmitted,
              onTapOutside: (_) => _focusNode.unfocus(),
              decoration: const InputDecoration.collapsed(
                hintText: 'Send a message',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitted(_messageController.text),
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}