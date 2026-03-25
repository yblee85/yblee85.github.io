import type { Metadata } from "next";
import ProtectedAuthContent from "@/components/ProtectedAuthContent";

export const metadata: Metadata = {
  title: "Chat with my agent · Yunbo Lee",
  description: "OAuth-protected chat powered by backend /api/chat",
};

const apiConfigured = Boolean(process.env.NEXT_PUBLIC_API_URL?.trim());

export default function ChatPage() {
  if (!apiConfigured) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold tracking-tight">Chat with my agent</h1>
        <p className="text-sm text-gray-600">
          Set <code className="rounded bg-gray-100 px-1">NEXT_PUBLIC_API_URL</code> to your backend
          origin so the browser can use session cookies with{" "}
          <code className="rounded bg-gray-100 px-1">/auth/me</code> and
          <code className="ml-1 rounded bg-gray-100 px-1">/api/chat</code>.
        </p>
      </div>
    );
  }

  return <ProtectedAuthContent />;
}
