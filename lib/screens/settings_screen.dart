import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Settings',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            leading: Semantics(
              label: 'Go back',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildSectionHeader('Appearance'),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  trailing: CupertinoSwitch(
                    value: settings.isDarkMode,
                    onChanged: (_) => settings.toggleDarkMode(),
                    activeColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Temperature'),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  context,
                  icon: Icons.thermostat_outlined,
                  title: 'Temperature Unit',
                  subtitle: settings.isCelsius ? 'Celsius (°C)' : 'Fahrenheit (°F)',
                  trailing: CupertinoSwitch(
                    value: settings.isCelsius,
                    onChanged: (_) => settings.toggleTemperatureUnit(),
                    activeColor: Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('Update Frequency'),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildIntervalButton(context, settings, 1800, 'Fast', 'Updates every 30 minutes'),
                      const SizedBox(height: 8),
                      _buildIntervalButton(context, settings, 3600, 'Normal', 'Updates every hour'),
                      const SizedBox(height: 8),
                      _buildIntervalButton(context, settings, 10800, 'Slow', 'Updates every 3 hours'),
                      const SizedBox(height: 8),
                      _buildIntervalButton(context, settings, 43200, 'Very Slow', 'Updates every 12 hours'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('API Configuration'),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  context,
                  icon: Icons.cloud_outlined,
                  title: 'Server Endpoint',
                  subtitle: 'Configure ThermaPool server',
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: () => _showEndpointDialog(context, settings),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('About'),
                const SizedBox(height: 8),
                _buildSettingsTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'ThermaPool',
                  subtitle: 'Version 1.0.0',
                  trailing: const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showEndpointDialog(BuildContext context, SettingsService settings) {
    final controller = TextEditingController(text: settings.apiEndpoint);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'API Endpoint',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the ThermaPool server URL:',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'https://api.example.com/temp',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                keyboardType: TextInputType.url,
                maxLines: 3,
                minLines: 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              settings.setApiEndpoint(controller.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'API endpoint updated',
                    style: GoogleFonts.inter(),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.blue,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalButton(
    BuildContext context,
    SettingsService settings,
    int seconds,
    String label,
    String description,
  ) {
    final isSelected = settings.updateInterval == seconds;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => settings.setUpdateInterval(seconds),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : isDark
                  ? Colors.grey[850]
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: isSelected ? Colors.white : (isDark ? Colors.grey[400]! : Colors.grey[600]!),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? Colors.white 
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isSelected
                          ? Colors.white.withOpacity(0.8)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}