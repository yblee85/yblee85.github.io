"use client";

import { useAuth } from "@/components/AuthProvider";
import { getApiBaseUrl } from "@/lib/api";
import Link from "next/link";
import { useState } from "react";

function isAdminUser(user: { roles?: string[] } | null): boolean {
  return Boolean(user?.roles?.includes("admin"));
}

export default function AdminContent() {
  const { loading, authenticated, user, refresh } = useAuth();
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const base = getApiBaseUrl();

  const runReindex = async () => {
    if (!base) {
      setError("API URL is not configured.");
      return;
    }
    setBusy(true);
    setMessage(null);
    setError(null);
    try {
      const { csrfToken: token } = await refresh();
      if (!token) {
        setError("Could not obtain security token. Try refreshing the page.");
        return;
      }

      const res = await fetch(`${base}/api/admin/reindex_db`, {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
        },
        body: "{}",
      });
      const body = (await res.json().catch(() => ({}))) as { ok?: boolean; error?: { message?: string } };
      if (!res.ok) {
        setError(body.error?.message || `Request failed (${res.status})`);
        return;
      }
      if (body.ok) {
        setMessage("Reindex completed successfully.");
      } else {
        setError("Unexpected response from server.");
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Request failed.");
    } finally {
      setBusy(false);
    }
  };

  if (!base) {
    return (
      <div className="space-y-2">
        <h1 className="text-2xl font-bold tracking-tight">Admin</h1>
        <p className="text-sm text-gray-600">
          Set <code className="rounded bg-gray-100 px-1">NEXT_PUBLIC_API_URL</code> to use admin tools.
        </p>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="text-sm text-gray-600" role="status">
        Loading…
      </div>
    );
  }

  if (!authenticated || !isAdminUser(user)) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold tracking-tight">Admin</h1>
        <p className="text-sm text-gray-600">You don’t have access to this page.</p>
        <Link href="/" className="text-sm font-medium text-indigo-600 hover:text-indigo-800">
          ← Back home
        </Link>
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-xl space-y-6">
      <header>
        <h1 className="text-2xl font-bold tracking-tight text-gray-900">Admin</h1>
        <p className="mt-2 text-sm text-gray-500">Maintenance actions for the portfolio agent backend.</p>
      </header>

      <div className="rounded-xl border border-gray-200 bg-gray-50/80 p-6 shadow-sm">
        <h2 className="text-sm font-semibold text-gray-900">Search index</h2>
        <p className="mt-1 text-sm text-gray-600">
          Reload documents from disk and rebuild in-memory embeddings (may take a minute).
        </p>
        <button
          type="button"
          onClick={() => void runReindex()}
          disabled={busy}
          className="mt-4 inline-flex items-center justify-center rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {busy ? "Reindexing…" : "Reindex db"}
        </button>
      </div>

      {message ? (
        <p className="text-sm text-green-700" role="status">
          {message}
        </p>
      ) : null}
      {error ? (
        <p className="text-sm text-red-600" role="alert">
          {error}
        </p>
      ) : null}
    </div>
  );
}
