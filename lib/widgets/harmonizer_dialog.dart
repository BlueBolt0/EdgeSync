import 'package:flutter/material.dart';
import '../services/harmonizer_service.dart';
import '../services/logging_service.dart';
import 'ui_components.dart';

class HarmonizerDialog extends StatefulWidget {
  final String imagePath;
  final HarmonizerService harmonizerService;

  const HarmonizerDialog({
    super.key,
    required this.imagePath,
    required this.harmonizerService,
  });

  @override
  State<HarmonizerDialog> createState() => _HarmonizerDialogState();
}

class _HarmonizerDialogState extends State<HarmonizerDialog> {
  bool _isProcessing = false;
  String _processingStep = '';
  String _extractedText = '';
  HarmonizerSuggestions? _suggestions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resetState();
    _processImage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _resetState() {
    _isProcessing = false;
    _processingStep = '';
    _extractedText = '';
    _suggestions = null;
    _error = null;
  }

  Future<void> _processImage() async {
    if (_isProcessing) {
      print('Already processing, skipping...');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStep = 'Processing OCR...';
      _error = null;
      _suggestions = null;
      _extractedText = '';
    });

    try {
      logger.info('Starting harmonizer processing for image: ${widget.imagePath}');
      
      // Extract text from image
      setState(() {
        _processingStep = 'Extracting text from image...';
      });
      
      _extractedText = await widget.harmonizerService.extractTextFromImage(widget.imagePath);
      
      logger.info('OCR completed. Text length: ${_extractedText.length}');
      
      if (_extractedText.trim().isEmpty) {
        setState(() {
          _error = 'No text found in the image';
          _isProcessing = false;
          _processingStep = '';
        });
        return;
      }

      setState(() {
        _processingStep = 'Sending to AI for analysis...';
      });
      
      // Analyze text and get suggestions
      setState(() {
        _processingStep = 'Parsing AI results...';
      });
      
      _suggestions = await widget.harmonizerService.analyzeText(_extractedText);
      
      logger.info('AI analysis completed. Suggestions found: ${_suggestions?.hasAnySuggestions ?? false}');
      
      setState(() {
        _isProcessing = false;
        _processingStep = '';
      });
    } catch (e) {
      logger.error('Error in _processImage: $e', error: e);
      setState(() {
        _error = e.toString();
        _isProcessing = false;
        _processingStep = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const ImageIcon(
                    AssetImage('assets/icons/harmonizer.png'),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Harmonizer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _isProcessing
                  ? _LoadingWidget(processingStep: _processingStep)
                  : _error != null
                      ? _ErrorWidget(
                          error: _error!,
                          onRetry: () {
                            _resetState();
                            _processImage();
                          },
                        )
                      : _suggestions != null
                          ? _SuggestionsWidget(
                              suggestions: _suggestions!,
                              extractedText: _extractedText,
                              harmonizerService: widget.harmonizerService,
                            )
                          : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  final String processingStep;
  
  const _LoadingWidget({required this.processingStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.teal),
          const SizedBox(height: 16),
          Text(
            processingStep.isNotEmpty ? processingStep : 'Analyzing image...',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'This may take a few seconds...',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  
  const _ErrorWidget({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (error.contains('API key'))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showApiKeyDialog(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Configure API Key'),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Retry'),
                  ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ApiKeyDialog(),
    );
  }
}

class _SuggestionsWidget extends StatelessWidget {
  final HarmonizerSuggestions suggestions;
  final String extractedText;
  final HarmonizerService harmonizerService;

  const _SuggestionsWidget({
    required this.suggestions,
    required this.extractedText,
    required this.harmonizerService,
  });

  @override
  Widget build(BuildContext context) {
    if (!suggestions.hasAnySuggestions) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 48),
            SizedBox(height: 16),
            Text(
              'No Actions Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No actionable content detected in this image.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Extracted text preview
          if (extractedText.isNotEmpty) ...[
            const Text(
              'Extracted Text:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                extractedText.length > 150 
                    ? '${extractedText.substring(0, 150)}...'
                    : extractedText,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Suggestions
          if (suggestions.calendarEvents.isNotEmpty)
            _SuggestionSection(
              title: 'Calendar Events',
              icon: Icons.event,
              color: Colors.blue,
              children: suggestions.calendarEvents
                  .map((event) => _CalendarEventTile(
                        event: event,
                        onExecute: () => _executeAction(() => 
                            harmonizerService.executeCalendarAction(event)),
                      ))
                  .toList(),
            ),

          if (suggestions.reminders.isNotEmpty)
            _SuggestionSection(
              title: 'Reminders',
              icon: Icons.notifications,
              color: Colors.orange,
              children: suggestions.reminders
                  .map((reminder) => _ReminderTile(
                        reminder: reminder,
                        onExecute: () => _executeAction(() =>
                            harmonizerService.executeReminderAction(reminder)),
                      ))
                  .toList(),
            ),

          if (suggestions.contacts.isNotEmpty)
            _SuggestionSection(
              title: 'Contacts',
              icon: Icons.contact_phone,
              color: Colors.green,
              children: suggestions.contacts
                  .map((contact) => _ContactTile(
                        contact: contact,
                        onExecute: () => _executeAction(() =>
                            harmonizerService.executeContactAction(contact)),
                      ))
                  .toList(),
            ),

          if (suggestions.notes.isNotEmpty)
            _SuggestionSection(
              title: 'Notes',
              icon: Icons.note,
              color: Colors.purple,
              children: suggestions.notes
                  .map((note) => _NoteTile(
                        note: note,
                        onExecute: () => _executeAction(() =>
                            harmonizerService.executeNoteAction(note)),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _executeAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      // Handle error (could show a snackbar)
      debugPrint('Action execution failed: $e');
    }
  }
}

class _SuggestionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SuggestionSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  final CalendarEvent event;
  final VoidCallback onExecute;

  const _CalendarEventTile({
    required this.event,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(event.title, style: const TextStyle(color: Colors.white)),
            ),
            ConfidenceIndicator(confidence: event.confidence),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${event.date} at ${event.time}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (event.explanation != null && event.explanation!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'AI: ${event.explanation}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          onPressed: onExecute,
          icon: const Icon(Icons.add_to_photos, color: Colors.blue),
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final ReminderItem reminder;
  final VoidCallback onExecute;

  const _ReminderTile({
    required this.reminder,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(reminder.title, style: const TextStyle(color: Colors.white)),
            ),
            ConfidenceIndicator(confidence: reminder.confidence),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reminder.description,
              style: const TextStyle(color: Colors.white70),
            ),
            if (reminder.explanation != null && reminder.explanation!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'AI: ${reminder.explanation}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          onPressed: onExecute,
          icon: const Icon(Icons.add_alarm, color: Colors.orange),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final ContactInfo contact;
  final VoidCallback onExecute;

  const _ContactTile({
    required this.contact,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(contact.name, style: const TextStyle(color: Colors.white)),
            ),
            ConfidenceIndicator(confidence: contact.confidence),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [contact.phone, contact.email, contact.organization]
                  .where((s) => s.isNotEmpty)
                  .join(' • '),
              style: const TextStyle(color: Colors.white70),
            ),
            if (contact.explanation != null && contact.explanation!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'AI: ${contact.explanation}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          onPressed: onExecute,
          icon: const Icon(Icons.save, color: Colors.green),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onExecute;

  const _NoteTile({
    required this.note,
    required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.purple.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Expanded(
              child: Text(note.title, style: const TextStyle(color: Colors.white)),
            ),
            ConfidenceIndicator(confidence: note.confidence),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.content,
              style: const TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.explanation != null && note.explanation!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'AI: ${note.explanation}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          onPressed: onExecute,
          icon: const Icon(Icons.note_add, color: Colors.purple),
        ),
      ),
    );
  }
}

class ApiKeyDialog extends StatefulWidget {
  const ApiKeyDialog({super.key});

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  final _controller = TextEditingController();
  bool _isObscured = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Configure Groq API Key',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your Groq API key to enable harmonizer features:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _isObscured,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'gsk_...',
              hintStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.teal),
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isObscured = !_isObscured),
                icon: Icon(
                  _isObscured ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Get your free API key from console.groq.com',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_controller.text.trim().isNotEmpty) {
              final service = HarmonizerService();
              await service.saveApiKey(_controller.text.trim());
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('API key saved successfully!'),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
