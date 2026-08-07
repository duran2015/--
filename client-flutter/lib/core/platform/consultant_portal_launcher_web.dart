import 'package:web/web.dart' as web;

const String consultantPortalUrl = String.fromEnvironment(
  'COUNSELOR_PORTAL_URL',
  defaultValue: 'http://localhost:4311/counselor',
);

bool openConsultantPortal() {
  web.window.location.assign(consultantPortalUrl);
  return true;
}
