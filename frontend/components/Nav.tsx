"use client";

import { useAuth } from "@/components/AuthProvider";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useMemo } from "react";

const baseTabs = [
  { label: "Home", href: "/" },
  { label: "Career", href: "/career" },
  { label: "MyThing", href: "/my-thing" },
] as const;

const chatTab = { label: "Chat with my agent", href: "/chat", emphasize: true as const };

export default function Nav() {
  const pathname = usePathname();
  const { user } = useAuth();

  const tabs = useMemo(() => {
    const isAdmin = Boolean(user?.roles?.includes("admin"));
    return [
      ...baseTabs.map((t) => ({ ...t })),
      ...(isAdmin ? [{ label: "Admin", href: "/admin" as const }] : []),
      chatTab,
    ];
  }, [user?.roles]);

  return (
    <nav className="border-b border-gray-200">
      <div className="max-w-4xl mx-auto px-6 flex gap-8">
        {tabs.map(({ label, href, emphasize }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={`py-4 text-sm font-medium border-b-2 -mb-px transition-colors ${
                emphasize
                  ? active
                    ? "border-indigo-600 text-indigo-700"
                    : "border-transparent text-indigo-600 hover:text-indigo-700 hover:border-indigo-300"
                  : active
                    ? "border-gray-900 text-gray-900"
                    : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              }`}
            >
              {label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
