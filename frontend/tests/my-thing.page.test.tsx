import { render, screen } from "@testing-library/react";
import PersonalPage from "@/app/personal/page";
import { personalExperience, personalProjects } from "@/media/me/aboutme";

describe("Personal page", () => {
  it("renders side project and personal experience entries", () => {
    render(<PersonalPage />);

    expect(screen.getByRole("heading", { name: "Personal" })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: personalProjects[0].name })).toBeInTheDocument();
    expect(screen.getByRole("heading", { name: personalProjects[1].name })).toBeInTheDocument();
    expect(screen.getByAltText(personalProjects[0].media![0].description!)).toBeInTheDocument();
    expect(screen.getByText(personalExperience[0].company)).toBeInTheDocument();
    expect(screen.getByText(personalExperience[1].company)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Related article" })).toHaveAttribute(
      "href",
      personalExperience[1].link,
    );
  });
});
