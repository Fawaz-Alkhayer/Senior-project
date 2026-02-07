import 'package:flutter/material.dart';
import '../models/note_model.dart';
import 'rich_note_editor_screen.dart';
import '../services/database_service.dart';
import 'settings_screen.dart';
import '../widgets/activity_detector.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  List<Note> notes = [];
  List<Note> filteredNotes = [];
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
      }
    });
    _applySortAndFilter();
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
      List<Note> result = _searchController.text.isEmpty 
          ? List.from(notes) 
          : List.from(filteredNotes);
      
      if (showFavoritesOnly) {
        result = result.where((note) => note.isFavorite).toList();
      }
      
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
      
      if (!showFavoritesOnly) {
        final favorites = result.where((note) => note.isFavorite).toList();
        final nonFavorites = result.where((note) => !note.isFavorite).toList();
        result = [...favorites, ...nonFavorites];
      }
      
      filteredNotes = result;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, 
                      color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Sort & Filter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'FILTER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('All Notes'),
                trailing: !showFavoritesOnly 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                    : null,
                onTap: () {
                  setState(() {
                    showFavoritesOnly = false;
                  });
                  _applySortAndFilter();
                  Navigator.pop(context);
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Favorites Only'),
                trailing: showFavoritesOnly 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                    : null,
                onTap: () {
                  setState(() {
                    showFavoritesOnly = true;
                  });
                  _applySortAndFilter();
                  Navigator.pop(context);
                },
              ),
              
              const Divider(height: 1),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SORT BY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Newest First'),
                trailing: sortBy == 'date_desc' 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                    : null,
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
                trailing: sortBy == 'date_asc' 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                    : null,
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
                trailing: sortBy == 'title_asc' 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                    : null,
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
                trailing: sortBy == 'title_desc' 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                    : null,
                onTap: () {
                  setState(() {
                    sortBy = 'title_desc';
                  });
                  _applySortAndFilter();
                  Navigator.pop(context);
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
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
      return 'Edited: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivityDetector(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Notes'),
          actions: [
            IconButton(
              icon: const Icon(Icons.star_outline),
              onPressed: _showSortOptions,
              tooltip: 'Sort & Filter',
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
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
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
              ),
            ),
            
            // Notes List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredNotes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            return _buildNoteCard(note);
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RichNoteEditorScreen(),
              ),
            );

            if (result != null && result is Note) {
              await DatabaseService.instance.createNote(result);
              _loadNotes();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first note',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RichNoteEditorScreen(note: note),
            ),
          );

          if (result != null) {
            if (result == 'delete') {
              await DatabaseService.instance.deleteNote(note.id!);
            } else if (result is Note) {
              await DatabaseService.instance.updateNote(result);
            }
            _loadNotes();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isFavorite ? Icons.star : Icons.star_outline,
                      color: note.isFavorite 
                          ? Colors.amber 
                          : Colors.grey.shade400,
                      size: 24,
                    ),
                    onPressed: () async {
                      await DatabaseService.instance.toggleFavorite(
                        note.id!,
                        !note.isFavorite,
                      );
                      _loadNotes();
                    },
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}