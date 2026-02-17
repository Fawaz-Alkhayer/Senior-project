import 'package:flutter/material.dart';
import '../models/note_model.dart';
import 'rich_note_editor_screen.dart';
import '../services/database_service.dart';
import 'settings_screen.dart';
import '../widgets/activity_detector.dart';
import '../models/category_model.dart';
import 'categories_screen.dart';
import '../services/note_auth_service.dart';


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
  List<Category> categories = [];
  String? selectedCategoryId;
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
    final loadedCategories = await DatabaseService.instance.readAllCategories();

    setState(() {
      notes = loadedNotes;
      filteredNotes = loadedNotes;
      categories = loadedCategories;
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
      
      // Apply category filter
      if (selectedCategoryId != null) {
        result = result.where((note) => note.categoryId == selectedCategoryId).toList();
      }
      
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
        drawer: _buildCategoryDrawer(),  
        appBar: AppBar(
          leading: Builder(  
            builder: (context) => IconButton(
              icon: const Text('☰', style: TextStyle(fontSize: 24)),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Categories',
            ),
          ),
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
    // Find category for this note
    Category? noteCategory;
    if (note.categoryId != null) {
      try {
        noteCategory = categories.firstWhere((cat) => cat.id == note.categoryId);
      } catch (e) {
        // Category not found
      }
    }

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
          // Check if note is locked
          if (note.isLocked) {
            final authenticated = await NoteAuthService.instance.authenticateForNote(context);
            
            if (!authenticated) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Authentication failed'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
            
            // Wait a moment before opening to ensure auth is complete
            await Future.delayed(const Duration(milliseconds: 300));
          }

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
      

        onLongPress: () => _showNoteOptionsMenu(note),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Lock icon (if locked)
                  if (note.isLocked)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                    ),
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
              
              if (noteCategory != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: noteCategory.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder,
                        size: 14,
                        color: noteCategory.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        noteCategory.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: noteCategory.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (note.content.isNotEmpty && !note.isLocked) ...[
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
              if (note.isLocked) ...[
                const SizedBox(height: 8),
                Text(
                  'Unlock to view content',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
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

    Widget _buildCategoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.folder_outlined, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.all_inbox),
            title: const Text('All Notes'),
            selected: selectedCategoryId == null,
            onTap: () {
              setState(() {
                selectedCategoryId = null;
              });
              _applySortAndFilter();
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No categories yet.\nTap "Manage Categories" to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.folder,
                            color: category.color,
                            size: 20,
                          ),
                        ),
                        title: Text(category.name),
                        selected: selectedCategoryId == category.id,
                        onTap: () {
                          setState(() {
                            selectedCategoryId = category.id;
                          });
                          _applySortAndFilter();
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Manage Categories'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
              _loadNotes();
            },
          ),
        ],
      ),
    );
  }
  void _showNoteOptionsMenu(Note note) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Column(
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
            child: Text(
              note.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          
          // Assign Category
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Assign Category'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showCategorySelectionDialog(note);
            },
          ),
          
          // Remove Category (if has category)
          if (note.categoryId != null)
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('Remove Category'),
              onTap: () async {
                Navigator.pop(context);
                await DatabaseService.instance.assignCategoryToNote(note.id!, null);
                _loadNotes();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category removed'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),

          ListTile(
            leading: Icon(
              note.isLocked ? Icons.lock_open_outlined : Icons.lock_outline,
              color: note.isLocked ? Colors.orange : null,
            ),
            title: Text(note.isLocked ? 'Unlock Note' : 'Lock Note'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              Navigator.pop(context);
              
              if (note.isLocked) {
                // Unlocking - require authentication first
                final authenticated = await NoteAuthService.instance.authenticateForNote(context);
                
                if (!authenticated) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Authentication failed'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }
              
              // Toggle lock state
              await DatabaseService.instance.toggleNoteLock(note.id!, !note.isLocked);
              _loadNotes();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(note.isLocked ? 'Note unlocked' : 'Note locked'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 16),
        ],
      );
    },
  );
}

  void _showCategorySelectionDialog(Note note) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Category'),
          content: categories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No categories available.\nCreate categories first.',
                    textAlign: TextAlign.center,
                  ),
                )
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = note.categoryId == category.id;
                      
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.folder,
                            color: category.color,
                            size: 20,
                          ),
                        ),
                        title: Text(category.name),
                        trailing: isSelected 
                            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) 
                            : null,
                        selected: isSelected,
                        onTap: () async {
                          Navigator.pop(context);
                          await DatabaseService.instance.assignCategoryToNote(
                            note.id!,
                            category.id,
                          );
                          _loadNotes();
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Assigned to "${category.name}"'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
          actions: [
            if (categories.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            if (categories.isEmpty)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                  _loadNotes();
                },
                child: const Text('Create Categories'),
              ),
          ],
        );
      },
    );
  }
}