"use client";

import { useAuth0 } from "@auth0/auth0-react";
import { useEffect } from "react";

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

export default function ProtectedAuthContent() {
  const { isAuthenticated, isLoading, user, loginWithRedirect, logout } = useAuth0();

  useEffect(() => {
    if (isLoading) return;
    const loggedIn = isAuthenticated ? "true" : "false";
    localStorage.setItem("auth0_logged_in", loggedIn);
    window.dispatchEvent(new Event("auth-changed"));
  }, [isAuthenticated, isLoading]);

  if (isLoading) {
    return <p className="text-sm text-gray-500">Checking authentication...</p>;
  }

  if (!isAuthenticated) {
    return (
      <div className="mx-auto max-w-md space-y-8">
        <div className="text-center">
          <h1 className="text-2xl font-bold tracking-tight text-gray-900">
            Protected
          </h1>
          <p className="mt-2 text-sm text-gray-500">
            Sign in with Google or GitHub to continue.
          </p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-gray-50/80 p-6 shadow-sm">
          <p className="mb-4 text-center text-xs font-medium uppercase tracking-wider text-gray-400">
            Continue with
          </p>
          <div className="flex flex-col gap-3">
            <button
              type="button"
              onClick={() =>
                loginWithRedirect({
                  authorizationParams: { connection: "google-oauth2" },
                })
              }
              className="inline-flex w-full items-center justify-center gap-3 rounded-lg border border-gray-200 bg-white px-4 py-3 text-sm font-medium text-gray-800 shadow-sm transition hover:bg-gray-50 hover:shadow"
              aria-label="Sign in with Google"
            >
              <GoogleIcon className="h-5 w-5 shrink-0" />
              Sign in with Google
            </button>
            <button
              type="button"
              onClick={() =>
                loginWithRedirect({
                  authorizationParams: { connection: "github" },
                })
              }
              className="inline-flex w-full items-center justify-center gap-3 rounded-lg border border-gray-800 bg-gray-900 px-4 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-gray-800"
              aria-label="Sign in with GitHub"
            >
              <GitHubIcon className="h-5 w-5 shrink-0 text-white" />
              Sign in with GitHub
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
          localStorage.setItem("auth0_logged_in", "false");
          window.dispatchEvent(new Event("auth-changed"));
          logout({ logoutParams: { returnTo: `${window.location.origin}/protected/` } });
        }}
        className="rounded-md border border-gray-300 px-4 py-2 text-sm hover:bg-gray-50"
      >
        Log out
      </button>
    </div>
  );
}
