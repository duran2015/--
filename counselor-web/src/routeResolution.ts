export type AppRoute = "client" | "counselor";

const CLIENT_PATH = /^\/client(?:\/|$)/;
const COUNSELOR_PATH = /^\/counselor(?:\/|$)/;

export function isKnownAppPath(pathname: string): boolean {
  return CLIENT_PATH.test(pathname) || COUNSELOR_PATH.test(pathname);
}

export function resolveAppRoute(pathname: string): AppRoute {
  return CLIENT_PATH.test(pathname) ? "client" : "counselor";
}
