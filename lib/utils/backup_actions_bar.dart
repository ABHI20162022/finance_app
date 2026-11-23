import 'package:flutter/material.dart';
import '../utils/backup_helper.dart';

class BackupRestoreBar extends StatelessWidget {
  final Future<void> Function()? onRestored;

  const BackupRestoreBar({super.key, this.onRestored});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.backup, size: 18),
            label: const Text('Backup'),
            onPressed: () async {
              try {
                await BackupHelper.exportBackupFile();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Backup JSON ready! Save to Google Drive, WhatsApp, or Files.'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backup failed: $e')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Restore'),
            onPressed: () async {
              try {
                final restored = await BackupHelper.importBackupFile();
                if (!restored) return;
                if (onRestored != null) {
                  await onRestored!();
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup restored successfully!'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore failed: $e')),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}