import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/temperature_service.dart';
import '../services/settings_service.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ThermaPool',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          Semantics(
            label: 'Open settings',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              iconSize: 24,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<TemperatureService, SettingsService>(
          builder: (context, tempService, settings, _) {
            if (tempService.isLoading && tempService.currentReading == null) {
              return Center(
                child: CupertinoActivityIndicator(
                  radius: 16,
                  color: Colors.blue,
                ),
              );
            }

            if (tempService.error != null && tempService.currentReading == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to fetch temperature',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tempService.error!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CupertinoButton.filled(
                        onPressed: () => tempService.fetchTemperature(playSound: true),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Retry',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final reading = tempService.currentReading;
            if (reading == null) {
              return Center(
                child: Text(
                  'No data available',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            }

            final temp = settings.convertTemperature(reading.temperature);
            final unit = settings.temperatureUnit;

            return RefreshIndicator(
              onRefresh: () => tempService.fetchTemperature(playSound: true),
              color: Colors.blue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue.withOpacity(0.3),
                                Colors.blue.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${temp.toStringAsFixed(1)}$unit',
                                  style: GoogleFonts.inter(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(
                                  Icons.water_drop,
                                  size: 32,
                                  color: Colors.blue.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildTemperatureStatus(reading.temperature),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              reading.getFormattedTime(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.grey[850]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildInfoItem(
                                    context,
                                    Icons.sync,
                                    'Updates',
                                    switch (settings.updateInterval) {
                                      1800 => 'Every 30 minutes',
                                      3600 => 'Every hour',
                                      10800 => 'Every 3 hours',
                                      43200 => 'Every 12 hours',
                                      _ => 'Unknown interval',
                                    }
                                    
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                                  ),
                                  _buildInfoItem(
                                    context,
                                    Icons.thermostat,
                                    'Unit',
                                    settings.isCelsius ? 'Celsius' : 'Fahrenheit',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                height: 1,
                                color: isDark ? Colors.grey[700] : Colors.grey[300],
                              ),
                              const SizedBox(height: 20),
                              _buildAverageInfo(context, tempService, settings, isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTemperatureStatus(double tempFahrenheit) {
    IconData icon;
    String message;
    Color color;

    if (tempFahrenheit >= 78 && tempFahrenheit <= 83) {
      icon = Icons.check_circle;
      message = "Perfect Temperature!";
      color = Colors.green;
    } else if (tempFahrenheit > 83) {
      icon = Icons.local_fire_department;
      message = tempFahrenheit > 90 ? "Too Hot!" : "Too Warm";
      color = Colors.orange;
    } else {
      icon = Icons.ac_unit;
      message = tempFahrenheit < 70 ? "Too Cold!" : "Too Cool";
      color = Colors.blue;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAverageInfo(BuildContext context, TemperatureService tempService, SettingsService settings, bool isDark) {
    final avgTemp = tempService.getAverageTemperature();
    final convertedAvg = settings.convertTemperature(avgTemp);
    
    // Create readable label
    String windowLabel;
    if (settings.averageWindow == 1) {
      windowLabel = '1h';
    } else if (settings.averageWindow == 12) {
      windowLabel = '12h';
    } else if (settings.averageWindow == 24) {
      windowLabel = '24h';
    } else if (settings.averageWindow == 72) {
      windowLabel = '3d';
    } else {
      windowLabel = '${settings.averageWindow}h';
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.show_chart, size: 20, color: Colors.blue.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          'Average ($windowLabel): ',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          '${convertedAvg.toStringAsFixed(1)}${settings.temperatureUnit}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}