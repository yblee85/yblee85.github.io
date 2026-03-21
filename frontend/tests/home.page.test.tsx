import { render, screen } from "@testing-library/react";
import Home from "@/app/page";
import { profile } from "@/media/me/aboutme";

describe("Home page", () => {
  it("renders profile and contact links", () => {
    render(<Home />);

    expect(screen.getByRole("heading", { name: profile.name })).toBeInTheDocument();
    expect(screen.getByText(profile.title)).toBeInTheDocument();
    expect(screen.getByText(profile.description)).toBeInTheDocument();

    expect(screen.getByRole("link", { name: "Email" })).toHaveAttribute(
      "href",
      profile.contact.email,
    );
    expect(screen.getByRole("link", { name: "GitHub" })).toHaveAttribute(
      "href",
      profile.contact.github,
    );
    expect(screen.getByRole("link", { name: "LinkedIn" })).toHaveAttribute(
      "href",
      profile.contact.linkedin,
    );
  });
});
