import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor, fireEvent } from "@testing-library/react";
import AuthProvider from "@/components/AuthProvider";
import ProtectedAuthContent from "@/components/ProtectedAuthContent";

function mockFetchMe(authenticated: boolean, user?: { name?: string; email?: string }) {
  global.fetch = vi.fn().mockResolvedValue({
    ok: authenticated,
    json: async () =>
      authenticated
        ? { authenticated: true, user: user ?? { name: "Test User", email: "test@example.com" } }
        : { authenticated: false },
  });
}

describe("ProtectedAuthContent", () => {
  beforeEach(() => {
    vi.stubEnv("NEXT_PUBLIC_API_URL", "https://api.example.com");
    localStorage.clear();
    mockFetchMe(false);
  });

  it("shows Google, GitHub, and LinkedIn sign-in when logged out", async () => {
    render(
      <AuthProvider>
        <ProtectedAuthContent />
      </AuthProvider>,
    );

    await waitFor(() => {
      expect(screen.queryByText("Checking authentication...")).not.toBeInTheDocument();
    });

    expect(screen.getByRole("button", { name: /sign in with google/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /sign in with github/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /sign in with linkedin/i })).toBeInTheDocument();
  });

  it("navigates to API login with google-oauth2 when Google is clicked", async () => {
    const assign = vi.fn();
    Object.defineProperty(window, "location", {
      value: { href: "https://site.example/protected", assign },
      writable: true,
      configurable: true,
    });

    render(
      <AuthProvider>
        <ProtectedAuthContent />
      </AuthProvider>,
    );

    await waitFor(() => {
      expect(screen.queryByText("Checking authentication...")).not.toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole("button", { name: /sign in with google/i }));

    expect(assign).toHaveBeenCalledTimes(1);
    const url = assign.mock.calls[0][0] as string;
    expect(url).toContain("/auth/login");
    expect(url).toContain("connection=google-oauth2");
  });

  it("navigates to API login with github when GitHub is clicked", async () => {
    const assign = vi.fn();
    Object.defineProperty(window, "location", {
      value: { href: "https://site.example/protected", assign },
      writable: true,
      configurable: true,
    });

    render(
      <AuthProvider>
        <ProtectedAuthContent />
      </AuthProvider>,
    );

    await waitFor(() => {
      expect(screen.queryByText("Checking authentication...")).not.toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole("button", { name: /sign in with github/i }));

    const url = assign.mock.calls[0][0] as string;
    expect(url).toContain("connection=github");
  });

  it("navigates to API login with linkedin when LinkedIn is clicked", async () => {
    const assign = vi.fn();
    Object.defineProperty(window, "location", {
      value: { href: "https://site.example/protected", assign },
      writable: true,
      configurable: true,
    });

    render(
      <AuthProvider>
        <ProtectedAuthContent />
      </AuthProvider>,
    );

    await waitFor(() => {
      expect(screen.queryByText("Checking authentication...")).not.toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole("button", { name: /sign in with linkedin/i }));

    const url = assign.mock.calls[0][0] as string;
    expect(url).toContain("connection=linkedin");
  });

  it("shows logged-in message when session is valid", async () => {
    mockFetchMe(true, { name: "Test User", email: "test@example.com" });

    render(
      <AuthProvider>
        <ProtectedAuthContent />
      </AuthProvider>,
    );

    await waitFor(() => {
      expect(screen.getByText("Ask about my background and experience.")).toBeInTheDocument();
    });
    expect(screen.getByText(/signed in as test user/i)).toBeInTheDocument();
  });

  it("sends message to backend chat API and renders response", async () => {
    global.fetch = vi
      .fn()
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          authenticated: true,
          user: { name: "Test User", email: "test@example.com" },
        }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          authenticated: true,
          user: { name: "Test User", email: "test@example.com" },
        }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ answer: "Hello from backend" }),
      });

    render(
      <AuthProvider>
        <ProtectedAuthContent />
      </AuthProvider>,
    );

    await waitFor(() => {
      expect(screen.getByPlaceholderText("Ask me anything...")).toBeInTheDocument();
    });

    fireEvent.change(screen.getByPlaceholderText("Ask me anything..."), {
      target: { value: "What did you work on?" },
    });
    fireEvent.click(screen.getByRole("button", { name: "Send" }));

    await waitFor(() => {
      expect(screen.getByText("What did you work on?")).toBeInTheDocument();
      expect(screen.getByText("Hello from backend")).toBeInTheDocument();
    });
  });
});
