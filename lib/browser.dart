import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'downloads.dart';

final _fileRe = RegExp(
    r'\.(zip|rar|7z|apk|pdf|mp3|mp4|mkv|avi|iso|exe|dmg|docx?|xlsx?|pptx?|epub)(\?.*)?$',
    caseSensitive: false);

class BrowserPage extends StatefulWidget {
  final VoidCallback onDownload;
  const BrowserPage({super.key, required this.onDownload});
  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  final tf = TextEditingController();
  late final WebViewController c;

  @override
  void initState() {
    super.initState();
    c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (r) {
          if (_fileRe.hasMatch(r.url)) {
            DownloadManager.i.add(r.url);
            widget.onDownload();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageStarted: (u) => setState(() => tf.text = u),
      ))
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  void _go(String s) {
    s = s.trim();
    if (s.isEmpty) return;
    final isUrl = s.startsWith('http') || (s.contains('.') && !s.contains(' '));
    final uri = isUrl
        ? Uri.parse(s.startsWith('http') ? s : 'https://$s')
        : Uri.https('www.google.com', '/search', {'q': s});
    c.loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => c.goBack()),
          Expanded(
            child: TextField(
              controller: tf,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: _go,
              decoration: const InputDecoration(hintText: 'Rechercher avec Google ou saisir un lien', border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => c.reload()),
        ]),
        Expanded(child: WebViewWidget(controller: c)),
      ]);
}
