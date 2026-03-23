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

  it("shows setup instructions when Auth0 env vars are missing", async () => {
    vi.stubEnv("NEXT_PUBLIC_AUTH0_DOMAIN", "");
    vi.stubEnv("NEXT_PUBLIC_AUTH0_CLIENT_ID", "");

    const { default: ProtectedPage } = await import("@/app/protected/page");
    render(<ProtectedPage />);

    expect(screen.getByRole("heading", { name: "Protected" })).toBeInTheDocument();
    expect(screen.getByText(/Auth0 is not configured yet/)).toBeInTheDocument();
    expect(screen.queryByTestId("protected-auth-mock")).not.toBeInTheDocument();
  });

  it("renders ProtectedAuthContent when Auth0 env vars are set", async () => {
    vi.stubEnv("NEXT_PUBLIC_AUTH0_DOMAIN", "dev-example.us.auth0.com");
    vi.stubEnv("NEXT_PUBLIC_AUTH0_CLIENT_ID", "test_client_id");

    const { default: ProtectedPage } = await import("@/app/protected/page");
    render(<ProtectedPage />);

    expect(screen.getByTestId("protected-auth-mock")).toBeInTheDocument();
  });
});
