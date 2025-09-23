import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/harmonizer_service.dart';

class HarmonizerSettingsScreen extends StatefulWidget {
  const HarmonizerSettingsScreen({super.key});

  @override
  State<HarmonizerSettingsScreen> createState() => _HarmonizerSettingsScreenState();
}

class _HarmonizerSettingsScreenState extends State<HarmonizerSettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isObscured = true;
  bool _isLoading = false;
  String? _currentApiKey;
  List<String> _savedReminders = [];
  List<String> _savedNotes = [];
  List<String> _savedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('groq_api_key');
      final reminders = prefs.getStringList('saved_reminders') ?? [];
      final notes = prefs.getStringList('saved_notes') ?? [];
      final contacts = prefs.getStringList('saved_contacts') ?? [];
      
      setState(() {
        _currentApiKey = apiKey;
        _apiKeyController.text = apiKey ?? '';
        _savedReminders = reminders;
        _savedNotes = notes;
        _savedContacts = contacts;
      });
    } catch (e) {
      _showError('Failed to load settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      _showError('Please enter an API key');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final service = HarmonizerService();
      await service.saveApiKey(_apiKeyController.text.trim());
      
      setState(() {
        _currentApiKey = _apiKeyController.text.trim();
      });
      
      _showSuccess('API key saved successfully!');
    } catch (e) {
      _showError('Failed to save API key: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearApiKey() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('groq_api_key');
      
      setState(() {
        _currentApiKey = null;
        _apiKeyController.clear();
      });
      
      _showSuccess('API key cleared');
    } catch (e) {
      _showError('Failed to clear API key: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_reminders');
      setState(() => _savedReminders.clear());
      _showSuccess('Reminders cleared');
    } catch (e) {
      _showError('Failed to clear reminders: $e');
    }
  }

  Future<void> _clearContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_contacts');
      setState(() => _savedContacts.clear());
      _showSuccess('Contacts cleared');
    } catch (e) {
      _showError('Failed to clear contacts: $e');
    }
  }

  Future<void> _clearNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_notes');
      setState(() => _savedNotes.clear());
      _showSuccess('Notes cleared');
    } catch (e) {
      _showError('Failed to clear notes: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Row(
          children: [
            ImageIcon(
              AssetImage('assets/icons/harmonizer.png'),
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Harmonizer Settings',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // API Key Section
                  _buildSection(
                    title: 'API Configuration',
                    icon: Icons.key,
                    children: [
                      const Text(
                        'Groq API Key',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _apiKeyController,
                        obscureText: _isObscured,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter your Groq API key',
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
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveApiKey,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save API Key'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_currentApiKey != null)
                            ElevatedButton(
                              onPressed: _clearApiKey,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentApiKey != null 
                            ? '✓ API key configured'
                            : '⚠ API key not set',
                        style: TextStyle(
                          color: _currentApiKey != null 
                              ? Colors.green 
                              : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Get your free API key from console.groq.com',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Saved Data Section
                  _buildSection(
                    title: 'Saved Data',
                    icon: Icons.storage,
                    children: [
                      _buildDataTile(
                        title: 'Reminders',
                        count: _savedReminders.length,
                        onClear: _clearReminders,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 8),
                      _buildDataTile(
                        title: 'Contacts',
                        count: _savedContacts.length,
                        onClear: _clearContacts,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildDataTile(
                        title: 'Notes',
                        count: _savedNotes.length,
                        onClear: _clearNotes,
                        color: Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // How it Works Section
                  _buildSection(
                    title: 'How Harmonizer Works',
                    icon: Icons.info_outline,
                    children: [
                      _buildInfoTile(
                        icon: Icons.camera_alt,
                        title: 'Capture',
                        description: 'Take a photo with Harmonizer enabled',
                      ),
                      _buildInfoTile(
                        icon: Icons.text_fields,
                        title: 'Extract',
                        description: 'OCR technology extracts text from your image',
                      ),
                      _buildInfoTile(
                        icon: Icons.psychology,
                        title: 'Analyze',
                        description: 'AI analyzes the text for actionable content',
                      ),
                      _buildInfoTile(
                        icon: Icons.integration_instructions,
                        title: 'Integrate',
                        description: 'Suggests calendar events, reminders, contacts & notes',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Features Section
                  _buildSection(
                    title: 'Supported Features',
                    icon: Icons.featured_play_list,
                    children: [
                      _buildFeatureTile(
                        icon: Icons.event,
                        title: 'Calendar Events',
                        description: 'Automatically detect meetings and appointments',
                        color: Colors.blue,
                      ),
                      _buildFeatureTile(
                        icon: Icons.notifications,
                        title: 'Reminders',
                        description: 'Save important tasks and follow-ups',
                        color: Colors.orange,
                      ),
                      _buildFeatureTile(
                        icon: Icons.contact_phone,
                        title: 'Contacts',
                        description: 'Extract and save contact information',
                        color: Colors.green,
                      ),
                      _buildFeatureTile(
                        icon: Icons.note,
                        title: 'Notes',
                        description: 'Save important information and ideas',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataTile({
    required String title,
    required int count,
    required VoidCallback onClear,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.data_object, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$count items saved',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (count > 0)
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
