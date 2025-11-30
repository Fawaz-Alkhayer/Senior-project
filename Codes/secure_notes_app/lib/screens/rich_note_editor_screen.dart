import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
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
  late quill.QuillController _quillController;
  bool _isEditing = false;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _imagePath = widget.note!.imagePath;
      
      // Load existing content
      _quillController = quill.QuillController(
        document: quill.Document()..insert(0, widget.note!.content),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      _quillController = quill.QuillController.basic();
      _isEditing = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final plainText = _quillController.document.toPlainText();
    final now = DateTime.now();

    final note = Note(
      id: widget.note?.id,
      title: title,
      content: plainText,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      isFavorite: widget.note?.isFavorite ?? false,
      imagePath: _imagePath,
    );

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

    return ActivityDetector(
      child: Scaffold(
        appBar: AppBar(
          title: Text(isNewNote ? 'New Note' : 'Note'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          actions: [
            if (!isNewNote && !_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                    _quillController.readOnly = false;
                  });
                },
                tooltip: 'Edit',
              ),
            if (!isNewNote)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteNote,
                tooltip: 'Delete',
              ),
          ],
        ),
        body: Column(
          children: [
            // Title field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _titleController,
                enabled: _isEditing,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: 'Note Title',
                  border: _isEditing ? const UnderlineInputBorder() : InputBorder.none,
                ),
              ),
            ),

            // Formatting toolbar (only when editing)
            if (_isEditing)
              Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.grey.shade100,
                child: quill.QuillSimpleToolbar(
                  controller: _quillController,
                  config: const quill.QuillSimpleToolbarConfig(
                    showAlignmentButtons: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showInlineCode: false,
                    showCodeBlock: false,
                    showQuote: false,
                    showIndent: false,
                    showLink: false,
                    showDividers: true,
                  ),
                ),
              ),

            // Editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: quill.QuillEditor.basic(
                  controller: _quillController,
                  config: quill.QuillEditorConfig(
                    placeholder: 'Start typing...',
                    padding: EdgeInsets.zero,
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
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_isEditing)
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
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: _isEditing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'image',
                    onPressed: _pickImage,
                    backgroundColor: Colors.grey.shade700,
                    child: const Icon(Icons.image),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    heroTag: 'save',
                    onPressed: _saveNote,
                    backgroundColor: const Color(0xFF00BCD4),
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}