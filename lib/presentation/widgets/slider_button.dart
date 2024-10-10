import 'package:flutter/material.dart';

class SliderButton extends StatefulWidget {
  final String labelText;
  final String subText;
  final VoidCallback onSlideComplete; // Add this parameter for the callback

  const SliderButton({
    super.key,
    required this.labelText,
    required this.subText,
    required this.onSlideComplete, // Required callback
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double sliderWidth = screenWidth * 0.8;
    double sliderHeight = screenHeight * 0.07;
    double sliderRadius = sliderHeight / 2;
    double sidePadding = sliderHeight * 0.1;
    double verticalPadding = sidePadding;
    double buttonHeight = sliderHeight - 2 * verticalPadding;
    double buttonWidth = sliderWidth * 0.25;
    double maxDragPosition = sliderWidth - (buttonWidth - (4 * sidePadding));

    return GestureDetector(
      onPanUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);
        double localX = localPosition.dx;

        setState(() {
          _dragPosition = (localX - buttonWidth / 2 - sidePadding)
              .clamp(0.0, maxDragPosition);

          if (_dragPosition >= maxDragPosition) {
            if (!isCompleted) {
              isCompleted = true;
              _updateColorsOnComplete();
              _dragPosition = maxDragPosition;
              widget
                  .onSlideComplete(); // Trigger the callback when slide completes
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
            _dragPosition = 0;
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
                    const SizedBox(height: 5),
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
    _boxBackgroundColor = const Color(0xFFD0F0C0);
    _buttonBackgroundColor = const Color(0xFF222222);
    _textColor = const Color(0xFF222222);
    _buttonIcon = 'assets/images/sendgreen.png';
  }

  void _resetColors() {
    _boxBackgroundColor = const Color(0xFF222222);
    _buttonBackgroundColor = const Color(0xFFD0F0C0);
    _textColor = const Color(0xFFEEEFEF);
    _buttonIcon = 'assets/images/sendblack.png';
  }
}
