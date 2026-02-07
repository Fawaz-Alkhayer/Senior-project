import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note_model.dart';
import '../widgets/activity_detector.dart';

class RichNoteEditorScreen extends StatefulWidget {
  final Note? note;

  const RichNoteEditorScreen({super.key, this.note});

  @override
  State<RichNoteEditorScreen> createState() => _RichNoteEditorScreenState();
}

class _RichNoteEditorScreenState extends State<RichNoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isEditing = false;
  String? _imagePath;
  bool _hasUnsavedChanges = false;

  // Simple formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _imagePath = widget.note!.imagePath;
    } else {
      _isEditing = true;
    }

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save changes?'),
        content: const Text('You have unsaved changes. Do you want to save them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveNote();
      return false;
    }

    return true;
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final content = _contentController.text.trim();
    final now = DateTime.now();

    final note = Note(
      id: widget.note?.id,
      title: title,
      content: content,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      isFavorite: widget.note?.isFavorite ?? false,
      imagePath: _imagePath,
    );

    setState(() {
      _hasUnsavedChanges = false;
    });

    Navigator.of(context).pop(note);
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop('delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewNote = widget.note == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: ActivityDetector(
        child: Scaffold(
          appBar: AppBar(
            title: Text(isNewNote ? 'New Note' : 'Edit Note'),
            actions: [
              if (!isNewNote && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  tooltip: 'Edit',
                ),
              if (!isNewNote)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteNote,
                  tooltip: 'Delete',
                ),
              if (_isEditing || isNewNote)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveNote,
                  tooltip: 'Save',
                ),
            ],
          ),
          body: Column(
            children: [
              // Title field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _titleController,
                  enabled: _isEditing || isNewNote,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    border: _isEditing || isNewNote 
                        ? const UnderlineInputBorder() 
                        : InputBorder.none,
                  ),
                ),
              ),

              // Simple Formatting Toolbar (when editing)
              if (_isEditing || isNewNote)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Bold
                        IconButton(
                          icon: const Icon(Icons.format_bold),
                          onPressed: () {
                            setState(() {
                              _isBold = !_isBold;
                            });
                          },
                          color: _isBold ? Theme.of(context).colorScheme.primary : null,
                          tooltip: 'Bold',
                        ),
                        // Italic
                        IconButton(
                          icon: const Icon(Icons.format_italic),
                          onPressed: () {
                            setState(() {
                              _isItalic = !_isItalic;
                            });
                          },
                          color: _isItalic ? Theme.of(context).colorScheme.primary : null,
                          tooltip: 'Italic',
                        ),
                        // Underline
                        IconButton(
                          icon: const Icon(Icons.format_underline),
                          onPressed: () {
                            setState(() {
                              _isUnderline = !_isUnderline;
                            });
                          },
                          color: _isUnderline ? Theme.of(context).colorScheme.primary : null,
                          tooltip: 'Underline',
                        ),
                        const VerticalDivider(),
                        // Font Size -
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (_fontSize > 12) {
                              setState(() {
                                _fontSize -= 2;
                              });
                            }
                          },
                          tooltip: 'Decrease Size',
                        ),
                        Text('${_fontSize.toInt()}'),
                        // Font Size +
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (_fontSize < 32) {
                              setState(() {
                                _fontSize += 2;
                              });
                            }
                          },
                          tooltip: 'Increase Size',
                        ),
                      ],
                    ),
                  ),
                ),

              // Content Editor
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _contentController,
                    enabled: _isEditing || isNewNote,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                      decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Start typing...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // Image preview
              if (_imagePath != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePath!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_isEditing || isNewNote)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () {
                              setState(() {
                                _imagePath = null;
                                _hasUnsavedChanges = true;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),

              // Add image button
              if ((_isEditing || isNewNote) && _imagePath == null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Add Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}