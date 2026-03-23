"use client";

import { Auth0Provider } from "@auth0/auth0-react";
import type { PropsWithChildren } from "react";

const domain = process.env.NEXT_PUBLIC_AUTH0_DOMAIN;
const clientId = process.env.NEXT_PUBLIC_AUTH0_CLIENT_ID;

export default function AuthProvider({ children }: PropsWithChildren) {
  // Keep local/dev builds working even when Auth0 env vars are not set.
  if (!domain || !clientId) {
    return <>{children}</>;
  }

  return (
    <Auth0Provider
      domain={domain}
      clientId={clientId}
      authorizationParams={{
        redirect_uri:
          typeof window !== "undefined"
            ? `${window.location.origin}/protected/`
            : undefined,
      }}
      cacheLocation="localstorage"
      useRefreshTokens
    >
      {children}
    </Auth0Provider>
  );
}
