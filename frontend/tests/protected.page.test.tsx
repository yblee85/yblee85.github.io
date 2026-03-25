import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen } from "@testing-library/react";

vi.mock("@/components/ProtectedAuthContent", () => ({
  default: () => <div data-testid="protected-auth-mock">Auth content mock</div>,
}));

describe("Protected page", () => {
  beforeEach(() => {
    vi.resetModules();
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("shows setup instructions when NEXT_PUBLIC_API_URL is missing", async () => {
    vi.stubEnv("NEXT_PUBLIC_API_URL", "");

    const { default: ProtectedPage } = await import("@/app/protected/page");
    render(<ProtectedPage />);

    expect(screen.getByRole("heading", { name: "Protected" })).toBeInTheDocument();
    expect(screen.getByText(/NEXT_PUBLIC_API_URL/)).toBeInTheDocument();
    expect(screen.queryByTestId("protected-auth-mock")).not.toBeInTheDocument();
  });

  it("renders ProtectedAuthContent when NEXT_PUBLIC_API_URL is set", async () => {
    vi.stubEnv("NEXT_PUBLIC_API_URL", "https://api.example.com");

    const { default: ProtectedPage } = await import("@/app/protected/page");
    render(<ProtectedPage />);

    expect(screen.getByTestId("protected-auth-mock")).toBeInTheDocument();
  });
});
