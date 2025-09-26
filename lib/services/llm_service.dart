import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LLMService {
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _apiKeyPref = 'groq_api_key';

  Future<Map<String, dynamic>> analyzeText(String extractedText) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString(_apiKeyPref);
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
              'content': _buildSystemPrompt(),
            },
            {
              'role': 'user',
              'content': 'Analyze this text and suggest relevant actions: $extractedText'
            }
          ],
          'temperature': 0.1,
          'max_tokens': 2000,
          'top_p': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        
        // Clean and validate the content before parsing
        String cleanContent = _cleanJsonContent(content);
        
        // Validate JSON structure
        if (!cleanContent.startsWith('{') || !cleanContent.endsWith('}')) {
          throw Exception('Invalid JSON format from AI response');
        }

        try {
          return jsonDecode(cleanContent);
        } catch (jsonError) {
          // Try to fix common JSON issues
          String fixedContent = _attemptJsonFix(cleanContent);
          return jsonDecode(fixedContent);
        }
      } else {
        throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to analyze text: $e');
    }
  }

  String _buildSystemPrompt() {
    return '''You are an expert text analysis assistant. Analyze the given text and return ONLY a valid JSON object with confidence scores and explanations.

RULES:
1. Return ONLY the JSON object, no other text or markdown
2. Include confidence scores (0.0-1.0) for each suggestion
3. Add brief explanations for your reasoning
4. Use this EXACT structure:

{
  "calendar_events": [
    {
      "title": "string",
      "date": "YYYY-MM-DD",
      "time": "HH:MM",
      "description": "string",
      "confidence": 0.0-1.0,
      "explanation": "Why this was identified as an event"
    }
  ],
  "reminders": [
    {
      "title": "string",
      "description": "string",
      "priority": "high|medium|low",
      "confidence": 0.0-1.0,
      "explanation": "Why this was identified as a reminder"
    }
  ],
  "contacts": [
    {
      "name": "string",
      "phone": "string",
      "email": "string",
      "organization": "string",
      "confidence": 0.0-1.0,
      "explanation": "What contact information was found"
    }
  ],
  "notes": [
    {
      "title": "string",
      "content": "string",
      "category": "string",
      "confidence": 0.0-1.0,
      "explanation": "Why this information should be saved"
    }
  ]
}

EXAMPLES:

Example 1 - Business Card:
Text: "John Smith, Marketing Director, ABC Corp, john@abc.com, (555) 123-4567"
Response: {"calendar_events":[],"reminders":[],"contacts":[{"name":"John Smith","phone":"(555) 123-4567","email":"john@abc.com","organization":"ABC Corp","confidence":0.95,"explanation":"Complete contact information clearly listed"}],"notes":[]}

Example 2 - Meeting Notice:
Text: "Team meeting tomorrow at 2 PM in conference room A"
Response: {"calendar_events":[{"title":"Team meeting","date":"2025-09-05","time":"14:00","description":"Team meeting in conference room A","confidence":0.8,"explanation":"Clear meeting reference with time, location implied as tomorrow"}],"reminders":[],"contacts":[],"notes":[]}

Example 3 - Mixed Content:
Text: "Buy groceries before party on Saturday. Call Mom about dinner plans. Dr. Smith appointment 3/15 at 10 AM"
Response: {"calendar_events":[{"title":"Dr. Smith appointment","date":"2025-03-15","time":"10:00","description":"Medical appointment","confidence":0.9,"explanation":"Specific appointment with date and time"}],"reminders":[{"title":"Buy groceries","description":"Buy groceries before party on Saturday","priority":"medium","confidence":0.7,"explanation":"Task with deadline context"},{"title":"Call Mom","description":"Call Mom about dinner plans","priority":"medium","confidence":0.8,"explanation":"Clear action item with purpose"}],"contacts":[],"notes":[]}

If no information found, return: {"calendar_events":[],"reminders":[],"contacts":[],"notes":[]}''';
  }

  String _cleanJsonContent(String content) {
    String cleaned = content.trim();
    
    // Remove markdown code blocks if present
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    
    return cleaned.trim();
  }

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
}
