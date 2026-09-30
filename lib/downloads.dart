import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Task {
  final String url, name, path;
  int received = 0, total = 0;
  String status = 'en attente';
  CancelToken? cancel;
  Task(this.url, this.name, this.path);
  double? get progress => total > 0 ? received / total : null;
}

class DownloadManager extends ChangeNotifier {
  static final i = DownloadManager._();
  DownloadManager._();
  final tasks = <Task>[];
  final _dio = Dio();

  Future<Directory> dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/Kora');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  Future<void> add(String url) async {
    final d = await dir();
    final segs = Uri.parse(url).pathSegments.where((s) => s.isNotEmpty);
    final name = segs.isEmpty ? 'fichier' : Uri.decodeComponent(segs.last);
    final t = Task(url, name, '${d.path}/$name');
    tasks.insert(0, t);
    notifyListeners();
    _run(t);
  }

  Future<void> _run(Task t) async {
    final f = File(t.path);
    final start = f.existsSync() ? f.lengthSync() : 0;
    t.cancel = CancelToken();
    t.status = 'en cours';
    notifyListeners();
    try {
      await _dio.download(
        t.url,
        t.path,
        cancelToken: t.cancel,
        deleteOnError: false,
        fileAccessMode: start > 0 ? FileAccessMode.append : FileAccessMode.write,
        options: Options(headers: start > 0 ? {'range': 'bytes=$start-'} : null),
        onReceiveProgress: (r, tot) {
          t.received = start + r;
          t.total = tot > 0 ? start + tot : 0;
          notifyListeners();
        },
      );
      t.status = 'terminé';
    } on DioException catch (e) {
      t.status = CancelToken.isCancel(e) ? 'en pause' : 'erreur';
    }
    notifyListeners();
  }

  void pause(Task t) => t.cancel?.cancel();
  void resume(Task t) => _run(t);
  void remove(Task t) {
    t.cancel?.cancel();
    tasks.remove(t);
    notifyListeners();
  }
}

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: DownloadManager.i,
        builder: (_, __) {
          final l = DownloadManager.i.tasks;
          if (l.isEmpty) {
            return const Center(child: Text('Aucun téléchargement.\nOuvrez un lien de fichier dans le navigateur.', textAlign: TextAlign.center));
          }
          return ListView(
            children: l.map((t) {
              final running = t.status == 'en cours';
              return ListTile(
                title: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  LinearProgressIndicator(value: t.status == 'terminé' ? 1 : t.progress),
                  Text(t.status),
                ]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (t.status != 'terminé')
                    IconButton(
                      icon: Icon(running ? Icons.pause : Icons.play_arrow),
                      onPressed: () => running ? DownloadManager.i.pause(t) : DownloadManager.i.resume(t),
                    ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => DownloadManager.i.remove(t)),
                ]),
              );
            }).toList(),
          );
        },
      );
}
