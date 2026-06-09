/// Configuration passed from Ride Setup into the camera HUD simulation.
class SimLaunchConfig {
  final String destinationLabel;
  final Map<String, dynamic>? destination;
  final Map<String, dynamic>? routeContext;
  final Map<String, dynamic>? routeVisualization;
  final Map<String, dynamic>? origin;
  final bool useLiveCamera;
  final String fixtureToken;
  final bool showGpsOnHud;
  final String riderId;
  final String sessionId;

  const SimLaunchConfig({
    required this.destinationLabel,
    this.destination,
    this.routeContext,
    this.routeVisualization,
    this.origin,
    this.useLiveCamera = true,
    this.fixtureToken = 'fixture:normal_clear',
    this.showGpsOnHud = true,
    this.riderId = 'operator-01',
    this.sessionId = 'flutter-session',
  });

  bool get hasNavigation =>
      destination != null &&
      (routeContext != null || destination!['label'] != null);
}
