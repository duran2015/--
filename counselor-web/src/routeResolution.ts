const COUNSELOR_PATH = /^\/counselor(?:\/|$)/;

export function isKnownAppPath(pathname: string): boolean {
  return COUNSELOR_PATH.test(pathname);
}
