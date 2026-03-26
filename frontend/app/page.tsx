import { profile } from "@/media/me/aboutme";

export default function Home() {
  const profilePictureUrl = process.env.NEXT_PUBLIC_PROFILE_PICTURE_URL?.trim();

  return (
    <div className="space-y-8">
      <div className="space-y-4">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
          {profilePictureUrl ? (
            <img
              src={profilePictureUrl}
              alt={`${profile.name}`}
              className="h-16 w-16 shrink-0 rounded-xl object-cover shadow-sm ring-1 ring-gray-200/80 sm:h-20 sm:w-20"
            />
          ) : null}
          <div className="min-w-0 flex-1">
            <h1 className="text-4xl font-bold tracking-tight">{profile.name}</h1>
            <p className="mt-2 text-lg text-gray-500">{profile.title}</p>
          </div>
        </div>
        <p className="max-w-3xl text-sm leading-7 text-gray-600">{profile.description}</p>
      </div>

      <div className="space-y-3">
        <h2 className="text-sm font-semibold uppercase tracking-wider text-gray-400">
          Contact
        </h2>
        <ul className="flex items-center gap-4 text-sm">
          <li>
            <a
              href={profile.contact.email}
              aria-label="Email"
              className="text-gray-600 hover:text-gray-900"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.8"
                className="h-5 w-5"
              >
                <path d="M4 6h16v12H4z" />
                <path d="m4 7 8 6 8-6" />
              </svg>
            </a>
          </li>
          <li>
            <a
              href={profile.contact.github}
              target="_blank"
              rel="noopener noreferrer"
              aria-label="GitHub"
              className="text-gray-600 hover:text-gray-900"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                className="h-5 w-5"
              >
                <path d="M12 .5a12 12 0 0 0-3.79 23.39c.6.11.82-.26.82-.58v-2.23c-3.34.72-4.04-1.42-4.04-1.42-.55-1.38-1.33-1.75-1.33-1.75-1.09-.75.08-.74.08-.74 1.21.08 1.85 1.22 1.85 1.22 1.07 1.82 2.8 1.3 3.49 1 .11-.77.42-1.3.76-1.59-2.67-.3-5.47-1.32-5.47-5.9 0-1.3.47-2.37 1.24-3.2-.12-.3-.54-1.52.12-3.17 0 0 1.01-.32 3.3 1.22a11.6 11.6 0 0 1 6 0c2.28-1.54 3.29-1.22 3.29-1.22.66 1.65.24 2.87.12 3.17.77.83 1.24 1.9 1.24 3.2 0 4.6-2.8 5.59-5.48 5.89.43.37.81 1.1.81 2.22v3.29c0 .32.21.7.82.58A12 12 0 0 0 12 .5Z" />
              </svg>
            </a>
          </li>
          <li>
            <a
              href={profile.contact.linkedin}
              target="_blank"
              rel="noopener noreferrer"
              aria-label="LinkedIn"
              className="text-gray-600 hover:text-gray-900"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                className="h-5 w-5"
              >
                <path d="M20.45 20.45h-3.56v-5.58c0-1.33-.03-3.05-1.86-3.05-1.87 0-2.16 1.46-2.16 2.95v5.68H9.3V9h3.42v1.56h.05c.47-.9 1.64-1.86 3.39-1.86 3.62 0 4.29 2.38 4.29 5.47v6.28ZM5.34 7.44a2.07 2.07 0 1 1 0-4.14 2.07 2.07 0 0 1 0 4.14ZM7.12 20.45H3.56V9h3.56v11.45Z" />
              </svg>
            </a>
          </li>
        </ul>
      </div>
    </div>
  );
}
