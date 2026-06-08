import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tech_panel.dart';

class TechInput extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;

  const TechInput({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
  });

  @override
  State<TechInput> createState() => _TechInputState();
}

class _TechInputState extends State<TechInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFDDB7FF);
    const inactiveColor = Color(0xFF353436);
    const focusGlowColor = Color(0xFF8E2DE2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // High-Tech Label Above the Input
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            color: _isFocused ? activeColor : const Color(0xFF998CA0),
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8.0),
        // Cyberpunk Input Panel with Corner Brackets
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: focusGlowColor.withValues(alpha: 0.15),
                      blurRadius: 10.0,
                      spreadRadius: 1.0,
                    ),
                  ]
                : null,
          ),
          child: TechPanel(
            padding: const EdgeInsets.all(2.0), // slim inside padding for the text field
            borderColor: _isFocused ? activeColor : inactiveColor,
            bracketColor: _isFocused ? activeColor : inactiveColor.withValues(alpha: 0.5),
            bracketLength: 8.0,
            bracketThickness: 1.5,
            backgroundColor: const Color(0xFF131314).withValues(alpha: 0.4),
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              obscureText: _obscureText,
              style: GoogleFonts.inter(
                color: const Color(0xFFE5E2E3),
                fontSize: 15.0,
                letterSpacing: _obscureText ? 3.0 : 0.5,
              ),
              cursorColor: activeColor,
              decoration: InputDecoration(
                hintText: widget.hintText.toUpperCase(),
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF4D4354),
                  fontSize: 13.0,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  widget.prefixIcon,
                  color: _isFocused ? activeColor : const Color(0xFF998CA0),
                  size: 18.0,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                          color: _isFocused ? activeColor : const Color(0xFF4D4354),
                          size: 18.0,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
