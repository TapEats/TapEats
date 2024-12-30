import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapeats/presentation/state_management/slider_state.dart';

class SliderButton extends StatefulWidget {
  final String labelText;
  final String subText;
  final VoidCallback onSlideComplete;
  final String pageId;
  
  // New optional parameters for customizing size
  final double? width;
  final double? height;

  const SliderButton({
    super.key,
    required this.labelText,
    required this.subText,
    required this.onSlideComplete,
    required this.pageId,
    this.width,
    this.height,
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

  // New variable to track color transition state
  bool _isColorTransitioned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sliderState = Provider.of<SliderState>(context, listen: false);
      if (mounted) {
        bool savedState = sliderState.getSliderState(widget.pageId);
        setState(() {
          isCompleted = savedState;
          _isColorTransitioned = savedState;
          if (savedState) {
            _updateColorsOnComplete();
            _dragPosition = _calculateMaxDragPosition(context);
          } else {
            _resetState();
          }
        });
      }
    });
  }

  double _calculateMaxDragPosition(BuildContext context) {
    // If a custom width is provided, use it; otherwise, calculate based on screen width
    final screenWidth = widget.width ?? MediaQuery.of(context).size.width;
    final sliderWidth = widget.width ?? screenWidth * 0.8;
    final buttonWidth = sliderWidth * 0.25;
    final sidePadding = (widget.height ?? MediaQuery.of(context).size.height * 0.07) * 0.1;
    return sliderWidth - (buttonWidth - (4 * sidePadding));
  }

  void _resetState() {
    if (mounted) {
      setState(() {
        _dragPosition = 0.0;
        isCompleted = false;
        _isColorTransitioned = false;
        _resetColors();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use provided width or calculate based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
  
    // Base dimensions
    final sliderWidth = widget.width ?? screenWidth * 0.8;
    final sliderHeight = widget.height ?? screenHeight * 0.07;
    final sliderRadius = sliderHeight / 2;
    final sidePadding = sliderHeight * 0.1;
    final verticalPadding = sidePadding;

    // Adjust button width based on text length
    final buttonWidth = sliderWidth * 0.25;
    final buttonHeight = sliderHeight - 2 * verticalPadding;
    final maxDragPosition = sliderWidth - (buttonWidth - (4 * sidePadding));
  // if (kDebugMode) {
  //   print('Page ID: ${widget.pageId}');
  //   print('Slider dimensions:');
  //   print('  Screen width: $screenWidth');
  //   print('  Screen height: $screenHeight');
  //   print('  Slider width: $sliderWidth');
  //   print('  Button width: $buttonWidth');
  //   print('  Max drag position: $maxDragPosition');
  // }

    return PopScope(
      canPop: true,
      child: Consumer<SliderState>(
        builder: (context, sliderState, child) {
          // Listen for state changes and update UI accordingly
          bool currentState = sliderState.getSliderState(widget.pageId);
          if (currentState != isCompleted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  isCompleted = currentState;
                  _isColorTransitioned = currentState;
                  if (!currentState) {
                    _resetState();
                  }
                });
              }
            });
          }

          return GestureDetector(
            onPanUpdate: (details) {
              if (isCompleted) return;
  
              RenderBox box = context.findRenderObject() as RenderBox;
              Offset localPosition = box.globalToLocal(details.globalPosition);
              double localX = localPosition.dx;

              setState(() {
                // Calculate drag position with strict bounds
                _dragPosition = (localX - buttonWidth / 2 - sidePadding)
                    .clamp(0.0, maxDragPosition);

                // Calculate dynamic threshold based on text length
                final textLength = widget.labelText.length;
                final baseThreshold = 1; // Maximum threshold for shortest text
                final minThreshold = 1; // Minimum threshold for longest text
                final thresholdReduction = 0.02; // How much to reduce per character
  
                // Calculate threshold based on text length beyond base length (e.g., 4 chars)
                final baseLengthForText = 4;
                final extraChars = textLength - baseLengthForText;
                final dynamicThreshold = (baseThreshold - (extraChars * thresholdReduction))
                    .clamp(minThreshold, baseThreshold);

                // Trigger color transition earlier
                if (_dragPosition >= maxDragPosition * 0.5 && !_isColorTransitioned) {
                  _updateColorsOnComplete();
                  _isColorTransitioned = true;
                }

                // Check for full completion
                if (_dragPosition >= maxDragPosition * dynamicThreshold) {
                  if (!isCompleted) {
                    isCompleted = true;
                    _dragPosition = maxDragPosition; // Ensure button stays within bounds
                    sliderState.setSliderState(widget.pageId, true);
                    widget.onSlideComplete();
                  }
                }
              });
            },

            onPanEnd: (_) {
              if (!isCompleted) {
                setState(() {
                  _dragPosition = 0.0;
                  _isColorTransitioned = false;
                  _resetColors();
                });
                sliderState.setSliderState(widget.pageId, false);
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
                    color: Colors.black.withAlpha(64),
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
        },
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