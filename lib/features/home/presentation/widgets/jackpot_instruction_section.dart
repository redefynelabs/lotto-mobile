import 'package:flutter/material.dart';
import 'package:win33/core/theme/app_colors.dart';

/// ===============================================================
/// JACKPOT INSTRUCTION SECTION
/// ===============================================================
class JackpotInstructionSection extends StatelessWidget {
  const JackpotInstructionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        // ✅ FIRST CARD → IMAGE TOP, CONTENT BOTTOM
        JackpotInstructionCard(
          title: "Choose your 6 Numbers",
          description:
              "Contact agent and choose your six numbers out of 0 - 32.",
          imagePath: "assets/images/balls.png",
          backgroundColor: AppColors.thunderbird800,
          verticalLayout: true,
        ),
        SizedBox(height: 16),

        JackpotInstructionCard(
          title: "Place your Bid",
          description: "Confirm the bid and wait for the result.",
          imagePath: "assets/images/machine2.png",
          backgroundColor: Colors.white,
          darkText: true,
        ),
        SizedBox(height: 16),

        JackpotInstructionCard(
          title: "Win Jackpot and Enjoy",
          description: "Have a chance to win the jackpot prize.",
          imagePath: "assets/images/prize-box.png",
          backgroundColor: AppColors.thunderbird400,
          imageOnRight: false,
        ),
      ],
    );
  }
}

/// ===============================================================
/// JACKPOT CARD
/// ===============================================================
class JackpotInstructionCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final bool darkText;
  final bool imageOnRight;
  final bool verticalLayout;

  const JackpotInstructionCard({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    this.darkText = false,
    this.imageOnRight = true,
    this.verticalLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = darkText ? Colors.black : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      // ✅ FIRST CARD (VERTICAL)
      child: verticalLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    imagePath,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                _JackpotTextBlock(
                  title: title,
                  description: description,
                  textColor: textColor,
                  darkText: darkText,
                ),
              ],
            )

          // ✅ OTHER CARDS (HORIZONTAL)
          : Row(
              children: imageOnRight
                  ? [
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 20, right: 12),
                          child: _JackpotTextBlock(
                            title: title,
                            description: description,
                            textColor: textColor,
                            darkText: darkText,
                          ),
                        ),
                      ),
                      Image.asset(
                        imagePath,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                    ]
                  : [
                      Image.asset(
                        imagePath,
                        height: 130,
                        fit: BoxFit.contain,
                      ),
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 12, right: 20),
                          child: _JackpotTextBlock(
                            title: title,
                            description: description,
                            textColor: textColor,
                            darkText: darkText,
                          ),
                        ),
                      ),
                    ],
            ),
    );
  }
}

/// ===============================================================
/// TEXT BLOCK
/// ===============================================================
class _JackpotTextBlock extends StatelessWidget {
  final String title;
  final String description;
  final Color textColor;
  final bool darkText;

  const _JackpotTextBlock({
    required this.title,
    required this.description,
    required this.textColor,
    required this.darkText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontFamily: "Coolvetica",
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: darkText ? Colors.black87 : Colors.white,
          ),
        ),
      ],
    );
  }
}
