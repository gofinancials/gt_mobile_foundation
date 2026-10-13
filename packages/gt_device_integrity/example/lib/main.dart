import 'package:flutter/material.dart';
import 'package:gt_device_integrity/gt_device_integrity.dart';

void main() => runApp(const MaterialApp(home: ReportScreen()));

/// Lists every reading, so the checks can be tried on a real device.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('gt_device_integrity')),
      body: FutureBuilder(
        future: const GtDeviceIntegrity().report(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final report = snapshot.data;
          if (report == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              for (final entry in report.toMap().entries)
                ListTile(
                  title: Text(entry.key),
                  trailing: Text('${entry.value}'),
                ),
            ],
          );
        },
      ),
    );
  }
}
