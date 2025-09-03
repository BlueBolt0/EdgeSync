import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HarmonizerService {
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _apiKeyPref = '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';
  
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  // Get API key from shared preferences
  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }
  
  // Save API key to shared preferences
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
  }
  
  // Extract text from image using OCR
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      print('Starting OCR for image: $imagePath');
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      print('OCR completed. Text: ${recognizedText.text}');
      return recognizedText.text;
    } catch (e) {
      print('OCR error: $e');
      throw Exception('OCR processing failed: $e');
    }
  }
  
  // Analyze text using Groq LLM and get suggestions
  Future<HarmonizerSuggestions> analyzeText(String extractedText) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key not configured. Please set it in settings.');
    }
    
    try {
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-20b',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a JSON generator. Analyze the given text and return ONLY a valid JSON object.

RULES:
1. Return ONLY the JSON object, no other text
2. Use this EXACT structure:
{
  "calendar_events": [],
  "reminders": [],
  "contacts": [],
  "notes": []
}

3. For calendar_events, look for dates, times, meetings, appointments
4. For reminders, look for tasks, todos, deadlines
5. For contacts, look for names, phone numbers, emails
6. For notes, save any important information

Example valid response:
{"calendar_events":[{"title":"Meeting","date":"2025-09-04","time":"14:00","description":"Team meeting"}],"reminders":[],"contacts":[],"notes":[]}

If no information found, return:
{"calendar_events":[],"reminders":[],"contacts":[],"notes":[]}'''
            },
            {
              'role': 'user',
              'content': 'Analyze this text and suggest relevant actions: $extractedText'
            }
          ],
          'temperature': 0.1,
          'max_tokens': 1500,
          'top_p': 0.9,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        
        // Clean and validate the content before parsing
        String cleanContent = content.trim();
        
        // Remove any markdown code blocks if present
        if (cleanContent.startsWith('```json')) {
          cleanContent = cleanContent.substring(7);
        }
        if (cleanContent.endsWith('```')) {
          cleanContent = cleanContent.substring(0, cleanContent.length - 3);
        }
        cleanContent = cleanContent.trim();
        
        // Validate JSON structure
        if (!cleanContent.startsWith('{') || !cleanContent.endsWith('}')) {
          throw Exception('Invalid JSON format from AI response');
        }
        
        try {
          // Parse the JSON response from LLM
          final suggestions = jsonDecode(cleanContent);
          return HarmonizerSuggestions.fromJson(suggestions);
        } catch (jsonError) {
          // Fallback: try to extract partial JSON or create empty response
          print('JSON parsing error: $jsonError');
          print('Raw content: $cleanContent');
          
          // Try to fix common JSON issues
          String fixedContent = _attemptJsonFix(cleanContent);
          
          try {
            final suggestions = jsonDecode(fixedContent);
            return HarmonizerSuggestions.fromJson(suggestions);
          } catch (secondError) {
            print('Second parsing attempt failed: $secondError');
            
            // Last resort: try to extract any useful information manually
            return _parseManually(cleanContent, extractedText);
          }
        }
      } else {
        throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to analyze text: $e');
    }
  }
  
  // Execute suggested actions
  Future<void> executeCalendarAction(CalendarEvent event) async {
    try {
      // Create calendar event URL
      final startDate = DateTime.parse('${event.date} ${event.time}:00');
      final endDate = startDate.add(const Duration(hours: 1));
      
      final url = 'https://calendar.google.com/calendar/render?action=TEMPLATE'
          '&text=${Uri.encodeComponent(event.title)}'
          '&dates=${_formatDateTime(startDate)}/${_formatDateTime(endDate)}'
          '&details=${Uri.encodeComponent(event.description ?? '')}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      throw Exception('Failed to create calendar event: $e');
    }
  }
  
  Future<void> executeReminderAction(ReminderItem reminder) async {
    try {
      // For now, we'll use a simple note-taking approach
      // In a real app, you might integrate with a task management service
      final prefs = await SharedPreferences.getInstance();
      final reminders = prefs.getStringList('saved_reminders') ?? [];
      reminders.add(jsonEncode(reminder.toJson()));
      await prefs.setStringList('saved_reminders', reminders);
    } catch (e) {
      throw Exception('Failed to save reminder: $e');
    }
  }
  
  Future<void> executeContactAction(ContactInfo contact) async {
    try {
      // For now, we'll save contact info to shared preferences
      // In a future update, we can integrate with device contacts
      final prefs = await SharedPreferences.getInstance();
      final contacts = prefs.getStringList('saved_contacts') ?? [];
      contacts.add(jsonEncode(contact.toJson()));
      await prefs.setStringList('saved_contacts', contacts);
    } catch (e) {
      throw Exception('Failed to save contact: $e');
    }
  }
  
  Future<void> executeNoteAction(NoteItem note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notes = prefs.getStringList('saved_notes') ?? [];
      notes.add(jsonEncode(note.toJson()));
      await prefs.setStringList('saved_notes', notes);
    } catch (e) {
      throw Exception('Failed to save note: $e');
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}T'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '${dateTime.second.toString().padLeft(2, '0')}Z';
  }
  
  // Helper method to attempt fixing common JSON issues
  String _attemptJsonFix(String content) {
    String fixed = content;
    
    // Remove any trailing commas before closing brackets/braces
    fixed = fixed.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');
    
    // Ensure proper quotes around keys
    fixed = fixed.replaceAll(RegExp(r'(\w+):'), r'"$1":');
    
    // Fix unescaped quotes in strings
    fixed = fixed.replaceAll(RegExp(r'(?<!\\)"(?=[^,}\]:]*[,}\]:])'), r'\"');
    
    // Ensure the JSON has proper structure
    if (!fixed.trim().startsWith('{')) {
      fixed = '{$fixed';
    }
    if (!fixed.trim().endsWith('}')) {
      fixed = '$fixed}';
    }
    
    return fixed;
  }
  
  // Manual parsing as last resort
  HarmonizerSuggestions _parseManually(String content, String originalText) {
    print('Attempting manual parsing...');
    
    // Try to extract any actionable content manually
    List<CalendarEvent> events = [];
    List<ReminderItem> reminders = [];
    List<ContactInfo> contacts = [];
    List<NoteItem> notes = [];
    
    // Look for date patterns in original text
    final dateRegex = RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b');
    final timeRegex = RegExp(r'\b(\d{1,2}):(\d{2})\s*(AM|PM)?\b', caseSensitive: false);
    
    if (dateRegex.hasMatch(originalText) || timeRegex.hasMatch(originalText)) {
      events.add(CalendarEvent(
        title: 'Event from captured text',
        date: DateTime.now().add(const Duration(days: 1)).toString().substring(0, 10),
        time: '09:00',
        description: originalText.length > 100 ? originalText.substring(0, 100) + '...' : originalText,
      ));
    }
    
    // Look for phone numbers
    final phoneRegex = RegExp(r'\b(?:\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})\b');
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    
    if (phoneRegex.hasMatch(originalText) || emailRegex.hasMatch(originalText)) {
      contacts.add(ContactInfo(
        name: 'Contact from image',
        phone: phoneRegex.firstMatch(originalText)?.group(0) ?? '',
        email: emailRegex.firstMatch(originalText)?.group(0) ?? '',
        organization: '',
      ));
    }
    
    // Always create at least one note with the extracted text
    if (originalText.trim().isNotEmpty) {
      notes.add(NoteItem(
        title: 'Text from image',
        content: originalText.length > 200 ? originalText.substring(0, 200) + '...' : originalText,
        category: 'general',
      ));
    }
    
    return HarmonizerSuggestions(
      calendarEvents: events,
      reminders: reminders,
      contacts: contacts,
      notes: notes,
    );
  }
  
  void dispose() {
    _textRecognizer.close();
  }
}

// Data models
class HarmonizerSuggestions {
  final List<CalendarEvent> calendarEvents;
  final List<ReminderItem> reminders;
  final List<ContactInfo> contacts;
  final List<NoteItem> notes;
  
  HarmonizerSuggestions({
    required this.calendarEvents,
    required this.reminders,
    required this.contacts,
    required this.notes,
  });
  
  factory HarmonizerSuggestions.fromJson(Map<String, dynamic> json) {
    return HarmonizerSuggestions(
      calendarEvents: (json['calendar_events'] as List? ?? [])
          .map((e) => CalendarEvent.fromJson(e))
          .toList(),
      reminders: (json['reminders'] as List? ?? [])
          .map((e) => ReminderItem.fromJson(e))
          .toList(),
      contacts: (json['contacts'] as List? ?? [])
          .map((e) => ContactInfo.fromJson(e))
          .toList(),
      notes: (json['notes'] as List? ?? [])
          .map((e) => NoteItem.fromJson(e))
          .toList(),
    );
  }
  
  bool get hasAnySuggestions =>
      calendarEvents.isNotEmpty ||
      reminders.isNotEmpty ||
      contacts.isNotEmpty ||
      notes.isNotEmpty;
}

class CalendarEvent {
  final String title;
  final String date;
  final String time;
  final String? description;
  
  CalendarEvent({
    required this.title,
    required this.date,
    required this.time,
    this.description,
  });
  
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '09:00',
      description: json['description'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'time': time,
      'description': description,
    };
  }
}

class ReminderItem {
  final String title;
  final String description;
  final String priority;
  
  ReminderItem({
    required this.title,
    required this.description,
    required this.priority,
  });
  
  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
    };
  }
}

class ContactInfo {
  final String name;
  final String phone;
  final String email;
  final String organization;
  
  ContactInfo({
    required this.name,
    required this.phone,
    required this.email,
    required this.organization,
  });
  
  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      organization: json['organization'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'organization': organization,
    };
  }
}

class NoteItem {
  final String title;
  final String content;
  final String category;
  
  NoteItem({
    required this.title,
    required this.content,
    required this.category,
  });
  
  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'general',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
    };
  }
}
