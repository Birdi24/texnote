import 'package:flutter/material.dart';
import 'package:texnote/models/favorite_and_collection_fandling.dart';
import 'package:texnote/screens/home_screen/home_nav_bar.dart';
import 'package:texnote/screens/home_screen/home_top_bar.dart';
import 'package:texnote/widgets/glass_container.dart';

import '../../app_style.dart';
import '../../models/note.dart';
import 'collections_view.dart';
import 'no_collections_view.dart';
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
  List<Note> favorites = [];
  bool _isSearching = false;
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

  Future<void> init_files() async {
    var savedNotes = await Note.collectNotes();
    collections = await load_collections();
    favorites = await load_favorites(savedNotes);

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

  Future<void> saveAppState() async{
    await save_collections(collections);
    await save_favorites(notes);
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
    Note.sort_notes(notes, sort);
    setState(() {notes = notes;});
    print("New State Set");
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

    debugPrint("Sort state: $sort");

    List<Note> new_notes = Note.sort_notes(notes, sort);
    setState(() {
      notes = new_notes;
    });
    print("New State Set");
  }

  @override
  Widget build(BuildContext context) {
    double screen_width = MediaQuery.of(context).size.width;

    return Scaffold(
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
                  displayedNotes.isEmpty
                      ? no_collections_view(context, onNoteChanged,collections,notes)
                      : collections_view(
                    context, collections, onNoteChanged,add_or_remove_favorite
                  ),

                  // 1 = ALL
                  displayedNotes.isEmpty
                      ? no_note_view(context, onNoteChanged,collections, notes)
                      : notes_view(
                    context,
                      displayedNotes, onNoteChanged, onNoteDeleted, add_or_remove_favorite
                  ),

                  // 2 = FAVORITES
                  displayedNotes.isEmpty
                      ? no_note_view(context, onNoteChanged, collections, notes)
                      : notes_view(
                    context,
                    displayedNotes, onNoteChanged, onNoteDeleted, add_or_remove_favorite
                  ),
                ],
              ),
            ),
            bg_gradient(),
            top_button_cluster(onNoteChanged, onSortChanged, context, screen_width, onSearchChanged, _isSearching),
            title(control),

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

            home_nav_bar(onNoteChanged, context, screen_width, control, onControlChanged, collections,notes),
          ],
        ),
      ),
    );
  }
}