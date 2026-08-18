import 'dart:ffi';

import 'package:flutter/material.dart';

import 'package:texnote/models/favorite_and_collection_handling.dart';
import 'package:texnote/models/note.dart';
import 'package:texnote/models/favorite_and_collection_handling.dart';

import 'package:texnote/screens/home_screen/home_body.dart';
import 'package:texnote/screens/home_screen/home_nav_bar.dart';
import 'package:texnote/screens/home_screen/home_top_bar.dart';

import '../../app_style.dart';
import '../../widgets/glass_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  List<Note> notes = [];
  List<Collection> collections = [];
  List<Note> favorites = [];

  Collection? _selectedCollection;

  bool _isSearching = false;
  bool _inCollection = false;

  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  int sort = 0;
  int control = 1;

  final PageController _pageController =
  PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _searchController.addListener(() {
      setState(() {
        _searchQuery =
            _searchController.text.toLowerCase();
      });
    });

    init_files();
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
    final savedNotes = await Note.collectNotes();
    final savedCollections = await load_collections();
    final savedFavorites = await load_favorites(savedNotes);

    setState(() {
      notes = savedNotes;
      collections = savedCollections;
      favorites = savedFavorites;
    });
  }

  Future<void> saveAppState() async {
    await Future.wait([
      save_collections(collections),
      save_favorites(notes),
    ]);
  }

  // ---------------------------------------------------------------------------
  // DISPLAYED NOTES
  // ---------------------------------------------------------------------------

  List<Note> get displayedNotes {
    List<Note> result;

    if (control == 2) {
      result = favorites;
    } else if (_inCollection && _selectedCollection != null) {
      result = _selectedCollection!.notes;
    } else {
      result = notes;
    }

    if (_searchQuery.isEmpty) {
      return result;
    }

    return result.where((note) {
      return note.title
          .toLowerCase()
          .contains(_searchQuery) ||
          note.body
              .toLowerCase()
              .contains(_searchQuery);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // COLLECTIONS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // NOTES
  // ---------------------------------------------------------------------------

  void add_or_remove_favorite(Note note) {
    if (favorites.contains(note)) {
      favorites.remove(note);
      note.is_fav = false;
    } else {
      favorites.add(note);
      note.is_fav = true;
    }

    setState(() {});
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

  Future<void> onNoteChanged() async {
    await saveAppState();
    refresh();
  }

  // ---------------------------------------------------------------------------
  // CONTROLS
  // ---------------------------------------------------------------------------

  Future<void> onControlChanged(int newControl) async {
    final difference = (newControl - control).abs();

    setState(() {
      control = newControl;
    });

    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        newControl,
        duration: Duration(
          milliseconds: 320 * difference,
        ),
        curve: Curves.easeInOut,
      );
    }
  }

  void onSearchChanged() {
    setState(() {
      _isSearching = !_isSearching;

      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  Future<void> onSortChanged() async {
    sort = (sort + 1) % 3;
    refresh();
  }

  void refresh() {
    switch (control) {
      case 0:
        setState(() {
          collections =
              Collection.sort_collections(collections, sort);
        });
        break;

      case 1:
        setState(() {
          notes = Note.sort_notes(notes, sort);
        });
        break;

      case 2:
        setState(() {
          favorites =
              Note.sort_notes(favorites, sort);
        });
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // APP LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.paused) {
      saveAppState();
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    return PopScope(
      canPop: !_inCollection,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _inCollection) {
          closeCollection();
        }
      },
      child: Scaffold(
        backgroundColor: BG,

        body: SafeArea(
          child: Stack(
            children: [
              // ----------------------------------------------------------------
              // MAIN CONTENT
              // ----------------------------------------------------------------

              Positioned(
                top: 40,
                left: 0,
                right: 0,
                bottom: 0,
                child: PageView(
                  controller: _pageController,

                  onPageChanged: (index) {
                    setState(() {
                      control = index;
                    });
                  },

                  children: [
                    home_body(
                      control: 0,
                      context: context,
                      notes: notes,
                      displayedNotes: displayedNotes,
                      collections: collections,
                      onNoteChanged: onNoteChanged,
                      onNoteDeleted: onNoteDeleted,
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
                      displayedNotes: displayedNotes,
                      collections: collections,
                      onNoteChanged: onNoteChanged,
                      onNoteDeleted: onNoteDeleted,
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
                      displayedNotes: displayedNotes,
                      collections: collections,
                      onNoteChanged: onNoteChanged,
                      onNoteDeleted: onNoteDeleted,
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

              // ----------------------------------------------------------------
              // BACKGROUND
              // ----------------------------------------------------------------

              bg_gradient(),

              // ----------------------------------------------------------------
              // TOP RIGHT
              // ----------------------------------------------------------------

              top_right_button_cluster(
                onNoteChanged,
                onSortChanged,
                context,
                screenWidth,
                onSearchChanged,
                _isSearching,
              ),

              // ----------------------------------------------------------------
              // TOP LEFT
              // ----------------------------------------------------------------

              top_left_cluster(
                control,
                _selectedCollection,
                closeCollection,
                context,
                screenWidth,
              ),

              // ----------------------------------------------------------------
              // SEARCH
              // ----------------------------------------------------------------

              if (_isSearching)
                Positioned(
                  bottom: 10,
                  left: 15,
                  right: 15,
                  child: glassContainer(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
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
                          prefixIcon:
                          const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon:
                            const Icon(Icons.clear),
                            onPressed:
                            onSearchChanged,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ----------------------------------------------------------------
              // NAVIGATION
              // ----------------------------------------------------------------

              home_nav_bar(
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