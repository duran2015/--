import 'package:web/web.dart' as web;

String get consultantPortalUrl {
  final currentOrigin = web.window.location.origin;
  if (currentOrigin.contains('localhost:4312') || currentOrigin.contains('127.0.0.1:4312')) {
    return 'http://localhost:4311/counselor';
  }
  return '$currentOrigin/counselor';
}

bool openConsultantPortal() {
  web.window.location.assign(consultantPortalUrl);
  return true;
}
