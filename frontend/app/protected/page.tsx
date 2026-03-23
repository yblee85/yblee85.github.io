import type { Metadata } from "next";
import ProtectedAuthContent from "@/components/ProtectedAuthContent";

export const metadata: Metadata = {
  title: "Protected · Yunbo Lee",
  description: "Auth0 protected page",
};

const authConfigured =
  Boolean(process.env.NEXT_PUBLIC_AUTH0_DOMAIN) &&
  Boolean(process.env.NEXT_PUBLIC_AUTH0_CLIENT_ID);

export default function ProtectedPage() {
  if (!authConfigured) {
    return (
      <div className="space-y-4">
        <h1 className="text-2xl font-bold tracking-tight">Protected</h1>
        <p className="text-sm text-gray-600">
          Auth0 is not configured yet. Set `NEXT_PUBLIC_AUTH0_DOMAIN` and
          `NEXT_PUBLIC_AUTH0_CLIENT_ID` to enable login.
        </p>
      </div>
    );
  }

  return <ProtectedAuthContent />;
}
