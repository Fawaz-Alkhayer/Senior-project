import 'package:flutter/material.dart';
import '../models/note_model.dart';
import 'note_detail_screen.dart';
import '../services/database_service.dart';
import '../services/app_lock_service.dart';
import 'settings_screen.dart';
import '../widgets/activity_detector.dart';

//imports list end...

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Note> notes = [];
  List<Note> filteredNotes = []; // For search results
  bool isLoading = true;
  bool isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String sortBy = 'date_desc'; 
  bool showFavoritesOnly = false;
  

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      isLoading = true;
    });

    final loadedNotes = await DatabaseService.instance.readAllNotes();

    setState(() {
      notes = loadedNotes;
      filteredNotes = loadedNotes;
      isLoading = false;
    });
    
    // Reapply search, sort, and filter
    if (_searchController.text.isNotEmpty) {
      _filterNotes(_searchController.text);
    }
    _applySortAndFilter();
  }
  

  void _onSearchChanged() {
    _filterNotes(_searchController.text);
  }

  void _filterNotes(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredNotes = notes;
      } else {
        filteredNotes = notes.where((note) {
          final titleLower = note.title.toLowerCase();
          final contentLower = note.content.toLowerCase();
          final searchLower = query.toLowerCase();
          
          return titleLower.contains(searchLower) || 
                contentLower.contains(searchLower);
        }).toList();
        
        print('Search: "$query" - Found ${filteredNotes.length} notes');
      }
    });
  }


  void _clearSearch() {
    _searchController.clear();
    setState(() {
      isSearching = false;
      filteredNotes = notes;
    });
  }

  void _applySortAndFilter() {
  setState(() {
    // Start with all notes or filtered search results
    List<Note> result = _searchController.text.isEmpty 
        ? List.from(notes) 
        : List.from(filteredNotes);
    
    // Apply favorites filter
    if (showFavoritesOnly) {
      result = result.where((note) => note.isFavorite).toList();
    }
    
    // Apply sorting
    switch (sortBy) {
      case 'date_desc':
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case 'date_asc':
        result.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case 'title_asc':
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'title_desc':
        result.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
    }
    
    // Keep favorites at top if not filtering by favorites only
    if (!showFavoritesOnly) {
      final favorites = result.where((note) => note.isFavorite).toList();
      final nonFavorites = result.where((note) => !note.isFavorite).toList();
      result = [...favorites, ...nonFavorites];
    }
    
    filteredNotes = result;
    
    print('Sort: $sortBy, Favorites Only: $showFavoritesOnly, Results: ${filteredNotes.length}');
  });
}

void _showSortOptions() {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Newest First'),
            trailing: sortBy == 'date_desc' ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              setState(() {
                sortBy = 'date_desc';
              });
              _applySortAndFilter();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Oldest First'),
            trailing: sortBy == 'date_asc' ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              setState(() {
                sortBy = 'date_asc';
              });
              _applySortAndFilter();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('Title (A-Z)'),
            trailing: sortBy == 'title_asc' ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              setState(() {
                sortBy = 'title_asc';
              });
              _applySortAndFilter();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.sort_by_alpha),
            title: const Text('Title (Z-A)'),
            trailing: sortBy == 'title_desc' ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              setState(() {
                sortBy = 'title_desc';
              });
              _applySortAndFilter();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      );
    },
  );
}

  
  @override
  Widget build(BuildContext context) {
    return ActivityDetector(
      child: Scaffold(
        appBar: AppBar(
          title: isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search notes...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                )
              : const Text('My Secure Notes'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          actions: [
            if (isSearching)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
                tooltip: 'Clear Search',
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    isSearching = true;
                  });
                },
                tooltip: 'Search',
              ),
              IconButton(
                icon: Icon(
                  showFavoritesOnly ? Icons.star : Icons.star_border,
                  color: showFavoritesOnly ? Colors.amber : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    showFavoritesOnly = !showFavoritesOnly;
                  });
                  _applySortAndFilter();
                },
                tooltip: showFavoritesOnly ? 'Show All Notes' : 'Show Favorites Only',
              ),
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _showSortOptions,
                tooltip: 'Sort',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                tooltip: 'Settings',
              ),
            ],
            IconButton(
              icon: const Icon(Icons.lock_outline),
              onPressed: () {
                AppLockService.instance.lock();
              },
              tooltip: 'Lock App',
            ),
          ],
        ),
        
        body: Column(
          children: [
            // Search results count banner
            if (isSearching && _searchController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '${filteredNotes.length} note${filteredNotes.length == 1 ? '' : 's'} found',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Main content area
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.note_add_outlined,
                                size: 100,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No notes yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tap + to create your first note',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            if (isSearching && filteredNotes.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 80,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No notes found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Try a different search term',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredNotes.length,
                                  itemBuilder: (context, index) {
                                    final note = filteredNotes[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: IconButton(
                                          icon: Icon(
                                            note.isFavorite ? Icons.star : Icons.star_border,
                                            color: note.isFavorite ? Colors.amber : Colors.grey,
                                            size: 28,
                                          ),
                                          onPressed: () async {
                                            final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
                                            await DatabaseService.instance.toggleFavorite(
                                              note.id!,
                                              updatedNote.isFavorite,
                                            );
                                            _loadNotes();
                                          },
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                note.title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (note.isFavorite)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Pinned',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.amber.shade700,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 8),
                                            Text(
                                              note.content,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _formatDate(note.updatedAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Icon(
                                          Icons.chevron_right,
                                          color: Colors.grey.shade400,
                                        ),
                                        onTap: () async {
                                          final result = await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => NoteDetailScreen(note: note),
                                            ),
                                          );

                                          if (result != null) {
                                            if (result == 'delete') {
                                              await DatabaseService.instance.deleteNote(note.id!);
                                              _loadNotes();
                                            } else if (result is Note) {
                                              await DatabaseService.instance.updateNote(result);
                                              _loadNotes();
                                            }
                                          }
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NoteDetailScreen(),
                ),
              );

              if (result != null && result is Note) {
                await DatabaseService.instance.createNote(result);
                _loadNotes();
              }
            },
        
          backgroundColor: Colors.blue.shade700,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}