import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import AdminContent from "@/components/AdminContent";

vi.mock("@/lib/api", () => ({
  getApiBaseUrl: vi.fn(() => "http://localhost:3001"),
}));

const mockUseAuth = vi.fn(() => ({
  loading: false,
  authenticated: true,
  user: { name: "Admin", roles: ["admin"] },
  csrfToken: "mock-csrf-token",
  refresh: vi.fn().mockResolvedValue({ csrfToken: "mock-csrf-token" }),
}));

vi.mock("@/components/AuthProvider", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/components/AuthProvider")>();
  return {
    ...actual,
    useAuth: () => mockUseAuth(),
  };
});

describe("AdminContent", () => {
  beforeEach(() => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({ ok: true, data: {} }),
      }),
    );
    mockUseAuth.mockReturnValue({
      loading: false,
      authenticated: true,
      user: { name: "Admin", roles: ["admin"] },
      csrfToken: "mock-csrf-token",
      refresh: vi.fn().mockResolvedValue({ csrfToken: "mock-csrf-token" }),
    });
  });

  it("posts to reindex endpoint when Reindex db is clicked", async () => {
    render(<AdminContent />);

    fireEvent.click(screen.getByRole("button", { name: /reindex db/i }));

    await waitFor(() => {
      expect(global.fetch).toHaveBeenCalledWith(
        "http://localhost:3001/api/admin/reindex_db",
        expect.objectContaining({
          method: "POST",
          credentials: "include",
          headers: expect.objectContaining({
            "X-CSRF-Token": "mock-csrf-token",
          }),
        }),
      );
    });

    expect(await screen.findByText(/reindex completed successfully/i)).toBeInTheDocument();
  });
});
