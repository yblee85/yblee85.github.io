"use client";

import { getApiBaseUrl } from "@/lib/api";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type PropsWithChildren,
} from "react";

export type SessionUser = {
  sub?: string;
  name?: string;
  email?: string;
  picture?: string;
  roles?: string[];
};

type AuthRefreshResult = { csrfToken: string | null };

type AuthContextValue = {
  loading: boolean;
  authenticated: boolean;
  user: SessionUser | null;
  /** Synchronizer token for mutating API requests (X-CSRF-Token). Null when logged out. */
  csrfToken: string | null;
  /** Returns the CSRF token from the same `/auth/me` response used to refresh state (avoids stale closure after await). */
  refresh: () => Promise<AuthRefreshResult>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return ctx;
}

function setNavSessionFlag(authenticated: boolean) {
  if (typeof window === "undefined") return;
  localStorage.setItem("auth_session_logged_in", authenticated ? "true" : "false");
  window.dispatchEvent(new Event("auth-changed"));
}

export default function AuthProvider({ children }: PropsWithChildren) {
  const [loading, setLoading] = useState(true);
  const [authenticated, setAuthenticated] = useState(false);
  const [user, setUser] = useState<SessionUser | null>(null);
  const [csrfToken, setCsrfToken] = useState<string | null>(null);

  const refresh = useCallback(async (): Promise<AuthRefreshResult> => {
    const base = getApiBaseUrl();
    if (!base) {
      setAuthenticated(false);
      setUser(null);
      setCsrfToken(null);
      setLoading(false);
      setNavSessionFlag(false);
      return { csrfToken: null };
    }

    try {
      const res = await fetch(`${base}/auth/me`, { credentials: "include" });
      const body = (await res.json()) as {
        authenticated?: boolean;
        user?: SessionUser;
        csrf_token?: string;
        data?: {
          authenticated?: boolean;
          user?: SessionUser;
          csrf_token?: string;
        };
      };
      const normalized = body.data ?? body;

      if (res.ok && normalized.authenticated && normalized.user) {
        setAuthenticated(true);
        setUser(normalized.user);
        const tok =
          typeof normalized.csrf_token === "string" && normalized.csrf_token.length > 0
            ? normalized.csrf_token
            : null;
        setCsrfToken(tok);
        setNavSessionFlag(true);
        return { csrfToken: tok };
      }

      setAuthenticated(false);
      setUser(null);
      setCsrfToken(null);
      setNavSessionFlag(false);
      return { csrfToken: null };
    } catch {
      setAuthenticated(false);
      setUser(null);
      setCsrfToken(null);
      setNavSessionFlag(false);
      return { csrfToken: null };
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const value = useMemo(
    () => ({ loading, authenticated, user, csrfToken, refresh }),
    [loading, authenticated, user, csrfToken, refresh],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
