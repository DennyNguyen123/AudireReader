import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audire_reader/models/book.dart';
import 'package:audire_reader/core/database/database_helper.dart';
import 'package:audire_reader/l10n/app_localizations.dart';

class EditBookDialog extends StatefulWidget {
  final Book book;

  const EditBookDialog({super.key, required this.book});

  @override
  State<EditBookDialog> createState() => _EditBookDialogState();
}

class _EditBookDialogState extends State<EditBookDialog> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  String? _newCoverPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _newCoverPath = widget.book.coverPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickNewCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _newCoverPath = result.files.single.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final newTitle = _titleController.text.trim();
    final newAuthor = _authorController.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    widget.book.title = newTitle;
    widget.book.author = newAuthor.isEmpty ? 'Unknown' : newAuthor;
    widget.book.coverPath = _newCoverPath;

    final db = await DatabaseHelper.getInstance();
    await db.saveBook(widget.book);

    if (mounted) {
      Navigator.pop(context, true); // true = has changes
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Book'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Image Preview
            Center(
              child: GestureDetector(
                onTap: _pickNewCover,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                    image: _newCoverPath != null && File(_newCoverPath!).existsSync()
                        ? DecorationImage(
                            image: FileImage(File(_newCoverPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: (_newCoverPath == null || !File(_newCoverPath!).existsSync())
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 40, color: isDark ? Colors.white54 : Colors.black54),
                            const SizedBox(height: 8),
                            Text('Change Cover', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                          ],
                        )
                      : Container(
                          alignment: Alignment.bottomCenter,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Tap to change', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _authorController,
              decoration: InputDecoration(
                labelText: 'Author',
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.black12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
        ),
      ],
    );
  }
}
