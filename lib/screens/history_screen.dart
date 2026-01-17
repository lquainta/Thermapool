import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/temperature_service.dart';
import '../services/settings_service.dart';
import '../models/temperature_reading.dart';
import '../screens/settings_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TemperatureService, SettingsService>(
      builder: (context, tempService, settings, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Temperature History',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
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
            ],
          ),
          body: SafeArea(
            child: tempService.history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.show_chart,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No History Available',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Temperature data will appear here',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () =>
                        tempService.fetchTemperature(playSound: true),
                    color: Colors.blue,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Temperature Chart',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: _buildChart(
                                    tempService.history, settings, isDark),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'TIME WINDOW',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildWindowChip(
                                          context, settings, 1, '1h', isDark)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: _buildWindowChip(
                                          context, settings, 12, '12h', isDark)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: _buildWindowChip(context, settings,
                                          24, '24h', isDark)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: _buildWindowChip(
                                          context, settings, 72, '3d', isDark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildAverageCard(tempService, settings, isDark),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Recent Readings',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...tempService.history.take(10).map((reading) {
                          return _buildHistoryItem(reading, settings, isDark);
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildChart(List<TemperatureReading> history,
      SettingsService settings, bool isDark) {
    if (history.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final windowDuration = Duration(hours: settings.averageWindow);
    final cutoffTime = now.subtract(windowDuration);

    final filteredHistory = history
        .where((reading) => reading.timestamp.isAfter(cutoffTime))
        .toList();

    filteredHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (filteredHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No data in selected time window',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double minTemp = double.infinity;
    double maxTemp = double.negativeInfinity;

    for (int i = 0; i < filteredHistory.length; i++) {
      final temp = settings.convertTemperature(filteredHistory[i].temperature);
      spots.add(FlSpot(i.toDouble(), temp));
      if (temp < minTemp) minTemp = temp;
      if (temp > maxTemp) maxTemp = temp;
    }

    final tempRange = maxTemp - minTemp;
    final double yMin;
    final double yMax;

    if (tempRange == 0) {
      yMin = (minTemp - 5).floorToDouble();
      yMax = (maxTemp + 5).ceilToDouble();
    } else {
      yMin = (minTemp - tempRange * 0.1).floorToDouble();
      yMax = (maxTemp + tempRange * 0.1).ceilToDouble();
    }

    final double interval = (yMax - yMin) / 4;
    final double safeInterval = interval > 0 ? interval : 1;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: safeInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: spots.length > 10
                  ? (spots.length / 5).ceilToDouble()
                  : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < filteredHistory.length) {
                  final reading = filteredHistory[value.toInt()];
                  
                  // Format x-axis based on time window
                  String label;
                  if (settings.averageWindow <= 24) {
                    // For 1h, 12h, 24h: show time
                    label = '${reading.dateTime.hour}:${reading.dateTime.minute.toString().padLeft(2, '0')}';
                  } else {
                    // For 3 days: show date and time
                    label = '${reading.dateTime.month}/${reading.dateTime.day}';
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: safeInterval,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(0)}${settings.temperatureUnit}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: yMin,
        maxY: yMax,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 20,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: isDark ? Colors.grey[850]! : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                isDark ? Colors.grey[800]! : Colors.white,
            tooltipBorder: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index >= 0 && index < filteredHistory.length) {
                  final reading = filteredHistory[index];
                  return LineTooltipItem(
                    '${touchedSpot.y.toStringAsFixed(1)}${settings.temperatureUnit}\n${reading.getFormattedTime()}',
                    GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    TemperatureReading reading,
    SettingsService settings,
    bool isDark,
  ) {
    final temp = settings.convertTemperature(reading.temperature);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${temp.toStringAsFixed(0)}°',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${temp.toStringAsFixed(1)}${settings.temperatureUnit}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reading.getFormattedDateTime(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.water_drop,
            color: Colors.blue.withOpacity(0.6),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard(
      TemperatureService tempService, SettingsService settings, bool isDark) {
    final avgTemp = tempService.getAverageTemperature();
    final convertedAvg = settings.convertTemperature(avgTemp);
    
    // Create a readable label for the average window
    String windowLabel;
    if (settings.averageWindow == 1) {
      windowLabel = '1 hour';
    } else if (settings.averageWindow == 12) {
      windowLabel = '12 hours';
    } else if (settings.averageWindow == 24) {
      windowLabel = '24 hours';
    } else if (settings.averageWindow == 72) {
      windowLabel = '3 days';
    } else {
      windowLabel = '${settings.averageWindow} hours';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Temperature',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last $windowLabel',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${convertedAvg.toStringAsFixed(1)}${settings.temperatureUnit}',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowChip(BuildContext context, SettingsService settings,
      int hours, String label, bool isDark) {
    final isSelected = settings.averageWindow == hours;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => settings.setAverageWindow(hours),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue
              : isDark
                  ? Colors.grey[800]
                  : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.blue
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}