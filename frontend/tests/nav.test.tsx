import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import Nav from "@/components/Nav";

vi.mock("next/navigation", () => ({
  usePathname: vi.fn(() => "/"),
}));

describe("Nav", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("does not show Protected tab when auth flag is absent", () => {
    render(<Nav />);
    expect(screen.queryByRole("link", { name: "Protected" })).not.toBeInTheDocument();
  });

  it("shows Protected tab when auth_session_logged_in is true", async () => {
    localStorage.setItem("auth_session_logged_in", "true");
    render(<Nav />);

    await waitFor(() => {
      expect(screen.getByRole("link", { name: "Protected" })).toBeInTheDocument();
    });
    expect(screen.getByRole("link", { name: "Protected" })).toHaveAttribute("href", "/protected");
  });

  it("shows Home, Career, and MyThing links", () => {
    render(<Nav />);
    expect(screen.getByRole("link", { name: "Home" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Career" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "MyThing" })).toBeInTheDocument();
  });
});
