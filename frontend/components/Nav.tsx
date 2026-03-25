"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

const tabs = [
  { label: "Home", href: "/" },
  { label: "Career", href: "/career" },
  { label: "MyThing", href: "/my-thing" },
  { label: "Protected", href: "/protected" },
];

export default function Nav() {
  const pathname = usePathname();
  const [showProtected, setShowProtected] = useState(false);

  useEffect(() => {
    const readAuth = () => {
      setShowProtected(localStorage.getItem("auth_session_logged_in") === "true");
    };

    readAuth();
    window.addEventListener("storage", readAuth);
    window.addEventListener("auth-changed", readAuth);
    return () => {
      window.removeEventListener("storage", readAuth);
      window.removeEventListener("auth-changed", readAuth);
    };
  }, []);

  const visibleTabs = tabs.filter((tab) =>
    tab.href === "/protected" ? showProtected : true,
  );

  return (
    <nav className="border-b border-gray-200">
      <div className="max-w-4xl mx-auto px-6 flex gap-8">
        {visibleTabs.map(({ label, href }) => {
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
