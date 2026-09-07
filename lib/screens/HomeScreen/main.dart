import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:birdwrite/models/TextNote.dart';
import 'package:birdwrite/models/collections.dart';
import 'package:birdwrite/screens/HomeScreen/home_body.dart';
import 'package:birdwrite/screens/HomeScreen/home_nav_bar.dart';
import 'package:birdwrite/screens/HomeScreen/home_top_bar.dart';

import '../../app_style.dart';
import '../../io/browse_file.dart';
import '../../models/Note.dart';
import '../../models/favorites.dart';
import '../../widgets/glass_container.dart';

/// Stateful because the displayed notes may change depending on the control (collection, all, favorites),
/// if notes are deleted, created etc...
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

  /// Holds the list of what is showed per control
  List<Note> notes = [];
  List<Collection> collections = [];
  List<Note> favorites = [];

  /// Holds the currently selected collection, if any
  Collection? _selectedCollection;

  /// Whether the search bar is open or not
  bool _isSearching = false;

  /// Whether the user is in a collection or not, is persistent even when you move between controls
  bool _inCollection = false;

  /// Controller for the search bar
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  int sort = 0;
  int control = 1;
  bool _isAnimating = false;

  /// page controller for the main content
  final PageController _pageController =
  PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    init_files(); // loads in files from storage
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DATA
  // ---------------------------------------------------------------------------

  Future<void> init_files() async {
    final savedNotes = await collect();
    final savedCollections = await Collection.load_collections(savedNotes);
    final savedFavorites = await load_favorites(savedNotes);
    notes = savedNotes;
    collections = savedCollections;
    favorites = savedFavorites;
    Note.sort_notes(notes, sort);
    Note.sort_notes(favorites, sort);
    Collection.sort_collections(collections, sort);

    setState(() {
      notes = notes; favorites =favorites; collections = collections;

    });
  }

  /// saves the current state of the app to storage, notes are already saved
  Future<void> saveAppState() async {
    await Future.wait([
      Collection.save_collections(collections),
      save_favorites(notes),
    ]);
  }

  /// current displayed notes, depending on the control and search query
  List<Note> get displayedNotes => _getDisplayedNotesFor(control);

  List<Note> _getDisplayedNotesFor(int targetControl) {
    List<Note> result;
    if (targetControl == 2) {
      result = favorites;
    } else if (_inCollection && _selectedCollection != null && targetControl == 0) {
      result = _selectedCollection!.notes;
    } else {
      result = notes;
    }

    if (_searchQuery.isEmpty) {
      return result;
    }

    return result.where((note) {
      if (note.type == NoteType.TextNote) {
        return note.title
            .toLowerCase()
            .contains(_searchQuery) ||
            (note as TextNote).body
            .toLowerCase()
            .contains(_searchQuery);
      }
      return note.title
          .toLowerCase()
          .contains(_searchQuery);
    }).toList();
  }


  void openCollection(Collection collection) {
    setState(() {
      _selectedCollection = collection;
      _inCollection = true;
    });
  }

  void closeCollection() {
    setState(() {
      _selectedCollection = null;
      _inCollection = false;
    });
  }

  get themeManager => widget.themeManager;


  void add_or_remove_favorite(Note note) {
    if (favorites.contains(note)) {
      favorites.remove(note);
      note.isFavorite = false;
    } else {
      favorites.add(note);
      note.isFavorite = true;
    }

    setState(() {});
  }

  void onCollectionDeleted(Collection collection) {
    setState(() {
      collections.remove(collection);
      if (_selectedCollection == collection) {
        closeCollection();
      }
    });
    saveAppState();
  }

  void onNotesDeleted(List<Note> notesToDelete) {
    setState(() {
      for (var note in notesToDelete) {
        notes.remove(note);
        favorites.remove(note);
        for (final collection in collections) {
          collection.notes.remove(note);
        }
      }
    });
    saveAppState();
  }

  void onNoteDeleted(Note note) {
    setState(() {
      notes.remove(note);
      favorites.remove(note);

      for (final collection in collections) {
        collection.notes.remove(note);
      }
    });
  }

  void onNoteAdded(Note note) {
    setState(() {
      notes.add(note);
      if (control == 2) {
        favorites.add(note);
        note.isFavorite = true;
      }
      if (_inCollection && _selectedCollection != null) {
        _selectedCollection!.notes.add(note);
      }
    });
    onNoteChanged();
  }

  Future<void> onNoteChanged() async {
    await saveAppState();
    refresh();
  }

  // ---------------------------------------------------------------------------
  // CONTROLS
  // ---------------------------------------------------------------------------

  Future<void> onControlChanged(int newControl) async {
    if (newControl == control) return;

    final difference = (newControl - control).abs();

    setState(() {
      control = newControl;
      _isAnimating = true;
    });

    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        newControl,
        duration: Duration(
          milliseconds: 300 * difference,
        ),
        curve: Curves.easeInOut,
      );
    }

    _isAnimating = false;
  }

  void onSearchChanged() {
    setState(() {
      _isSearching = !_isSearching;

      if (!_isSearching) {
        _searchController.clear();
      }
      //else {control = 1;}
    });
  }

  Future<void> onSortChanged() async {
    sort = (sort + 1) % 3;
    refresh();
  }

  void refresh() {
    switch (control) {
      case 0:
        setState(() {collections = Collection.sort_collections(collections, sort);});
        break;

      case 1:
        setState(() {notes = Note.sort_notes(notes, sort);});
        break;

      case 2:
        setState(() {favorites = Note.sort_notes(favorites, sort);});
        break;
    }
  }

  /// saves the app state when the app is in the background
  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.paused) {
      saveAppState();
    }
  }

  /// The actual widget that is displayed
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    debugPrint("HomeScreen build: ${notes.length} notes, ${displayedNotes.length} displayed");
    for (var n in notes) {debugPrint("Note in list: ${n.title} (${n.type})");}

    return PopScope(
      canPop: !_inCollection,
      onPopInvokedWithResult: (didPop, result) {if (!didPop && _inCollection) {closeCollection();}},

      child: Scaffold(
        backgroundColor: BG,

        body: SafeArea(
          child: Stack(
            children: [

              /// notes of the current control, positioned below the title
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                bottom: 0,
                child: PageView(
                  controller: _pageController,

                  onPageChanged: (index) {
                    if (!_isAnimating) {
                      setState(() {
                        control = index;
                      });
                    }
                  },

                  children: [
                    home_body(
                      control: 0,
                      context: context,
                      notes: notes,
                      displayedNotes: _getDisplayedNotesFor(0),
                      collections: collections,
                      onNoteChanged: onNoteChanged,
                      onNoteDeleted: onNoteDeleted,
                      onCollectionDeleted: onCollectionDeleted,
                      onNotesDeleted: onNotesDeleted,
                      onNoteAdded: onNoteAdded,
                      addToFavorites:
                      add_or_remove_favorite,
                      selectedCollection:
                      _selectedCollection,
                      inCollection: _inCollection,
                      openCollection: openCollection
                    ),

                    home_body(
                      control: 1,
                      context: context,
                      notes: notes,
                      displayedNotes: _getDisplayedNotesFor(1),
                      collections: collections,
                      onNoteChanged: onNoteChanged,
                      onNoteDeleted: onNoteDeleted,
                      onCollectionDeleted: onCollectionDeleted,
                      onNotesDeleted: onNotesDeleted,
                      onNoteAdded: onNoteAdded,
                      addToFavorites:
                      add_or_remove_favorite,
                      selectedCollection:
                      _selectedCollection,
                      inCollection: _inCollection,
                      openCollection: openCollection
                    ),

                    home_body(
                      control: 2,
                      context: context,
                      notes: notes,
                      displayedNotes: _getDisplayedNotesFor(2),
                      collections: collections,
                      onNoteChanged: onNoteChanged,
                      onNoteDeleted: onNoteDeleted,
                      onCollectionDeleted: onCollectionDeleted,
                      onNotesDeleted: onNotesDeleted,
                      onNoteAdded: onNoteAdded,
                      addToFavorites:
                      add_or_remove_favorite,
                      selectedCollection:
                      _selectedCollection,
                      inCollection: _inCollection,
                      openCollection: openCollection
                    ),
                  ],
                ),
              ),

              /// gradient below the title
              bg_gradient(),

              top_right_button_cluster(
                control,
                _inCollection,
                onNoteChanged,
                onSortChanged,
                context,
                screenWidth,
                onSearchChanged,
                _isSearching,
                themeManager
              ),

              top_left_cluster(
                control,
                _selectedCollection,
                closeCollection,
                context,
                screenWidth,
              ),

              /// positioned at the bottom, if [_isSearching] is true, the search bar is shown otherwise the nav bar
              _isSearching ?
                Positioned(
                  bottom: 10,
                  left: 15,
                  right: 15,
                  child: glassContainer(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 14,
                        left: 10,
                        right: 10,
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder:
                          InputBorder.none,
                          focusedBorder:
                          InputBorder.none,
                          hintText: 'Search notes...',
                          prefixIcon: Transform.translate(
                            offset: const Offset(0, -4),
                            child: const Icon(LucideIcons.search),
                          ),
                          suffixIcon: IconButton(
                            padding: const EdgeInsets.only(bottom: 6),
                            icon :const Icon(LucideIcons.x),
                            iconSize: 27,
                            onPressed:
                            onSearchChanged,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : home_nav_bar(
                onNoteChanged,
                context,
                screenWidth,
                control,
                onControlChanged,
                collections,
                notes,
                add_or_remove_favorite,
                _selectedCollection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
