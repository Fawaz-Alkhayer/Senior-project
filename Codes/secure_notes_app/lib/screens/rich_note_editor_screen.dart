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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: ActivityDetector(
        child: Scaffold(
          appBar: AppBar(
            title: Text(isNewNote ? 'New Note' : widget.note!.title),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextField(
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
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Content field
                TextField(
                  controller: _contentController,
                  enabled: _isEditing || isNewNote,
                  maxLines: null,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Start typing...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),

                // Image preview
                if (_imagePath != null) ...[
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePath!),
                          width: double.infinity,
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
                ],

                // Add image button (when editing)
                if ((_isEditing || isNewNote) && _imagePath == null) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}