const AUTH_KEY = 'admin_token';

export function getAuthToken(): string | null {
  return sessionStorage.getItem(AUTH_KEY);
}

export function setAuthToken(token: string): void {
  sessionStorage.setItem(AUTH_KEY, token);
}

export function clearAuthToken(): void {
  sessionStorage.removeItem(AUTH_KEY);
}

export function isAuthenticated(): boolean {
  return Boolean(getAuthToken());
}
