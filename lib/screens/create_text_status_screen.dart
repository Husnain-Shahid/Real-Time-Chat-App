import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/status_provider.dart';

class CreateTextStatusScreen extends StatefulWidget {
  const CreateTextStatusScreen({super.key});

  @override
  State<CreateTextStatusScreen> createState() => _CreateTextStatusScreenState();
}

class _CreateTextStatusScreenState extends State<CreateTextStatusScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const List<int> _backgroundColors = [
    0xFF005C4B, // WhatsApp Dark Green
    0xFF128C7E, // WhatsApp Teal
    0xFF5B397D, // Purple
    0xFFD9534F, // Crimson
    0xFFE67E22, // Orange
    0xFF2980B9, // Blue
    0xFF34495E, // Dark Slate
    0xFF8E44AD, // Deep Purple
    0xFF16A085, // Emerald
    0xFFC0392B, // Red
  ];

  static const List<String> _fontStyles = [
    'Default',
    'Serif',
    'Monospace',
    'Cursive',
  ];

  int _selectedColorIndex = 0;
  int _selectedFontIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _nextColor() {
    setState(() {
      _selectedColorIndex = (_selectedColorIndex + 1) % _backgroundColors.length;
    });
  }

  void _nextFont() {
    setState(() {
      _selectedFontIndex = (_selectedFontIndex + 1) % _fontStyles.length;
    });
  }

  TextStyle _getTextStyle() {
    switch (_selectedFontIndex) {
      case 1:
        return const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif',
        );
      case 2:
        return const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        );
      case 3:
        return const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        );
      default:
        return const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        );
    }
  }

  Future<void> _publishStatus() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    final success = await statusProvider.publishTextStatus(
      text: text,
      backgroundColor: _backgroundColors[_selectedColorIndex],
      fontFamily: _fontStyles[_selectedFontIndex],
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(statusProvider.errorMessage ?? 'Failed to publish status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = Color(_backgroundColors[_selectedColorIndex]);
    final statusProvider = Provider.of<StatusProvider>(context);

    return Scaffold(
      backgroundColor: currentColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Toolbar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      // Font style switcher
                      IconButton(
                        icon: const Icon(Icons.title, color: Colors.white, size: 28),
                        onPressed: _nextFont,
                      ),
                      // Background color switcher
                      IconButton(
                        icon: const Icon(Icons.color_lens_outlined, color: Colors.white, size: 28),
                        onPressed: _nextColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Text Input Area
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textAlign: TextAlign.center,
                    style: _getTextStyle(),
                    decoration: InputDecoration(
                      hintText: 'Type a status',
                      hintStyle: _getTextStyle().copyWith(color: Colors.white60),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),

            // Bottom Post Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  onPressed: statusProvider.isUploading || _textController.text.trim().isEmpty
                      ? null
                      : _publishStatus,
                  child: statusProvider.isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Icon(Icons.send, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
