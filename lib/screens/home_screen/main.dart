import 'package:flutter/material.dart';
import 'dart:io';
import 'package:texnote/models/favorite_and_collection_handling.dart';
import 'package:texnote/screens/home_screen/home_nav_bar.dart';
import 'package:texnote/screens/home_screen/home_top_bar.dart';
import 'package:texnote/widgets/glass_container.dart';

import '../../app_style.dart';
import '../../models/note.dart';
import 'collections_view.dart';
import 'no_collections_view.dart';
import 'package:path_provider/path_provider.dart';
import 'no_notes_view.dart';
import 'notes_view.dart';
class HomeScreen extends StatefulWidget   {
  const HomeScreen({super.key});

  Future<void> onNoteChanged() async {}

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Note> notes = [];
  List<Collection> collections = [];
  Collection? _selectedCollection;
  List<Note> favorites = [];
  bool _isSearching = false;
  bool _inCollection = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int sort = 0;
  int control = 1;

  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addObserver(this);
    init_files();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void openCollection(Collection collection) {
    setState(() {
      _inCollection = true;
      _selectedCollection = collection;
    });
  }
  void closeCollection() {
    debugPrint("Collection closed");
    setState(() {
      _inCollection = false;
      _selectedCollection = null;
    });
  }

  Future<void> init_files() async {
    var savedNotes = await Note.collectNotes();
    collections = await load_collections();
    debugPrint("Collections found: ${collections.length} ");
    favorites = await load_favorites(savedNotes);
    debugPrint("Favorites found: ${favorites.length}");

    setState(() {
      notes = savedNotes;
    });
  }

  List<Note> get displayedNotes {
    List<Note> result = notes;

    if (control == 2) {result = favorites;}

    // Apply search
    if (_searchQuery.isNotEmpty) {
      result = result.where((note) {
        return note.title.toLowerCase().contains(_searchQuery) ||
            note.body.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      saveAppState();
    }
  }

  Future<void> saveAppState() async {
    await Future.wait([
      save_collections(collections),
      save_favorites(notes),
    ]);
  }


  void add_or_remove_favorite(note) {
    if (!favorites.contains(note)) {favorites.add(note); note.is_fav =true;}
    else  {favorites.remove(note); note.is_fav =false;}
    setState(() {
      favorites = favorites;
    });
  }

  void onNoteDeleted(Note note) {
    setState(() {
      notes.remove(note);
      favorites.remove(note);
      for (var collection in collections) {
        collection.notes.remove(note);
      }
    });
  }

  Future<void> onNoteChanged() async {
    await saveAppState();
    refresh();
    debugPrint("New State Set after note change");
  }

  Future<void> onControlChanged(int n_control) async {
    int abs_change = (n_control -control).abs();

    setState(() {
      control = n_control;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        n_control,
        duration: Duration(milliseconds: 320 * abs_change),
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
    debugPrint("Sort state changed to: $sort");
    refresh();
    debugPrint("New State Set after sort change");
  }

  void refresh(){
    switch (control) {
      case 0: {
        List<Collection> newCollections = Collection.sort_collections(collections, sort);
        setState(() {collections = newCollections;});
        for (Collection collection in collections) {
          debugPrint("Collection Name: ${collection.title}");
          debugPrint("Collection Color: ${collection.color}");
          debugPrint("Notes paths:");
          for (var note in collection.notes) {
            if (note is String) {
              debugPrint(" - $note");
            } else if (note is Note) {
              debugPrint(" - ${note.path}");
            }
          }
        }
      }
      case 1 : {
        List<Note> new_notes = Note.sort_notes(notes, sort);
        setState(() {notes = new_notes; });
        debugPrint("Notes paths:");
        for (var note in notes) {
          debugPrint(" - ${note.path}");
        }
      }
      case 2 : {
        List<Note> new_fav = Note.sort_notes(favorites, sort);
        setState(() {favorites = new_fav;});
        debugPrint("Favorites paths:");
        for (var note in favorites) {
          debugPrint(" - ${note.path}");
        }
      }
    }
    getApplicationDocumentsDirectory().then((Directory directory) {
      debugPrint("Files in App Directory (${directory.path}):");
      directory.list(recursive: true, followLinks: false)
          .listen((FileSystemEntity entity) {
        debugPrint(" - ${entity.path}");
      });
    }).catchError((e) {
      debugPrint("Error listing files: $e");
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("HomeScreen building");
    double screen_width = MediaQuery.of(context).size.width;

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

              // NOTES AREA
              Positioned(top: 40, left: 0, right: 0, bottom: 0,

                child: PageView(
                  controller: _pageController,

                  onPageChanged: (index) {setState(() {control = index;});},

                  children: [

                    // 0 = COLLECTIONS
                    _inCollection
                        ? notes_view(context, _selectedCollection!.notes,collections, onNoteChanged, onNoteDeleted, add_or_remove_favorite,)
                        : collections.isEmpty
                        ? no_collections_view(context, onNoteChanged, collections, notes,control,add_or_remove_favorite,_selectedCollection)
                        : collections_view(context, collections, onNoteChanged, add_or_remove_favorite, openCollection,),
                    // 1 = ALL
                    displayedNotes.isEmpty
                        ? no_note_view(context, onNoteChanged,collections, notes,control,add_or_remove_favorite,_selectedCollection)
                        : notes_view(context, displayedNotes, collections,onNoteChanged, onNoteDeleted, add_or_remove_favorite),

                    // 2 = FAVORITES
                    displayedNotes.isEmpty
                        ? no_note_view(context, onNoteChanged, collections, notes,control,add_or_remove_favorite,_selectedCollection)
                        : notes_view(context, displayedNotes, collections,onNoteChanged, onNoteDeleted, add_or_remove_favorite),
                  ],
                ),
              ),
              bg_gradient(),
              top_right_button_cluster(onNoteChanged, onSortChanged, context, screen_width, onSearchChanged, _isSearching),

              top_left_cluster(control, _selectedCollection, closeCollection, context, screen_width),

              _isSearching ?
              Positioned(
                  bottom:10, left: 15, right :15,
                  child: glassContainer(

                      child: Padding(
                          padding: EdgeInsetsGeometry.only(top: 12, left: 10, right: 10,),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: 'Search notes...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  onSearchChanged();
                                },
                              ),
                            ),
                          )
                      )
                  )
              ):

              home_nav_bar(onNoteChanged, context, screen_width, control, onControlChanged, collections,notes,add_or_remove_favorite,_selectedCollection),
            ],
          ),
        ),
      )
    );



  }
}