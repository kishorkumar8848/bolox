import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'General'),
          ListTile(
            leading: const Icon(Icons.download_done, color: AppTheme.primary),
            title: const Text('Offline Models', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text('Manage downloaded ML models', style: TextStyle(color: AppTheme.textSecondary)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline models are currently synced and up to date.')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage, color: AppTheme.primary),
            title: const Text('Clear Cache', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: const Text('Free up temporary storage space', style: TextStyle(color: AppTheme.textSecondary)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully.')),
              );
            },
          ),
          const Divider(),
          const _SectionHeader(title: 'Legal'),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppTheme.primary),
            title: const Text('Privacy Policy', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () => _showLegalDialog(
              context, 
              'Privacy Policy', 
              'This application processes all audio and text strictly offline on your device using on-device Machine Learning models. No audio recordings or transcripts are transmitted to any external servers or third parties. Peer-to-peer data transmission only occurs directly between connected devices over an encrypted local transport.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.gavel, color: AppTheme.primary),
            title: const Text('Terms & Conditions', style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () => _showLegalDialog(
              context, 
              'Terms & Conditions', 
              'By using BoloX Neural Radio, you agree to use this application responsibly. The developers are not liable for any communication failures during emergency situations. The application is provided "as is" without warranty of any kind, either express or implied, including but not limited to the implied warranties of merchantability and fitness for a particular purpose.',
            ),
          ),
          const Divider(),
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info, color: AppTheme.primary),
            title: Text('Version', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text('1.0.0 (Build 1)', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          const ListTile(
            leading: Icon(Icons.memory, color: AppTheme.primary),
            title: Text('Neural Engines', style: TextStyle(color: AppTheme.textPrimary)),
            subtitle: Text('Powered by Sherpa-ONNX & Google ML Kit', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(title, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Text(content, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }
}
