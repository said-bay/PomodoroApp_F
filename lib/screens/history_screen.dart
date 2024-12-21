import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDate = DateTime(date.year, date.month, date.day);

    if (recordDate == today) {
      return 'Bugün';
    } else if (recordDate == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM', 'tr_TR').format(date);
    }
  }

  Map<String, List<PomodoroRecord>> _groupByDate(List<PomodoroRecord> records) {
    final Map<String, List<PomodoroRecord>> grouped = {};
    
    for (var record in records) {
      final dateStr = _formatDate(record.date);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(record);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<TimerModel>(
      builder: (context, timer, child) {
        final groupedRecords = _groupByDate(timer.history);

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => timer.setScreen('timer'),
            ),
            title: const Text(
              'Pomodoro Geçmişi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w300,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[900],
                      title: const Text(
                        'Geçmişi Sil',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Tüm geçmiş silinecek. Emin misiniz?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'İptal',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            timer.clearHistory();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Sil',
                            style: TextStyle(color: Colors.red[400]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: timer.history.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz geçmiş yok',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: groupedRecords.length,
                  itemBuilder: (context, index) {
                    final date = groupedRecords.keys.elementAt(index);
                    final records = groupedRecords[date]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            date,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ...records.map((record) => ListTile(
                          leading: Icon(
                            record.completed ? Icons.check_circle : Icons.cancel,
                            color: record.completed ? Colors.green : Colors.red[400],
                          ),
                          title: Text(
                            DateFormat('HH:mm').format(record.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          trailing: Text(
                            '${record.duration} dakika',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                          subtitle: record.completed 
                              ? null 
                              : Text(
                                  record.note ?? '1dk çalışıldı',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                        )).toList(),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}