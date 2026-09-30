import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'downloads.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});
  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    _load();
    DownloadManager.i.addListener(_load);
  }

  @override
  void dispose() {
    DownloadManager.i.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final d = await DownloadManager.i.dir();
    final l = d.listSync().whereType<File>().toList();
    if (mounted) setState(() => files = l);
  }

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const Center(child: Text('Aucun fichier.'));
    return ListView(
      children: files.map((f) {
        final name = f.path.split('/').last;
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => OpenFilex.open(f.path),
          trailing: PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'share') await Share.shareXFiles([XFile(f.path)]);
              if (v == 'delete') {
                await f.delete();
                _load();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'share', child: Text('Partager')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        );
      }).toList(),
    );
  }
}
