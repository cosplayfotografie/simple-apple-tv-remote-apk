import 'package:flutter/material.dart';

class TouchpadTab extends StatelessWidget {
  final Function(String) onCommand;
  final Function(String) onSendText;

  const TouchpadTab({
    super.key,
    required this.onCommand,
    required this.onSendText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Expanded(child: _buildLargeTouchpad()),
          const SizedBox(height: 32),
          _buildBottomButtons(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLargeTouchpad() {
    return GestureDetector(
      onTap: () => onCommand('select'),
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        if (velocity.dx.abs() > velocity.dy.abs()) {
          if (velocity.dx > 0) {
            onCommand('right');
          } else {
            onCommand('left');
          }
        } else {
          if (velocity.dy > 0) {
            onCommand('down');
          } else {
            onCommand('up');
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Touchpad',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRemoteButton('MENU', 'menu'),
        _buildKeyboardButton(context),
        _buildRemoteButton(Icons.tv, 'home'),
      ],
    );
  }

  Widget _buildRemoteButton(dynamic content, String cmd) {
    return GestureDetector(
      onTap: () => onCommand(cmd),
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C2E),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: content is String
              ? Text(
                  content,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                )
              : Icon(
                  content as IconData,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ),
    );
  }

  Widget _buildKeyboardButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showKeyboardDialog(context),
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF2C2C2E),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.keyboard, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  void _showKeyboardDialog(BuildContext context) {
    String textToSend = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Text eingeben'),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Text für das Apple TV...',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => textToSend = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                onSendText(textToSend);
                Navigator.pop(context);
              },
              child: const Text('Senden', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
