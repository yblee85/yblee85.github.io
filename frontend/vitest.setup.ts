import "@testing-library/jest-dom/vitest";
import { vi } from "vitest";

// next/font/google loaders are transformed by Next.js at build time.
// In Vitest (plain Vite), mock them as callable loaders returning className.
vi.mock("next/font/google", () => {
  const loader = () => ({ className: "mock-next-font" });
  return {
    Schoolbell: loader,
  };
});

if (!Element.prototype.scrollIntoView) {
  Element.prototype.scrollIntoView = vi.fn();
}
