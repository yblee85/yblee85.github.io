import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import ProtectedAuthContent from "@/components/ProtectedAuthContent";

const mockLoginWithRedirect = vi.fn();
const mockLogout = vi.fn();

vi.mock("@auth0/auth0-react", () => ({
  useAuth0: vi.fn(),
}));

import { useAuth0 } from "@auth0/auth0-react";

const mockedUseAuth0 = vi.mocked(useAuth0);

function mockAuthState(overrides: Partial<ReturnType<typeof useAuth0>>) {
  mockedUseAuth0.mockReturnValue({
    isAuthenticated: false,
    isLoading: false,
    user: undefined,
    loginWithRedirect: mockLoginWithRedirect,
    logout: mockLogout,
    getAccessTokenSilently: vi.fn(),
    getAccessTokenWithPopup: vi.fn(),
    getIdTokenClaims: vi.fn(),
    loginWithPopup: vi.fn(),
    handleRedirectCallback: vi.fn(),
    ...overrides,
  } as never);
}

describe("ProtectedAuthContent", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
    mockAuthState({});
  });

  it("shows Google, GitHub, and LinkedIn sign-in when logged out", () => {
    render(<ProtectedAuthContent />);

    expect(screen.getByRole("button", { name: /sign in with google/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /sign in with github/i })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /sign in with linkedin/i })).toBeInTheDocument();
  });

  it("calls loginWithRedirect with google-oauth2 when Google is clicked", () => {
    render(<ProtectedAuthContent />);

    fireEvent.click(screen.getByRole("button", { name: /sign in with google/i }));

    expect(mockLoginWithRedirect).toHaveBeenCalledWith({
      authorizationParams: { connection: "google-oauth2" },
    });
  });

  it("calls loginWithRedirect with github when GitHub is clicked", () => {
    render(<ProtectedAuthContent />);

    fireEvent.click(screen.getByRole("button", { name: /sign in with github/i }));

    expect(mockLoginWithRedirect).toHaveBeenCalledWith({
      authorizationParams: { connection: "github" },
    });
  });

  it("calls loginWithRedirect with linkedin when LinkedIn is clicked", () => {
    render(<ProtectedAuthContent />);

    fireEvent.click(screen.getByRole("button", { name: /sign in with linkedin/i }));

    expect(mockLoginWithRedirect).toHaveBeenCalledWith({
      authorizationParams: { connection: "linkedin" },
    });
  });

  it("shows logged-in message when authenticated", () => {
    mockAuthState({
      isAuthenticated: true,
      user: { name: "Test User", email: "test@example.com" },
    });

    render(<ProtectedAuthContent />);

    expect(screen.getByText("You have logged in")).toBeInTheDocument();
    expect(screen.getByText(/signed in as test user/i)).toBeInTheDocument();
  });
});
