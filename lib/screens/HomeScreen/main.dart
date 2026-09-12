import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../app_style.dart';
import '../../io/browse_file.dart';
import '../../models/Note.dart';
import '../../models/HandwrittenNote.dart';
import '../../models/folder.dart';
import '../../models/favorites.dart';
import '../../widgets/glass_container.dart';
import 'home_body.dart';
import 'home_nav_bar.dart';
import 'home_top_bar.dart';

class HomeScreen extends StatefulWidget {
  final ThemeManager themeManager;

  const HomeScreen({
    super.key,
    required this.themeManager,
  });
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {

  List<Note> allNotes = [];
  List<Folder> rootFolders = [];
  List<Note> favorites = [];

  Folder? _currentFolder;
  String? _appDirPath;

  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int sort = 0;
  int control = 1;
  bool _isAnimating = false;

  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    init_files();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> init_files() async {
    debugPrint("main.dart: init_files() started");
    final appDir = await getApplicationDocumentsDirectory();
    _appDirPath = p.canonicalize(appDir.path);
    debugPrint("main.dart: _appDirPath = $_appDirPath");

    final savedNotes = await collect();
    debugPrint("main.dart: init_files() collected ${savedNotes.length} notes");
    for (var n in savedNotes) {
      debugPrint("   -> Note: '${n.title}' at '${n.path}'");
    }
    
    final savedFolders = await Folder.load_folders(savedNotes);
    debugPrint("main.dart: init_files() loaded ${savedFolders.length} root folders");
    final savedFavorites = await load_favorites(savedNotes);

    allNotes = savedNotes;
    rootFolders = savedFolders;
    favorites = savedFavorites;

    if (_currentFolder != null) {
      final oldPath = _currentFolder!.path;
      _currentFolder = _findFolderInTree(rootFolders, oldPath);
      debugPrint("main.dart: restored _currentFolder to ${_currentFolder?.title} (found: ${_currentFolder != null})");
    }

    Note.sort_notes(allNotes, sort);
    Note.sort_notes(favorites, sort);
    Folder.sort_folders(rootFolders, sort);

    setState(() {});
    debugPrint("main.dart: init_files() completed. setState called.");
  }

  Future<void> saveAppState() async {
    await Future.wait([
      Folder.save_folder_metadata_recursive(rootFolders),
      save_favorites(allNotes),
    ]);
  }

  List<Note> get pdfNotes => allNotes.where((n) {
    if (n is HandwrittenNote) {
      return n.pdfSourcePath.isNotEmpty;
    }
    return false;
  }).toList();

  

  
  Folder? _findFolderInTree(List<Folder> folders, String path) {
    final targetPath = p.canonicalize(path);
    for (var f in folders) {
      if (p.canonicalize(f.path) == targetPath) return f;
      final found = _findFolderInTree(f.subfolders, path);
      if (found != null) return found;
    }
    return null;
  }
  
  // Refined helper to get items for Tab 1 (Browser)
  List<dynamic> get browserItems {
    debugPrint("main.dart: browserItems getter. _currentFolder: ${_currentFolder?.title}, allNotes count: ${allNotes.length}");
    if (_currentFolder != null) {
      return [..._currentFolder!.subfolders, ..._currentFolder!.notes];
    }
    
    if (_appDirPath == null) return [];
    
    final rootNotes = allNotes.where((n) {
      final dir = p.canonicalize(p.dirname(n.path));
      return dir == _appDirPath;
    }).toList();
    debugPrint("main.dart: browserItems root. rootFolders: ${rootFolders.length}, rootNotes: ${rootNotes.length}");
    return [...rootFolders, ...rootNotes];
  }

  void openFolder(Folder folder) {
    setState(() {
      _currentFolder = folder;
    });
  }

  void closeFolder() {
    setState(() {
      _currentFolder = _currentFolder?.parent;
    });
  }

  ThemeManager get themeManager => widget.themeManager;

  void _removeNoteFromHierarchy(Note note) {
    void removeFromFolder(Folder folder) {
      // Remove by identity OR by path (to handle renames/identity changes)
      folder.notes.removeWhere((n) => n == note || (n.path == note.path));
      for (var sub in folder.subfolders) {
        removeFromFolder(sub);
      }
    }
    for (var root in rootFolders) {
      removeFromFolder(root);
    }
  }

  void add_or_remove_favorite(Note note) {
    debugPrint("add_or_remove_favorite(note: ${note.title})");
    setState(() {
      if (favorites.contains(note)) {
        favorites.remove(note);
        note.isFavorite = false;
      } else {
        favorites.add(note);
        note.isFavorite = true;
      }
    });
    saveAppState();
  }

  void onFolderDeleted(Folder folder) {
    setState(() {
      if (folder.parent != null) {
        folder.parent!.subfolders.remove(folder);
      } else {
        rootFolders.remove(folder);
      }
      if (_currentFolder == folder) {
        _currentFolder = folder.parent;
      }
    });
    saveAppState();
  }

  void onNotesDeleted(List<Note> notesToDelete) {
    setState(() {
      for (var note in notesToDelete) {
        allNotes.remove(note);
        favorites.remove(note);
        _removeNoteFromHierarchy(note);
      }
    });
    saveAppState();
  }

  void onNoteDeleted(Note note) {
    setState(() {
      allNotes.remove(note);
      favorites.remove(note);
      _removeNoteFromHierarchy(note);
    });
    saveAppState();
  }

  void onNoteAdded(Note note) async {
    await onNoteChanged(note);
  }

  Future<void> onNoteChanged([Note? note]) async {
    debugPrint("main.dart: onNoteChanged(note: ${note?.title})");

    // Remember where the user currently is before rebuilding
    // the folder tree.
    final currentFolderPath = _currentFolder?.path;

    final savedFolders = await Folder.load_folders(allNotes);

    if (!mounted) return;

    setState(() {
      rootFolders = savedFolders;

      // Folder.load_folders() creates new Folder objects.
      // Reconnect the current folder to the new tree.
      if (currentFolderPath != null) {
        _currentFolder = _findFolderInTree(
          rootFolders,
          currentFolderPath,
        );
      }
    });

    await saveAppState();

    debugPrint(
      "main.dart: onNoteChanged completed. "
          "Current folder: ${_currentFolder?.title}",
    );
  }
  Future<void> onControlChanged(int newControl) async {
    if (newControl == control) return;
    setState(() {
      control = newControl;
      _isAnimating = true;
    });
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        newControl,
        duration: Duration(milliseconds: 300 * (newControl - control).abs()),
        curve: Curves.easeInOut,
      );
    }
    _isAnimating = false;
  }

  void onSearchChanged() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) _searchController.clear();
    });
  }

  Future<void> onSortChanged() async {
    sort = (sort + 1) % 3;
    refresh();
  }

  void refresh() {
    init_files();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) saveAppState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: _currentFolder == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentFolder != null) closeFolder();
      },
      child: Scaffold(
        backgroundColor: BG,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 40, left: 0, right: 0, bottom: 0,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (!_isAnimating) setState(() => control = index);
                  },
                  children: [
                    // Tab 0: PDFs
                    home_body(
                      control: 0,
                      context: context,
                      notes: pdfNotes,
                      displayedNotes: pdfNotes.where((n) => n.title.toLowerCase().contains(_searchQuery)).toList(),
                      folders: [],
                      onNoteChanged: onNoteChanged,
                      onNoteDeleted: onNoteDeleted,
                      onFolderDeleted: (_) {},
                      onNotesDeleted: onNotesDeleted,
                      onNoteAdded: onNoteAdded,
                      addToFavorites: add_or_remove_favorite,
                      selectedFolder: null,
                      inFolder: false,
                      openFolder: (_) {},
                      allFolders: rootFolders,
                    ),
                    // Tab 1: Browser
                    Builder(
                      builder: (context) {
                        final items = browserItems;
                        final filteredItems = items.where((item) {
                          final title = item is Folder ? item.title : (item as Note).title;
                          return title.toLowerCase().contains(_searchQuery);
                        }).toList();
                        
                        return home_body(
                          control: 1,
                          context: context,
                          notes: allNotes,
                          displayedNotes: filteredItems.whereType<Note>().toList(),
                          folders: filteredItems.whereType<Folder>().toList(),
                          onNoteChanged: onNoteChanged,
                          onNoteDeleted: onNoteDeleted,
                          onFolderDeleted: onFolderDeleted,
                          onNotesDeleted: onNotesDeleted,
                          onNoteAdded: onNoteAdded,
                          addToFavorites: add_or_remove_favorite,
                          selectedFolder: _currentFolder,
                          inFolder: _currentFolder != null,
                          openFolder: openFolder,
                          allFolders: rootFolders,
                        );
                      }
                    ),
                    // Tab 2: Favorites
                    home_body(
                      control: 2,
                      context: context,
                      notes: favorites,
                      displayedNotes: favorites.where((n) => n.title.toLowerCase().contains(_searchQuery)).toList(),
                      folders: [],
                      onNoteChanged: onNoteChanged,
                      onNoteDeleted: onNoteDeleted,
                      onFolderDeleted: (_) {},
                      onNotesDeleted: onNotesDeleted,
                      onNoteAdded: onNoteAdded,
                      addToFavorites: add_or_remove_favorite,
                      selectedFolder: null,
                      inFolder: false,
                      openFolder: (_) {},
                      allFolders: rootFolders,
                    ),
                  ],
                ),
              ),
              bg_gradient(),
              top_right_button_cluster(
                control, _currentFolder != null, onNoteChanged, onSortChanged, 
                context, screenWidth, onSearchChanged, _isSearching, themeManager
              ),
              top_left_cluster(
                control, _currentFolder, closeFolder, context, screenWidth,
              ),
              _isSearching ?
                Positioned(
                  bottom: 10, left: 15, right: 15,
                  child: glassContainer(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14, left: 10, right: 10),
                      child: TextField(
                        controller: _searchController,
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
                onNoteChanged, context, screenWidth, control, onControlChanged, 
                rootFolders, allNotes, add_or_remove_favorite, _currentFolder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
