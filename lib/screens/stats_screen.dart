import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TimerModel>(
      builder: (context, timer, child) {
        final stats = timer.calculateStats();
        final productiveHours = timer.calculateMostProductiveHours();

        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // Üst Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () => timer.setScreen('timer'),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'İSTATİSTİKLER',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),

                // İstatistikler
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Bugün
                        _buildStatsSection(
                          context,
                          'Bugün',
                          stats.today.completed,
                          stats.today.total > 0
                              ? ((stats.today.completed * 100.0) / stats.today.total).round()
                              : 0,
                          stats.today.totalMinutes,
                          'dakika',
                        ),

                        // Bu Hafta
                        _buildStatsSection(
                          context,
                          'Bu Hafta',
                          stats.week.completed,
                          stats.week.total > 0
                              ? ((stats.week.completed * 100.0) / stats.week.total).round()
                              : 0,
                          (stats.week.totalMinutes / 60.0).ceil(),
                          'saat',
                        ),

                        // Bu Ay
                        _buildStatsSection(
                          context,
                          'Bu Ay',
                          stats.month.completed,
                          stats.month.total > 0
                              ? ((stats.month.completed * 100.0) / stats.month.total).round()
                              : 0,
                          (stats.month.totalMinutes / 60.0).ceil(),
                          'saat',
                        ),

                        // En Verimli Saatler
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: theme.dividerColor),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'En Verimli Saatler',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: productiveHours.map((hour) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      '${hour.toString().padLeft(2, '0')}:00',
                                      style: AppTheme.clockTextStyle.copyWith(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        // Toplam
                        _buildStatsSection(
                          context,
                          'Toplam',
                          stats.all.completed,
                          stats.all.total > 0
                              ? (stats.all.completed / stats.all.total * 100).round()
                              : 0,
                          (stats.all.totalMinutes / 60).round(),
                          'saat',
                          showBorder: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    String title,
    int completed,
    int successRate,
    int total,
    String unit, {
    bool showBorder = true,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: showBorder
              ? BorderSide(color: theme.dividerColor)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                completed.toString(),
                'Tamamlanan',
              ),
              _buildStatItem(
                context,
                '$successRate%',
                'Başarı',
              ),
              _buildStatItem(
                context,
                total.toString(),
                unit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: AppTheme.timerTextStyle.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.clockTextStyle.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }
} 