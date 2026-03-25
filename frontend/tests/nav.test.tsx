import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import Nav from "@/components/Nav";

vi.mock("next/navigation", () => ({
  usePathname: vi.fn(() => "/"),
}));

describe("Nav", () => {
  it("shows Chat with my agent tab", () => {
    render(<Nav />);
    expect(screen.getByRole("link", { name: "Chat with my agent" })).toBeInTheDocument();
  });

  it("chat tab links to /chat", async () => {
    render(<Nav />);
    expect(screen.getByRole("link", { name: "Chat with my agent" })).toHaveAttribute(
      "href",
      "/chat",
    );
  });

  it("shows Home, Career, and MyThing links", () => {
    render(<Nav />);
    expect(screen.getByRole("link", { name: "Home" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Career" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "MyThing" })).toBeInTheDocument();
  });
});
