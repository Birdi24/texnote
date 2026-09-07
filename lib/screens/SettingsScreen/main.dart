import 'package:flutter/material.dart';
import 'package:birdwrite/widgets/single_circle_button.dart';

import '../../app_style.dart';
import 'custom_theme_picker.dart';

/// Stateful because the theme may change
class SettingsScreen extends StatefulWidget {
  final ThemeManager themeManager;

  const SettingsScreen({
    super.key,
    required this.themeManager,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  ThemeManager get themeManager => widget.themeManager;

  @override
  void initState() {
    super.initState();
    themeManager.addListener(_themeChanged);
  }

  @override
  void dispose() {
    themeManager.removeListener(_themeChanged);
    super.dispose();
  }

  void _themeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeManager.theme;

    return Scaffold(
      backgroundColor: theme.bg,

      body: SafeArea(
        child: Stack(
          children: [

            Positioned(
              top: 10, left: 10,
              child: single_circle_button(
                  Icons.arrow_back_ios_rounded,
                  20,
                  255,
                  "back", () {
                Navigator.pop(context);
              },
                  context,
                  MediaQuery
                      .of(context)
                      .size
                      .width,
                  button_width: 50),
            ),

            Positioned(
              top: 17, left: 75,
              child: Text(
                'Themes',

                style: TextStyle(
                  color: theme.iconColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),),
            Positioned(
              left: 20,
              right: 20,
              top: 100,
              child: SizedBox(
                height: MediaQuery
                    .of(context)
                    .size
                    .height - 100,
                child: SingleChildScrollView(
                  child: Center(
                    child: _themeGrid(theme),
                  ),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }


  // ==========================================================
  // THEME GRID
  // ==========================================================
  Widget _themeGrid(AppTheme currentTheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;

        final cardWidth = constraints.maxWidth >= 900
            ? 280.0
            : constraints.maxWidth >= 600
            ? 260.0
            : 180.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _themeCard(
              theme: AppThemes.defaultTheme,
              index: 0,
              name: 'Pure Light',
              width: cardWidth,
            ),

            _themeCard(
              theme: AppThemes.darkTheme,
              index: 1,
              name: 'Ash Dark',
              width: cardWidth,
            ),

            _themeCard(
              theme: AppThemes.redTheme,
              index: 2,
              name: 'Vampire Red',
              width: cardWidth,
            ),

            _themeCard(
              theme: AppThemes.greenTheme,
              index: 3,
              name: 'Sage Green',
              width: cardWidth,
            ),

            _themeCard(
              theme: AppThemes.tokyoNightTheme,
              index: 4,
              name: 'Tokyo Night',
              width: cardWidth,
            ),

            _customThemeCard(
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // PRESET THEME CARD
  // ==========================================================

  Widget _themeCard({
    required AppTheme theme,
    required int index,
    required String name,
    required double width,
  }) {
    final selected =
        themeManager.selectedPreset == index;

    return SizedBox(
        width: width,
        height: width,
        child: Material(
          color: Colors.transparent,

          child: InkWell(
            borderRadius: BorderRadius.circular(18),

            onTap: () async {
              await themeManager.setPreset(index);
              applyTheme(themeManager.theme);
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),

              decoration: BoxDecoration(
                color: theme.bg,

                borderRadius: BorderRadius.circular(18),

                border: Border.all(
                  color: selected
                      ? theme.accent
                      : theme.iconColor.withAlpha(27),

                  width: selected ? 2 : 1,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(17),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Stack(
                children: [

                  // ----------------------------------------------
                  // THEME PREVIEW
                  // ----------------------------------------------

                  Padding(
                    padding: const EdgeInsets.all(12),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        // Fake title
                        Container(
                          width: 45,
                          height: 6,

                          decoration: BoxDecoration(
                            color: theme.iconColor.withAlpha(191),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Fake text
                        Container(
                          width: 65,
                          height: 4,

                          decoration: BoxDecoration(
                            color: theme.iconColor.withAlpha(64),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Container(
                          width: 50,
                          height: 4,

                          decoration: BoxDecoration(
                            color: theme.iconColor.withAlpha(32),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const Spacer(),

                        // Accent preview
                        Container(
                          width: double.infinity,
                          height: 22,

                          decoration: BoxDecoration(
                            color: theme.accent.withAlpha(32),
                            borderRadius: BorderRadius.circular(8),
                          ),

                          child: Align(
                            alignment: Alignment.centerLeft,

                            child: Container(
                              width: 35,
                              height: 6,

                              margin: const EdgeInsets.only(
                                left: 8,
                              ),

                              decoration: BoxDecoration(
                                color: theme.accent,
                                borderRadius:
                                BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          name,

                          style: TextStyle(
                            color: theme.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ----------------------------------------------
                  // SELECTED CHECKMARK
                  // ----------------------------------------------

                  if (selected)
                    Positioned(
                      top: 8,
                      right: 8,

                      child: Container(
                        width: 24,
                        height: 24,

                        decoration: BoxDecoration(
                          color: theme.accent,
                          shape: BoxShape.circle,
                        ),

                        child: Icon(
                          Icons.check,
                          size: 15,
                          color: theme.bg,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
    );
  }

  // ==========================================================
  // CUSTOM THEME CARD
  // ==========================================================

  Widget _customThemeCard({
    required double width,
  }) {
    final current = themeManager.theme;
    final selected = themeManager.isCustom;

    return SizedBox(
        width: width,
        height: width,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          decoration: BoxDecoration(
            color: current.bg,

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: selected
                  ? current.accent
                  : current.iconColor.withAlpha(27),

              width: selected ? 2 : 1,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomThemeScreen(
                          themeManager: themeManager,
                        ),
                  ),
                );
              },
              child: Stack(
                children: [

                  if (!selected)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          Container(
                            width: 46,
                            height: 46,

                            decoration: BoxDecoration(
                              color: current.accent.withAlpha(30),
                              borderRadius: BorderRadius.circular(14),
                            ),

                            child: Icon(
                              Icons.color_lens_outlined,
                              color: current.accent,
                              size: 25,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'Custom',

                            style: TextStyle(
                              color: current.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fake title
                          Container(
                            width: 45,
                            height: 6,
                            decoration: BoxDecoration(
                              color: current.iconColor.withAlpha(191),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Fake text
                          Container(
                            width: 65,
                            height: 4,
                            decoration: BoxDecoration(
                              color: current.iconColor.withAlpha(64),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 50,
                            height: 4,
                            decoration: BoxDecoration(
                              color: current.iconColor.withAlpha(32),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const Spacer(),
                          // Accent preview
                          Container(
                            width: double.infinity,
                            height: 22,
                            decoration: BoxDecoration(
                              color: current.accent.withAlpha(32),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 35,
                                height: 6,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: current.accent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Custom",
                            style: TextStyle(
                              color: current.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (selected)
                    Positioned(
                      top: 8, right: 8,

                      child: Container(width: 24, height: 24,

                        decoration: BoxDecoration(color: current.accent, shape: BoxShape.circle,),

                        child: Icon(Icons.check, size: 15, color: current.bg,),
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
    );
  }
}