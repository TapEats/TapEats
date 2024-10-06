import 'package:flutter/material.dart';

class SliderButton extends StatefulWidget {
  final String labelText;
  final String subText;

  const SliderButton({
    super.key,
    required this.labelText,
    required this.subText,
  });

  @override
  State<SliderButton> createState() => _SliderButtonState();
}

class _SliderButtonState extends State<SliderButton> {
  double _dragPosition = 0.0;
  bool isCompleted = false;

  Color _boxBackgroundColor = const Color(0xFF222222);
  Color _buttonBackgroundColor = const Color(0xFFD0F0C0);
  Color _textColor = const Color(0xFFEEEFEF);
  String _buttonIcon = 'assets/images/sendblack.png';

  @override
  Widget build(BuildContext context) {
    // Screen dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Responsive dimensions
    double sliderWidth = screenWidth * 0.8; // 80% of screen width
    double sliderHeight = screenHeight * 0.07; // 7% of screen height
    double sliderRadius = sliderHeight / 2;

    double sidePadding = sliderHeight * 0.1; // 10% of slider height as padding
    double verticalPadding = sidePadding; // Equal vertical padding

    double buttonHeight = sliderHeight - 2 * verticalPadding; // Adjusted button height
    double buttonWidth = sliderWidth * 0.25; // Button width is 25% of slider width

    double maxDragPosition = sliderWidth - (buttonWidth - (4 * sidePadding));

    return GestureDetector(
      onPanUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);
        double localX = localPosition.dx;

        setState(() {
          // Update drag position based on touch position and padding
          _dragPosition = (localX - buttonWidth / 2 - sidePadding).clamp(0.0, maxDragPosition);

          // If dragged to the end, mark it as completed and update colors
          if (_dragPosition >= maxDragPosition) {
            if (!isCompleted) {
              isCompleted = true;
              _updateColorsOnComplete();
              // Ensure button snaps to the exact end position
              _dragPosition = maxDragPosition;
            }
          } else {
            if (isCompleted) {
              isCompleted = false;
              _resetColors();
            }
          }
        });
      },
      onPanEnd: (_) {
        if (!isCompleted) {
          setState(() {
            // Animate the button back to the start position
            _dragPosition = 0;
          });
        } else {
          setState(() {
            // Ensure button is at the end position
            _dragPosition = maxDragPosition;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: sliderWidth,
        height: sliderHeight,
        decoration: BoxDecoration(
          color: _boxBackgroundColor,
          borderRadius: BorderRadius.circular(sliderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 0),
              blurRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Positioned Button
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              left: _dragPosition + sidePadding,
              top: verticalPadding,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: buttonWidth,
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: _buttonBackgroundColor,
                  borderRadius: BorderRadius.circular(sliderRadius),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Image.asset(
                      _buttonIcon,
                      key: ValueKey<String>(_buttonIcon),
                      width: buttonWidth * 0.6,
                      height: buttonHeight * 0.6,
                    ),
                  ),
                ),
              ),
            ),
            // Centered Text with Padding
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePadding),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: _textColor,
                        fontSize: sliderHeight * 0.3,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Helvetica Neue',
                      ),
                      child: Text(widget.labelText),
                    ),
                    const SizedBox(height: 5), // Small space between texts
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: _textColor,
                        fontSize: sliderHeight * 0.25,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Helvetica Neue',
                      ),
                      child: Text(widget.subText),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateColorsOnComplete() {
    _boxBackgroundColor = const Color(0xFFD0F0C0); // Box turns to D0F0C0
    _buttonBackgroundColor = const Color(0xFF222222); // Button turns to #222222
    _textColor = const Color(0xFF222222); // Text color changes
    _buttonIcon = 'assets/images/sendgreen.png'; // Icon changes to green
  }

  void _resetColors() {
    _boxBackgroundColor = const Color(0xFF222222);
    _buttonBackgroundColor = const Color(0xFFD0F0C0);
    _textColor = const Color(0xFFEEEFEF);
    _buttonIcon = 'assets/images/sendblack.png';
  }
}
