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

        return WillPopScope(
          onWillPop: () async {
            timer.setScreen('home');
            return false;
          },
          child: Scaffold(
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
                          _buildProductiveHours(context, productiveHours),

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
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(BuildContext context, String title, int completed, int percentage, int total, String unit) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$completed/$total',
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tamamlanan',
                    style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$total $unit',
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toplam Süre',
                    style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '%$percentage başarı',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductiveHours(BuildContext context, List<int> hours) {
    if (hours.isEmpty) return const SizedBox.shrink();
    
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'En Verimli Saatler',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hours.map((hour) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 