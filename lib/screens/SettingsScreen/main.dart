import 'package:flutter/material.dart';

import '../../app_style.dart';
import 'custom_theme_picker.dart';

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
        child: Column(
          children: [

            // =================================================
            // HEADER
            // =================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                8,
                12,
                20,
                12,
              ),

              child: Row(
                children: [

                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.iconColor,
                    ),

                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Settings & Help',

                    style: TextStyle(
                      color: theme.iconColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // CONTENT
            // =================================================

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  30,
                ),

                children: [

                  // =================================================
                  // APPEARANCE
                  // =================================================

                  _sectionTitle(
                    'Appearance',
                    theme,
                  ),

                  _themeGrid(theme),

                  const SizedBox(height: 28),

                  // =================================================
                  // HELP
                  // =================================================

                  _sectionTitle(
                    'Help & How-To',
                    theme,
                  ),

                  _settingsCard(
                    theme: theme,
                    icon: Icons.menu_book_outlined,
                    title: 'How to Use Texnote',
                    subtitle: 'Learn the basics of the app',

                    onTap: () {
                      // TODO: Open how-to page
                    },
                  ),

                  const SizedBox(height: 12),

                  _settingsCard(
                    theme: theme,
                    icon: Icons.edit_note_outlined,
                    title: 'Notes',
                    subtitle: 'Learn about creating and editing notes',

                    onTap: () {
                      // TODO
                    },
                  ),

                  const SizedBox(height: 12),

                  _settingsCard(
                    theme: theme,
                    icon: Icons.draw_outlined,
                    title: 'Handwritten Notes',
                    subtitle: 'Learn about the handwriting editor',

                    onTap: () {
                      // TODO
                    },
                  ),

                  const SizedBox(height: 12),

                  _settingsCard(
                    theme: theme,
                    icon: Icons.collections_bookmark_outlined,
                    title: 'Collections & Favorites',
                    subtitle: 'Organize your notes',

                    onTap: () {
                      // TODO
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle(
      String title,
      AppTheme theme,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 12,
      ),

      child: Text(
        title,

        style: TextStyle(
          color: theme.accent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
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
              builder: (_) => CustomThemeScreen(
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
                    top: 8,
                    right: 8,

                    child: Container(
                      width: 24,
                      height: 24,

                      decoration: BoxDecoration(
                        color: current.accent,
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        Icons.check,
                        size: 15,
                        color: current.bg,
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
  // NORMAL SETTINGS CARD
  // ==========================================================

  Widget _settingsCard({
    required AppTheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),

          decoration: BoxDecoration(
            color: theme.iconColor.withAlpha(15),

            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: theme.iconColor.withAlpha(17),
            ),
          ),

          child: Row(
            children: [

              Container(
                width: 46,
                height: 46,

                decoration: BoxDecoration(
                  color: theme.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(
                  icon,
                  color: theme.accent,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,

                      style: TextStyle(
                        color: theme.iconColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,

                      style: TextStyle(
                        color: theme.iconColor.withAlpha(140),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right,
                color: theme.iconColor.withAlpha(130),
              ),
            ],
          ),
        ),
      ),
    );
  }
}