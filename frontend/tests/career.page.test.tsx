import { render, screen } from "@testing-library/react";
import Career from "@/app/career/page";
import { experience } from "@/media/me/aboutme";

describe("Career page", () => {
  it("renders key sections and work data", () => {
    render(<Career />);

    expect(screen.getByRole("heading", { name: "Career" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: "Experience" })).toBeInTheDocument();

    expect(screen.getByText(experience[0].company)).toBeInTheDocument();
    expect(screen.getByText(experience[0].bullets[0])).toBeInTheDocument();
  });
});
