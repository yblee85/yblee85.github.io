import { render, screen } from "@testing-library/react";
import PersonalPage from "@/app/personal/page";
import { personalExperience } from "@/media/me/aboutme";

describe("Personal page", () => {
  it("renders personal experience entries", () => {
    render(<PersonalPage />);

    expect(screen.getByRole("heading", { name: "Personal" })).toBeInTheDocument();
    expect(screen.getByText(personalExperience[0].company)).toBeInTheDocument();
    expect(screen.getByText(personalExperience[1].company)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Related article" })).toHaveAttribute(
      "href",
      personalExperience[1].link,
    );
  });
});
