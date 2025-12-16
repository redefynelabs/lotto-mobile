import 'package:flutter/material.dart';
import 'package:win33/core/theme/app_colors.dart';

/// ===============================================================
/// LUCKY DRAW INSTRUCTION SECTION
/// ===============================================================
class LuckyDrawInstructionSection extends StatelessWidget {
  const LuckyDrawInstructionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        LuckyDrawInstructionCard(
          title: "Contact an Agent",
          description:
              "Contact an authorized agent to place your bids securely and get guidance.",
          imagePath: "assets/images/contact-agent.png",
          backgroundColor: AppColors.thunderbird800,
        ),
        SizedBox(height: 16),

        // ✅ SECOND CARD → IMAGE LEFT (NO GAP)
        LuckyDrawInstructionCard(
          title: "Choose Your Number",
          description:
              "Select any number between 0 and 32. Each number can receive a total of 80 bids only.",
          imagePath: "assets/images/pick-number.png",
          backgroundColor: AppColors.thunderbird400,
          imageOnRight: false,
        ),
        SizedBox(height: 16),

        LuckyDrawInstructionCard(
          title: "Place Your Bid",
          description:
              "You can bid up to 80 times on a single number. Once all 80 bids are taken, no further bids can be placed.",
          imagePath: "assets/images/coin.png",
          backgroundColor: AppColors.thunderbird200,
          darkText: true,
        ),
        SizedBox(height: 16),

        // ✅ LAST CARD → IMAGE LEFT + TEXT RIGHT
        LuckyDrawInstructionCard(
          title: "Wait For Results",
          description:
              "When the winning number is drawn, everyone who placed a bid on that number wins.",
          imagePath: "assets/images/machine.png",
          backgroundColor: AppColors.thunderbird800,
          imageOnRight: false,
          alignTextRight: true,
        ),
      ],
    );
  }
}

/// ===============================================================
/// SINGLE CARD (STABLE + SAFE LAYOUT)
/// ===============================================================
class LuckyDrawInstructionCard extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;
  final bool darkText;
  final bool imageOnRight;
  final bool alignTextRight;

  const LuckyDrawInstructionCard({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
    this.darkText = false,
    this.imageOnRight = true,
    this.alignTextRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = darkText ? Colors.black : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(vertical: 22),
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
      child: Row(
        children: imageOnRight
            ? [
                /// TEXT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 10),
                    child: _TextBlock(
                      title: title,
                      description: description,
                      textColor: textColor,
                      darkText: darkText,
                      alignRight: alignTextRight,
                    ),
                  ),
                ),

                /// IMAGE (RIGHT)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Image.asset(
                    imagePath,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),
              ]
            : [
                /// IMAGE (LEFT — NO GAP)
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: Image.asset(
                    imagePath,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),

                /// TEXT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 20),
                    child: _TextBlock(
                      title: title,
                      description: description,
                      textColor: textColor,
                      darkText: darkText,
                      alignRight: alignTextRight,
                    ),
                  ),
                ),
              ],
      ),
    );
  }
}

/// ===============================================================
/// TEXT BLOCK (REUSABLE)
/// ===============================================================
class _TextBlock extends StatelessWidget {
  final String title;
  final String description;
  final Color textColor;
  final bool darkText;
  final bool alignRight;

  const _TextBlock({
    required this.title,
    required this.description,
    required this.textColor,
    required this.darkText,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: 20,
            fontFamily: "Coolvetica",
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: darkText ? Colors.black87 : Colors.white,
          ),
        ),
      ],
    );
  }
}
