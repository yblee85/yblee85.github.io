import type { Metadata } from "next";
import "./globals.css";
import Nav from "@/components/Nav";
import AuthProvider from "@/components/AuthProvider";

export const metadata: Metadata = {
  title: "Yunbo Lee",
  description: "Senior Software Engineer",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-white text-gray-900 antialiased">
        <AuthProvider>
          <Nav />
          <main className="max-w-4xl mx-auto px-6 py-10">{children}</main>
        </AuthProvider>
      </body>
    </html>
  );
}
