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

type AuthContextValue = {
  loading: boolean;
  authenticated: boolean;
  user: SessionUser | null;
  refresh: () => Promise<void>;
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

  const refresh = useCallback(async () => {
    const base = getApiBaseUrl();
    if (!base) {
      setAuthenticated(false);
      setUser(null);
      setLoading(false);
      setNavSessionFlag(false);
      return;
    }

    try {
      const res = await fetch(`${base}/auth/me`, { credentials: "include" });
      const body = (await res.json()) as {
        authenticated?: boolean;
        user?: SessionUser;
        data?: {
          authenticated?: boolean;
          user?: SessionUser;
        };
      };
      const normalized = body.data ?? body;

      if (res.ok && normalized.authenticated && normalized.user) {
        setAuthenticated(true);
        setUser(normalized.user);
        setNavSessionFlag(true);
      } else {
        setAuthenticated(false);
        setUser(null);
        setNavSessionFlag(false);
      }
    } catch {
      setAuthenticated(false);
      setUser(null);
      setNavSessionFlag(false);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  const value = useMemo(
    () => ({ loading, authenticated, user, refresh }),
    [loading, authenticated, user, refresh],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
