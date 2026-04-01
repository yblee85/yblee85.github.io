import type { Metadata } from "next";
import AdminContent from "@/components/AdminContent";

export const metadata: Metadata = {
  title: "Admin · Yunbo Lee",
  description: "Admin tools for the portfolio backend",
};

const apiConfigured = Boolean(process.env.NEXT_PUBLIC_API_URL?.trim());

export default function AdminPage() {
  if (!apiConfigured) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold tracking-tight">Admin</h1>
        <p className="text-sm text-gray-600">
          Set <code className="rounded bg-gray-100 px-1">NEXT_PUBLIC_API_URL</code> to your backend origin.
        </p>
      </div>
    );
  }

  return <AdminContent />;
}
