import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path/path.dart' as p;

import '../../app_style.dart';
import '../../models/Note.dart';
import '../../models/HandwrittenNote.dart';
import '../../models/folder.dart';
import '../../widgets/glass_container.dart';
import 'home_body.dart';
import 'home_nav_bar.dart';
import 'home_top_bar.dart';
import 'multi_tab_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeManager themeManager;
  final TabState tabState;
  final List<Note> allNotes;
  final List<Folder> rootFolders;
  final List<Note> favorites;
  final String? appDirPath;
  final Map<String, int> openNotes;
  final int currentTabIndex;
  final int totalTabs;
  final VoidCallback onRemoveCurrentTab;
  final Future<void> Function(BuildContext, Note) openNote;
  final Future<void> Function([Note?]) onNoteChanged;
  final void Function(Note) onNoteDeleted;
  final Future<void> Function(Folder) onFolderDeleted;
  final void Function(List<Note>) onNotesDeleted;
  final void Function(Note) addOrRemoveFavorite;
  final Future<void> Function() saveAppState;
  final Future<void> Function() initFiles;

  const HomeScreen({
    super.key,
    required this.themeManager,
    required this.tabState,
    required this.allNotes,
    required this.rootFolders,
    required this.favorites,
    required this.appDirPath,
    required this.openNotes,
    required this.currentTabIndex,
    required this.totalTabs,
    required this.onRemoveCurrentTab,
    required this.openNote,
    required this.onNoteChanged,
    required this.onNoteDeleted,
    required this.onFolderDeleted,
    required this.onNotesDeleted,
    required this.addOrRemoveFavorite,
    required this.saveAppState,
    required this.initFiles,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {

  bool _isAnimating = false;
  late final PageController _pageController;

  TabState get tabState => widget.tabState;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: tabState.control);
    WidgetsBinding.instance.addObserver(this);
    tabState.searchController.addListener(_onSearchTextChanged);
  }

  void _onSearchTextChanged() {
    if (mounted) {
      setState(() {
        tabState.searchQuery = tabState.searchController.text.toLowerCase();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tabState.searchController.removeListener(_onSearchTextChanged);
    _pageController.dispose();
    super.dispose();
  }

  List<dynamic> get browserItems {
    if (tabState.currentFolder != null) {
      return [...tabState.currentFolder!.subfolders, ...tabState.currentFolder!.notes];
    }
    
    if (widget.appDirPath == null) return [];
    
    final rootNotes = widget.allNotes.where((n) {
      final dir = p.canonicalize(p.dirname(n.path));
      return dir == widget.appDirPath;
    }).toList();
    return [...widget.rootFolders, ...rootNotes];
  }

  void openFolder(Folder folder) {
    setState(() {
      tabState.currentFolder = folder;
    });
  }

  void closeFolder() {
    setState(() {
      tabState.currentFolder = tabState.currentFolder?.parent;
    });
  }

  ThemeManager get themeManager => widget.themeManager;

  List<Note> get pdfNotes => widget.allNotes.where((n) {
    if (n is HandwrittenNote) {
      return n.pdfSourcePath.isNotEmpty;
    }
    return false;
  }).toList();

  Future<void> onControlChanged(int newControl) async {
    if (newControl == tabState.control) return;
    setState(() {
      tabState.control = newControl;
      _isAnimating = true;
    });
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        newControl,
        duration: Duration(milliseconds: 300 * (newControl - tabState.control).abs()),
        curve: Curves.easeInOut,
      );
    }
    _isAnimating = false;
  }

  void onSearchChanged() {
    setState(() {
      tabState.isSearching = !tabState.isSearching;
      if (!tabState.isSearching) tabState.searchController.clear();
    });
  }

  Future<void> onSortChanged() async {
    tabState.sort = (tabState.sort + 1) % 3;
    Note.sort_notes(widget.allNotes, tabState.sort);
    Note.sort_notes(widget.favorites, tabState.sort);
    Folder.sort_folders(widget.rootFolders, tabState.sort);
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) widget.saveAppState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: tabState.currentFolder == null && widget.totalTabs == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (tabState.currentFolder != null) {
          closeFolder();
        } else if (widget.totalTabs > 1) {
          widget.onRemoveCurrentTab();
        }
      },
      child: Scaffold(
        backgroundColor: BG,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 20, left: 0, right: 0, bottom: 0,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (!_isAnimating) setState(() => tabState.control = index);
                  },
                  children: [
                    // Tab 0: PDFs
                    home_body(
                      control: 0,
                      context: context,
                      notes: pdfNotes,
                      displayedNotes: pdfNotes.where((n) => n.title.toLowerCase().contains(tabState.searchQuery)).toList(),
                      folders: [],
                      onNoteChanged: widget.onNoteChanged,
                      onNoteDeleted: widget.onNoteDeleted,
                      onFolderDeleted: (_) async {},
                      onNotesDeleted: widget.onNotesDeleted,
                      onNoteAdded: widget.onNoteChanged,
                      addToFavorites: widget.addOrRemoveFavorite,
                      selectedFolder: null,
                      inFolder: false,
                      openFolder: (_) {},
                      allFolders: widget.rootFolders,
                      openNote: widget.openNote,
                      openNotes: widget.openNotes,
                    ),
                    // Tab 1: Browser
                    Builder(
                      builder: (context) {
                        final items = browserItems;
                        final filteredItems = items.where((item) {
                          final title = item is Folder ? item.title : (item as Note).title;
                          return title.toLowerCase().contains(tabState.searchQuery);
                        }).toList();
                        
                        return home_body(
                          control: 1,
                          context: context,
                          notes: widget.allNotes,
                          displayedNotes: filteredItems.whereType<Note>().toList(),
                          folders: filteredItems.whereType<Folder>().toList(),
                          onNoteChanged: widget.onNoteChanged,
                          onNoteDeleted: widget.onNoteDeleted,
                          onFolderDeleted: widget.onFolderDeleted,
                          onNotesDeleted: widget.onNotesDeleted,
                          onNoteAdded: widget.onNoteChanged,
                          addToFavorites: widget.addOrRemoveFavorite,
                          selectedFolder: tabState.currentFolder,
                          inFolder: tabState.currentFolder != null,
                          openFolder: openFolder,
                          allFolders: widget.rootFolders,
                          openNote: widget.openNote,
                          openNotes: widget.openNotes,
                        );
                      }
                    ),
                    // Tab 2: Favorites
                    home_body(
                      control: 2,
                      context: context,
                      notes: widget.favorites,
                      displayedNotes: widget.favorites.where((n) => n.title.toLowerCase().contains(tabState.searchQuery)).toList(),
                      folders: [],
                      onNoteChanged: widget.onNoteChanged,
                      onNoteDeleted: widget.onNoteDeleted,
                      onFolderDeleted: (_) async {},
                      onNotesDeleted: widget.onNotesDeleted,
                      onNoteAdded: widget.onNoteChanged,
                      addToFavorites: widget.addOrRemoveFavorite,
                      selectedFolder: null,
                      inFolder: false,
                      openFolder: (_) {},
                      allFolders: widget.rootFolders,
                      openNote: widget.openNote,
                      openNotes: widget.openNotes,
                    ),
                  ],
                ),
              ),
              bg_gradient(),
              top_right_button_cluster(
                tabState.control, tabState.currentFolder != null, widget.onNoteChanged, onSortChanged, 
                context, screenWidth, onSearchChanged, tabState.isSearching, themeManager
              ),
              top_left_cluster(
                tabState.control, tabState.currentFolder, closeFolder, context, screenWidth,
              ),
              tabState.isSearching ?
                Positioned(
                  bottom: 10, left: 15, right: 15,
                  child: glassContainer(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, left: 10, right: 10),
                      child: TextField(
                        controller: tabState.searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Search notes...',
                          prefixIcon: Transform.translate(
                            offset: const Offset(0, -4),
                            child: const Icon(LucideIcons.search),
                          ),
                          suffixIcon: IconButton(
                            padding: const EdgeInsets.only(bottom: 6),
                            icon: const Icon(LucideIcons.x),
                            iconSize: 27,
                            onPressed: onSearchChanged,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : home_nav_bar(
                widget.onNoteChanged, context, screenWidth, tabState.control, onControlChanged, 
                widget.rootFolders, widget.allNotes, widget.addOrRemoveFavorite, tabState.currentFolder, widget.openNote,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
