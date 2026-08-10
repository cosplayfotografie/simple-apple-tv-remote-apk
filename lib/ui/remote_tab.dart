import 'package:flutter/material.dart';

class RemoteTab extends StatelessWidget {
  final Function(String) onCommand;

  const RemoteTab({super.key, required this.onCommand});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Expanded(child: _buildDPad()),
          const SizedBox(height: 32),
          _buildButtonGrid(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDPad() {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth < constraints.maxHeight
          ? constraints.maxWidth
          : constraints.maxHeight;
      final buttonSize = size / 3.2;

      return Center(
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Stack(
            children: [
              // OK button (Center)
              Center(
                child: GestureDetector(
                  onTap: () => onCommand('select'),
                  child: Container(
                    width: buttonSize * 1.2,
                    height: buttonSize * 1.2,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2C2E),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'OK',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
              // Up
              Positioned(
                top: 0,
                left: size / 2 - buttonSize / 2,
                child: _buildDPadDirection('up', buttonSize),
              ),
              // Down
              Positioned(
                bottom: 0,
                left: size / 2 - buttonSize / 2,
                child: _buildDPadDirection('down', buttonSize),
              ),
              // Left
              Positioned(
                left: 0,
                top: size / 2 - buttonSize / 2,
                child: _buildDPadDirection('left', buttonSize),
              ),
              // Right
              Positioned(
                right: 0,
                top: size / 2 - buttonSize / 2,
                child: _buildDPadDirection('right', buttonSize),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDPadDirection(String cmd, double size) {
    return GestureDetector(
      onTap: () => onCommand(cmd),
      child: Container(
        width: size,
        height: size,
        color: Colors.transparent, // Invisible touch target over the white circle
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRemoteButton('MENU', 'menu'),
            _buildVolumeControls(),
            _buildRemoteButton(Icons.power_settings_new, 'power'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRemoteButton(Icons.volume_off, 'mute'),
            const SizedBox(width: 80), // spacer for volume column
            _buildRemoteButton(Icons.tv, 'home'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRemoteButton(Icons.fast_rewind, 'previous'),
            _buildRemoteButton(
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_arrow, color: Colors.white, size: 28),
                  Icon(Icons.pause, color: Colors.white, size: 28),
                ],
              ),
              'play_pause',
            ),
            _buildRemoteButton(Icons.fast_forward, 'next'),
          ],
        ),
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
              : content is IconData
                  ? Icon(
                      content,
                      color: Colors.white,
                      size: 28,
                    )
                  : content as Widget,
        ),
      ),
    );
  }

  Widget _buildVolumeControls() {
    return Container(
      width: 70,
      height: 156,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            iconSize: 28,
            onPressed: () => onCommand('volume_up'),
          ),
          Container(
            height: 1,
            width: 35,
            color: Colors.white24,
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            iconSize: 28,
            onPressed: () => onCommand('volume_down'),
          ),
        ],
      ),
    );
  }
}
