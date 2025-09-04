import 'dart:convert';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fcontacts;
import 'package:share_plus/share_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';
import 'llm_service.dart';
import 'logging_service.dart';
import 'notifications_service.dart';

class HarmonizerService {
  static const String _apiKeyPref = 'groq_api_key';
  
  final TextRecognizer _textRecognizer = TextRecognizer();
  final LLMService _llmService = LLMService();
  
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
    logger.startOperation('ocr_extraction');
    try {
      logger.info('Starting OCR for image: $imagePath', operation: 'ocr_extraction');
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      logger.info('OCR completed. Text: ${recognizedText.text}', operation: 'ocr_extraction');
      logger.endOperation('ocr_extraction');
      return recognizedText.text;
    } catch (e) {
      logger.error('OCR error: $e', operation: 'ocr_extraction', error: e);
      logger.endOperation('ocr_extraction');
      throw Exception('OCR processing failed: $e');
    }
  }
  
  // Analyze text using Groq LLM and get suggestions
  Future<HarmonizerSuggestions> analyzeText(String extractedText) async {
    logger.startOperation('llm_analysis');
    try {
      logger.info('Starting LLM analysis for text: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}...', operation: 'llm_analysis');
      
      final apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Groq API key not configured. Please set it in settings.');
      }
      
      final response = await _llmService.analyzeText(extractedText);
      final suggestions = HarmonizerSuggestions.fromJson(response);
      logger.info('LLM analysis completed successfully', operation: 'llm_analysis');
      logger.endOperation('llm_analysis');
      return suggestions;
    } catch (e) {
      logger.error('LLM analysis failed: $e', operation: 'llm_analysis', error: e);
      logger.endOperation('llm_analysis');
      rethrow;
    }
  }

  // Execute suggested actions
  Future<void> executeCalendarAction(CalendarEvent event) async {
    try {
      final startDate = DateTime.parse('${event.date}T${event.time}:00');
      final endDate = startDate.add(const Duration(hours: 1));

      // Prefer native calendar insert on Android
      if (Platform.isAndroid) {
        // Request calendar permission if needed
        final status = await Permission.calendar.request();
        if (status.isGranted) {
          final intent = AndroidIntent(
            action: 'android.intent.action.INSERT',
            data: 'content://com.android.calendar/events',
            arguments: <String, dynamic>{
              'title': event.title,
              'description': event.description ?? '',
              'beginTime': startDate.millisecondsSinceEpoch,
              'endTime': endDate.millisecondsSinceEpoch,
            },
          );
          await intent.launch();
          return;
        }
      }

      // Fallback: open Google Calendar web template
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
      // Schedule a local notification as a reminder
      await NotificationsService.instance.ensureInitialized();

      // Try to parse a due date/time from description if present (very simple heuristic)
      final now = DateTime.now();
      final scheduled = now.add(const Duration(minutes: 1));

      await NotificationsService.instance.scheduleReminder(
        title: 'Reminder: ${reminder.title}',
        body: reminder.description,
        scheduledDate: scheduled,
      );

      // Also persist to local storage for history
      final prefs = await SharedPreferences.getInstance();
      final reminders = prefs.getStringList('saved_reminders') ?? [];
      reminders.add(jsonEncode(reminder.toJson()));
      await prefs.setStringList('saved_reminders', reminders);
    } catch (e) {
      throw Exception('Failed to schedule reminder: $e');
    }
  }
  
  Future<void> executeContactAction(ContactInfo contact) async {
    try {
      // Request permission
      if (!await fcontacts.FlutterContacts.requestPermission()) {
        throw Exception('Contacts permission denied');
      }

      final newContact = fcontacts.Contact(
        name: fcontacts.Name(first: contact.name),
        phones: contact.phone.isNotEmpty ? [fcontacts.Phone(contact.phone)] : [],
        emails: contact.email.isNotEmpty ? [fcontacts.Email(contact.email)] : [],
        organizations: contact.organization.isNotEmpty
            ? [fcontacts.Organization(company: contact.organization)]
            : [],
      );

      await newContact.insert();

      // Also persist to local storage for history
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
      final content = '${note.title}\n\n${note.content}';

      if (Platform.isAndroid) {
        // Try direct share to Google Keep
        try {
          final intent = AndroidIntent(
            action: 'android.intent.action.SEND',
            type: 'text/plain',
            package: 'com.google.android.keep',
            arguments: <String, dynamic>{
              'android.intent.extra.SUBJECT': note.title,
              'android.intent.extra.TEXT': content,
            },
          );
          await intent.launch();
        } catch (_) {
          // Fallback to generic share sheet
          await Share.share(content, subject: note.title);
        }
      } else {
        // Other platforms: generic share
        await Share.share(content, subject: note.title);
      }

      // Also persist to local storage for history
      final prefs = await SharedPreferences.getInstance();
      final notes = prefs.getStringList('saved_notes') ?? [];
      notes.add(jsonEncode(note.toJson()));
      await prefs.setStringList('saved_notes', notes);
    } catch (e) {
      throw Exception('Failed to share note: $e');
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
  final double confidence;
  final String? explanation;
  
  CalendarEvent({
    required this.title,
    required this.date,
    required this.time,
    this.description,
    this.confidence = 0.0,
    this.explanation,
  });
  
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '09:00',
      description: json['description'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      explanation: json['explanation'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'time': time,
      'description': description,
      'confidence': confidence,
      'explanation': explanation,
    };
  }
}

class ReminderItem {
  final String title;
  final String description;
  final String priority;
  final double confidence;
  final String? explanation;
  
  ReminderItem({
    required this.title,
    required this.description,
    required this.priority,
    this.confidence = 0.0,
    this.explanation,
  });
  
  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'medium',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      explanation: json['explanation'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'priority': priority,
      'confidence': confidence,
      'explanation': explanation,
    };
  }
}

class ContactInfo {
  final String name;
  final String phone;
  final String email;
  final String organization;
  final double confidence;
  final String? explanation;
  
  ContactInfo({
    required this.name,
    required this.phone,
    required this.email,
    required this.organization,
    this.confidence = 0.0,
    this.explanation,
  });
  
  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      organization: json['organization'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      explanation: json['explanation'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'organization': organization,
      'confidence': confidence,
      'explanation': explanation,
    };
  }
}

class NoteItem {
  final String title;
  final String content;
  final String category;
  final double confidence;
  final String? explanation;
  
  NoteItem({
    required this.title,
    required this.content,
    required this.category,
    this.confidence = 0.0,
    this.explanation,
  });
  
  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'general',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      explanation: json['explanation'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'category': category,
      'confidence': confidence,
      'explanation': explanation,
    };
  }
}
