import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import Nav from "@/components/Nav";

vi.mock("next/navigation", () => ({
  usePathname: vi.fn(() => "/"),
}));

const mockUseAuth = vi.fn(() => ({
  loading: false,
  authenticated: false,
  user: null as { roles?: string[] } | null,
  csrfToken: null,
  refresh: vi.fn().mockResolvedValue({ csrfToken: null }),
}));

vi.mock("@/components/AuthProvider", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/components/AuthProvider")>();
  return {
    ...actual,
    useAuth: () => mockUseAuth(),
  };
});

describe("Nav", () => {
  beforeEach(() => {
    mockUseAuth.mockReturnValue({
      loading: false,
      authenticated: false,
      user: null,
      csrfToken: null,
      refresh: vi.fn().mockResolvedValue({ csrfToken: null }),
    });
  });

  it("shows Chat with my agent tab", () => {
    render(<Nav />);
    expect(screen.getByRole("link", { name: "Chat with my agent" })).toBeInTheDocument();
  });

  it("chat tab links to /chat", async () => {
    render(<Nav />);
    expect(screen.getByRole("link", { name: "Chat with my agent" })).toHaveAttribute("href", "/chat");
  });

  it("shows Home, Career, and Personal links", () => {
    render(<Nav />);
    expect(screen.getByRole("link", { name: "Home" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Career" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Personal" })).toBeInTheDocument();
  });

  it("does not show Admin tab when user is not admin", () => {
    render(<Nav />);
    expect(screen.queryByRole("link", { name: "Admin" })).not.toBeInTheDocument();
  });

  it("shows Admin tab when user has admin role", () => {
    mockUseAuth.mockReturnValue({
      loading: false,
      authenticated: true,
      user: { name: "A", roles: ["admin"] },
      csrfToken: null,
      refresh: vi.fn().mockResolvedValue({ csrfToken: null }),
    });
    render(<Nav />);
    expect(screen.getByRole("link", { name: "Admin" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Admin" })).toHaveAttribute("href", "/admin");
  });
});
