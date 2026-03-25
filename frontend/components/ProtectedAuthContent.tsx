"use client";

import { useAuth } from "@/components/AuthProvider";
import { getApiBaseUrl } from "@/lib/api";

function GoogleIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" aria-hidden>
      <path
        fill="#4285F4"
        d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
      />
      <path
        fill="#34A853"
        d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
      />
      <path
        fill="#FBBC05"
        d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
      />
      <path
        fill="#EA4335"
        d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
      />
    </svg>
  );
}

function GitHubIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M12 .5a12 12 0 0 0-3.79 23.39c.6.11.82-.26.82-.58v-2.23c-3.34.72-4.04-1.42-4.04-1.42-.55-1.38-1.33-1.75-1.33-1.75-1.09-.75.08-.74.08-.74 1.21.08 1.85 1.22 1.85 1.22 1.07 1.82 2.8 1.3 3.49 1 .11-.77.42-1.3.76-1.59-2.67-.3-5.47-1.32-5.47-5.9 0-1.3.47-2.37 1.24-3.2-.12-.3-.54-1.52.12-3.17 0 0 1.01-.32 3.3 1.22a11.6 11.6 0 0 1 6 0c2.28-1.54 3.29-1.22 3.29-1.22.66 1.65.24 2.87.12 3.17.77.83 1.24 1.9 1.24 3.2 0 4.6-2.8 5.59-5.48 5.89.43.37.81 1.1.81 2.22v3.29c0 .32.21.7.82.58A12 12 0 0 0 12 .5Z" />
    </svg>
  );
}

function LinkedInIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 24 24" fill="currentColor" aria-hidden>
      <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
    </svg>
  );
}

function loginUrl(connection: string): string | null {
  const base = getApiBaseUrl();
  if (!base || typeof window === "undefined") return null;
  const u = new URL(`${base}/auth/login`);
  u.searchParams.set("connection", connection);
  u.searchParams.set("return_to", window.location.href);
  return u.toString();
}

function logoutUrl(): string | null {
  const base = getApiBaseUrl();
  if (!base || typeof window === "undefined") return null;
  const u = new URL(`${base}/auth/logout`);
  u.searchParams.set("return_to", `${window.location.origin}/protected`);
  return u.toString();
}

export default function ProtectedAuthContent() {
  const { loading, authenticated, user } = useAuth();
  const base = getApiBaseUrl();

  if (!base) {
    return (
      <p className="text-sm text-gray-600">
        Set <code className="rounded bg-gray-100 px-1">NEXT_PUBLIC_API_URL</code> to your API origin
        (e.g. <code className="rounded bg-gray-100 px-1">https://api.example.com</code>).
      </p>
    );
  }

  if (loading) {
    return <p className="text-sm text-gray-500">Checking authentication...</p>;
  }

  if (!authenticated) {
    return (
      <div className="mx-auto max-w-md space-y-8">
        <div className="text-center">
          <h1 className="text-2xl font-bold tracking-tight text-gray-900">Protected</h1>
          <p className="mt-2 text-sm text-gray-500">
            Sign in with Google, GitHub, or LinkedIn to continue.
          </p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-gray-50/80 p-6 shadow-sm">
          <p className="mb-4 text-center text-xs font-medium uppercase tracking-wider text-gray-400">
            Continue with
          </p>
          <div className="flex flex-col gap-3">
            <button
              type="button"
              onClick={() => {
                const url = loginUrl("google-oauth2");
                if (url) window.location.assign(url);
              }}
              className="inline-flex w-full cursor-pointer items-center justify-center gap-3 rounded-lg border border-gray-200 bg-white px-4 py-3 text-sm font-medium text-gray-800 shadow-sm transition hover:bg-gray-50 hover:shadow"
              aria-label="Sign in with Google"
            >
              <GoogleIcon className="h-5 w-5 shrink-0" />
              Sign in with Google
            </button>
            <button
              type="button"
              onClick={() => {
                const url = loginUrl("github");
                if (url) window.location.assign(url);
              }}
              className="inline-flex w-full cursor-pointer items-center justify-center gap-3 rounded-lg border border-gray-800 bg-gray-900 px-4 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-gray-800"
              aria-label="Sign in with GitHub"
            >
              <GitHubIcon className="h-5 w-5 shrink-0 text-white" />
              Sign in with GitHub
            </button>
            <button
              type="button"
              onClick={() => {
                const url = loginUrl("linkedin");
                if (url) window.location.assign(url);
              }}
              className="inline-flex w-full cursor-pointer items-center justify-center gap-3 rounded-lg border border-[#0A66C2] bg-[#0A66C2] px-4 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-[#004182]"
              aria-label="Sign in with LinkedIn"
            >
              <LinkedInIcon className="h-5 w-5 shrink-0 text-white" />
              Sign in with LinkedIn
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold tracking-tight">Protected</h1>
      <p className="text-sm text-gray-600">You have logged in</p>
      {user?.name ? <p className="text-sm text-gray-500">Signed in as {user.name}</p> : null}
      <button
        type="button"
        onClick={() => {
          const url = logoutUrl();
          if (url) window.location.assign(url);
        }}
        className="rounded-md border border-gray-300 px-4 py-2 text-sm hover:bg-gray-50"
      >
        Log out
      </button>
    </div>
  );
}
