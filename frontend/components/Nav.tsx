"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const tabs = [
  { label: "Home", href: "/" },
  { label: "Career", href: "/career" },
  { label: "MyThing", href: "/my-thing" },
];

export default function Nav() {
  const pathname = usePathname();
  return (
    <nav className="border-b border-gray-200">
      <div className="max-w-4xl mx-auto px-6 flex gap-8">
        {tabs.map(({ label, href }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={`py-4 text-sm font-medium border-b-2 -mb-px transition-colors ${
                active
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
