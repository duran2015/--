import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../router/route_paths.dart';
import 'consultant_portal_launcher_stub.dart'
    if (dart.library.js_interop) 'consultant_portal_launcher_web.dart';

export 'consultant_portal_launcher_stub.dart'
    if (dart.library.js_interop) 'consultant_portal_launcher_web.dart';

void navigateOrOpenPortal(BuildContext context, String route) {
  if (route == RoutePaths.counselor) {
    openConsultantPortal();
  } else {
    context.go(route);
  }
}
