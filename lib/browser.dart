import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win;
import 'downloads.dart';

final _fileRe = RegExp(
    r'\.(zip|rar|7z|apk|pdf|mp3|mp4|mkv|avi|iso|exe|dmg|docx?|xlsx?|pptx?|epub)(\?.*)?$',
    caseSensitive: false);

Uri _toUri(String s) {
  s = s.trim();
  final isUrl = s.startsWith('http') || (s.contains('.') && !s.contains(' '));
  return isUrl
      ? Uri.parse(s.startsWith('http') ? s : 'https://$s')
      : Uri.https('www.google.com', '/search', {'q': s});
}

class BrowserPage extends StatelessWidget {
  final VoidCallback onDownload;
  const BrowserPage({super.key, required this.onDownload});
  @override
  Widget build(BuildContext context) => Platform.isWindows
      ? _WinBrowser(onDownload: onDownload)
      : _MobileBrowser(onDownload: onDownload);
}

Widget _bar(TextEditingController tf, void Function(String) go, VoidCallback back, VoidCallback reload) =>
    Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: back),
      Expanded(
        child: TextField(
          controller: tf,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: go,
          decoration: const InputDecoration(hintText: 'Rechercher avec Google ou saisir un lien', border: InputBorder.none),
        ),
      ),
      IconButton(icon: const Icon(Icons.refresh), onPressed: reload),
    ]);

class _MobileBrowser extends StatefulWidget {
  final VoidCallback onDownload;
  const _MobileBrowser({required this.onDownload});
  @override
  State<_MobileBrowser> createState() => _MobileBrowserState();
}

class _MobileBrowserState extends State<_MobileBrowser> {
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

  @override
  Widget build(BuildContext context) => Column(children: [
        _bar(tf, (s) {
          if (s.trim().isNotEmpty) c.loadRequest(_toUri(s));
        }, () => c.goBack(), () => c.reload()),
        Expanded(child: WebViewWidget(controller: c)),
      ]);
}

const _js = r'''
document.addEventListener('click', function (e) {
  var a = e.target.closest ? e.target.closest('a') : null;
  if (a && a.href && /\.(zip|rar|7z|apk|pdf|mp3|mp4|mkv|avi|iso|exe|dmg|docx?|xlsx?|pptx?|epub)(\?.*)?$/i.test(a.href)) {
    e.preventDefault();
    e.stopPropagation();
    window.chrome.webview.postMessage(a.href);
  }
}, true);
''';

class _WinBrowser extends StatefulWidget {
  final VoidCallback onDownload;
  const _WinBrowser({required this.onDownload});
  @override
  State<_WinBrowser> createState() => _WinBrowserState();
}

class _WinBrowserState extends State<_WinBrowser> {
  final tf = TextEditingController();
  final c = win.WebviewController();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await c.initialize();
    await c.setPopupWindowPolicy(win.WebviewPopupWindowPolicy.sameWindow);
    await c.addScriptToExecuteOnDocumentCreated(_js);
    c.url.listen((u) {
      if (mounted) setState(() => tf.text = u);
    });
    c.webMessage.listen((m) {
      final u = m.toString();
      if (_fileRe.hasMatch(u)) {
        DownloadManager.i.add(u);
        widget.onDownload();
      }
    });
    await c.loadUrl('https://www.google.com');
    if (mounted) setState(() => ready = true);
  }

  @override
  void dispose() {
    c.dispose();
    tf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        _bar(tf, (s) {
          if (s.trim().isNotEmpty) c.loadUrl(_toUri(s).toString());
        }, () => c.goBack(), () => c.reload()),
        Expanded(child: ready ? win.Webview(c) : const Center(child: CircularProgressIndicator())),
      ]);
}
