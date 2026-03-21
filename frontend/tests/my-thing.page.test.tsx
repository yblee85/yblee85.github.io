import { render, screen } from "@testing-library/react";
import MyThingPage from "@/app/my-thing/page";
import { personalExperience } from "@/media/me/aboutme";

describe("MyThing page", () => {
  it("renders personal experience entries", () => {
    render(<MyThingPage />);

    expect(screen.getByRole("heading", { name: "MyThing" })).toBeInTheDocument();
    expect(screen.getByText(personalExperience[0].company)).toBeInTheDocument();
    expect(screen.getByText(personalExperience[1].company)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Related article" })).toHaveAttribute(
      "href",
      personalExperience[1].link,
    );
  });
});
