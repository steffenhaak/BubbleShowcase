import 'dart:js' as js;

final isCanvasKit = js.context['flutterCanvasKit'] != null;

final hasBlendModeClear = isCanvasKit;
