"use client";

import { useAuth } from "@/components/AuthProvider";
import { getApiBaseUrl } from "@/lib/api";
import { Open_Sans } from "next/font/google";
import { FormEvent, KeyboardEvent, useEffect, useMemo, useRef, useState } from "react";

const openSans = Open_Sans({ subsets: ["latin"] });

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
  u.searchParams.set("return_to", `${window.location.origin}/chat`);
  return u.toString();
}

function guestLoginUrl(): string | null {
  const base = getApiBaseUrl();
  if (!base || typeof window === "undefined") return null;
  const u = new URL(`${base}/auth/login`);
  u.searchParams.set("guest", "true");
  u.searchParams.set("return_to", window.location.href);
  return u.toString();
}

export default function ProtectedAuthContent() {
  const { loading, authenticated, user, refresh } = useAuth();
  const base = getApiBaseUrl();
  const [message, setMessage] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [chat, setChat] = useState<Array<{ role: "user" | "assistant"; content: string }>>([]);
  const bottomRef = useRef<HTMLDivElement | null>(null);
  const canSend = useMemo(() => !isSending && message.trim().length > 0, [isSending, message]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ block: "end" });
  }, [chat.length]);

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
      <div className="mx-auto w-full max-w-xl space-y-8">
        <header className="text-left">
          <h1 className="text-2xl font-bold tracking-tight text-gray-900">Chat with my agent</h1>
          <p className="mt-2 text-sm text-gray-500">
            Ask me anything about my career history.
          </p>
        </header>

        <div className={`text-left text-[18px] leading-8 text-gray-700 ${openSans.className}`}>
          <p className="font-medium text-gray-900">
            Hi there, you&apos;re about to chat with my agent about my career history.
          </p>
        </div>

        <div className="w-full rounded-xl border border-gray-200 bg-gray-50/80 p-6 shadow-sm">
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
              aria-label="Continue with Google"
            >
              <GoogleIcon className="h-5 w-5 shrink-0" />
              Continue with Google
            </button>
            <button
              type="button"
              onClick={() => {
                const url = loginUrl("github");
                if (url) window.location.assign(url);
              }}
              className="inline-flex w-full cursor-pointer items-center justify-center gap-3 rounded-lg border border-gray-800 bg-gray-900 px-4 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-gray-800"
              aria-label="Continue with GitHub"
            >
              <GitHubIcon className="h-5 w-5 shrink-0 text-white" />
              Continue with GitHub
            </button>
            <button
              type="button"
              onClick={() => {
                const url = loginUrl("linkedin");
                if (url) window.location.assign(url);
              }}
              className="inline-flex w-full cursor-pointer items-center justify-center gap-3 rounded-lg border border-[#0A66C2] bg-[#0A66C2] px-4 py-3 text-sm font-medium text-white shadow-sm transition hover:bg-[#004182]"
              aria-label="Continue with LinkedIn"
            >
              <LinkedInIcon className="h-5 w-5 shrink-0 text-white" />
              Continue with LinkedIn
            </button>

            <div className="flex items-center gap-3 py-1">
              <div className="h-px flex-1 bg-gray-200" />
              <span className="text-[11px] font-medium uppercase tracking-wider text-gray-400">Or</span>
              <div className="h-px flex-1 bg-gray-200" />
            </div>

            <button
              type="button"
              onClick={() => {
                const url = guestLoginUrl();
                if (url) window.location.assign(url);
              }}
              className="inline-flex w-full cursor-pointer items-center justify-center rounded-lg border border-gray-200 bg-white px-4 py-3 text-sm font-medium text-gray-800 shadow-sm transition hover:bg-gray-50 hover:shadow"
              aria-label="Continue as guest"
            >
              Continue as guest
            </button>
          </div>
        </div>

        <div className="rounded-lg border border-gray-200 bg-white/70 px-4 py-3 text-sm leading-6 text-gray-600">
          <p className="font-medium text-gray-900">Your privacy comes first and is respected.</p>
          <p className="mt-1">
            I do not (nor will I) collect your personal information. It&apos;s anonymous and I do not know who you are.
          </p>
          <p className="mt-2">I made this sign-in page for the following reasons:</p>
          <ol className="mt-2 list-decimal space-y-1 pl-5">
            <li>To set rate limits to protect against service abuse and billing surprises.</li>
            <li>For fun/study of OAuth 2.0.</li>
          </ol>
        </div>
      </div>
    );
  }

  const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const text = message.trim();
    if (!text || !base || isSending) return;

    setError(null);
    setIsSending(true);
    setChat((prev) => [...prev, { role: "user", content: text }]);
    setMessage("");

    try {
      // Ensure session cookie is up-to-date before calling /api/chat.
      const { csrfToken: token } = await refresh();
      if (!token) {
        setChat((prev) => prev.slice(0, -1));
        setMessage(text);
        setError("Could not obtain security token. Try refreshing the page.");
        return;
      }

      const res = await fetch(`${base}/api/chat`, {
        method: "POST",
        credentials: "include",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
        },
        body: JSON.stringify({ message: text }),
      });
      const body = (await res.json().catch(() => ({}))) as {
        answer?: string;
        error?: string | { message?: string };
        data?: { answer?: string };
        ok?: boolean;
      };

      if (!res.ok) {
        const errorMessage =
          typeof body.error === "string" ? body.error : body.error?.message;
        throw new Error(errorMessage || "Failed to get response from backend");
      }
      setChat((prev) => [
        ...prev,
        { role: "assistant", content: body.data?.answer || body.answer || "No answer returned." },
      ]);
    } catch (e) {
      const messageText = e instanceof Error ? e.message : "Request failed";
      setError(messageText);
    } finally {
      setIsSending(false);
    }
  };

  const onMessageKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key !== "Enter") return;
    if (!event.ctrlKey && !event.metaKey) return;

    event.preventDefault();
    if (!canSend) return;
    void onSubmit(event as unknown as FormEvent<HTMLFormElement>);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Chat with my agent</h1>
          <p className="text-sm text-gray-600">Ask about my background and experience.</p>
          {user?.name ? <p className="text-xs text-gray-500">Signed in as {user.name}</p> : null}
        </div>
        <button
          type="button"
          onClick={() => {
            const url = logoutUrl();
            if (url) window.location.assign(url);
          }}
          className="rounded-md border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
        >
          Log out
        </button>
      </div>

      <div className="rounded-xl border border-indigo-100 bg-indigo-50/40 p-4">
        <div className="space-y-3 max-h-[420px] overflow-y-auto">
          {chat.length === 0 ? (
            <div className="space-y-1">
              <p className="text-sm text-gray-600">Start by asking a question below.</p>
              <p className="text-sm text-gray-500">
                Can you summarize his skills? What do his team members think of him?
              </p>
            </div>
          ) : (
            chat.map((item, index) => (
              <div
                key={`${item.role}-${index}`}
                className={`rounded-lg px-4 py-3 text-sm ${
                  item.role === "user"
                    ? "ml-6 bg-white border border-gray-200"
                    : "mr-6 bg-indigo-100 border border-indigo-200"
                }`}
              >
                <p className="mb-1 text-xs font-semibold uppercase tracking-wide text-gray-500">
                  {item.role === "user" ? "You" : "Agent"}
                </p>
                <p className="whitespace-pre-wrap text-gray-800">{item.content}</p>
              </div>
            ))
          )}
          <div ref={bottomRef} />
        </div>
      </div>

      <form onSubmit={onSubmit} className="space-y-3">
        <textarea
          value={message}
          onChange={(event) => setMessage(event.target.value)}
          onKeyDown={onMessageKeyDown}
          placeholder="Ask me anything..."
          rows={4}
          className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-100"
        />
        <div className="flex items-center justify-between gap-3">
          {error ? <p className="text-sm text-red-600">{error}</p> : <span />}
          <button
            type="submit"
            disabled={!canSend}
            className="rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-50 hover:bg-indigo-700"
          >
            {isSending ? "Sending..." : "Send"}
          </button>
        </div>
      </form>
    </div>
  );
}
