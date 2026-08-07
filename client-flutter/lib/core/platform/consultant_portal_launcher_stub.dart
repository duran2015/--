const String consultantPortalUrl = String.fromEnvironment(
  'COUNSELOR_PORTAL_URL',
  defaultValue: 'http://localhost:4311/counselor',
);

bool openConsultantPortal() => false;
