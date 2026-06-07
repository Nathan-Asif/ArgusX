import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/websocket_service.dart';
import 'viewports/hud_viewport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force high-frame 16:9 landscape orientation lock
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system overlays for full screen HUD view
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final wsService = WebSocketService();

  runApp(ArgusHUDApp(wsService: wsService));
}

class ArgusHUDApp extends StatelessWidget {
  final WebSocketService wsService;

  const ArgusHUDApp({
    super.key,
    required this.wsService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArgusX HUD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030303),
        useMaterial3: true,
      ),
      home: HudViewport(wsService: wsService),
    );
  }
}
