import MediaCarousel from "@/components/MediaCarousel";
import { personalExperience, personalProjects } from "@/media/me/aboutme";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Personal · Yunbo Lee",
  description:
    "Side projects, certifications, and community work — including this portfolio site and AI career agent.",
};

export default function PersonalPage() {
  return (
    <div className="space-y-12">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Personal</h1>
        <p className="mt-2 text-sm text-gray-500">
          Side projects, certifications, and community outside day-to-day work.
        </p>
      </div>

      <section className="space-y-6">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-gray-400">
          Side projects
        </h2>
        {personalProjects.map((project) => (
          <article
            key={project.name}
            className="rounded-xl border border-gray-200 bg-gray-50/60 p-6 shadow-sm"
          >
            <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">{project.name}</h3>
                <p className="mt-0.5 text-sm text-gray-600">{project.role}</p>
              </div>
              <span className="text-xs text-gray-400 whitespace-nowrap">{project.period}</span>
            </div>

            <p className="mt-4 text-sm leading-7 text-gray-700">{project.summary}</p>

            <ul className="mt-4 space-y-2 text-sm text-gray-600 list-disc list-inside">
              {project.bullets.map((bullet) => (
                <li key={bullet}>{bullet}</li>
              ))}
            </ul>

            <div className="mt-5 flex flex-wrap gap-2">
              {project.stack.map((tech) => (
                <span
                  key={tech}
                  className="rounded-full border border-gray-200 bg-white px-2.5 py-0.5 text-xs font-medium text-gray-600"
                >
                  {tech}
                </span>
              ))}
            </div>

            <div className="mt-5 flex flex-wrap gap-x-4 gap-y-2 text-sm">
              {project.links.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={
                    link.label === "Try the agent"
                      ? "font-medium text-indigo-600 underline underline-offset-2 hover:text-indigo-800"
                      : "text-gray-600 underline underline-offset-2 hover:text-gray-900"
                  }
                >
                  {link.label}
                </a>
              ))}
            </div>
            {"media" in project && project.media ? (
              <MediaCarousel items={project.media} />
            ) : null}
          </article>
        ))}
      </section>

      <section className="space-y-10">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-gray-400">
          Certifications & community
        </h2>
        {personalExperience.map((item) => (
          <div key={`${item.company}-${item.period}`}>
            <div className="flex items-baseline justify-between">
              <div>
                <span className="font-semibold">{item.company}</span>
                <span className="mx-2 text-gray-300">·</span>
                <span className="text-gray-600">{item.role}</span>
              </div>
              <span className="text-xs text-gray-400 whitespace-nowrap ml-4">
                {item.period}
              </span>
            </div>
            <p className="mt-0.5 text-xs text-gray-400">{item.location}</p>
            {"link" in item && item.link ? (
              <p className="mt-2 text-sm">
                <a
                  href={item.link}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-gray-600 underline underline-offset-2 hover:text-gray-900"
                >
                  Related article
                </a>
              </p>
            ) : null}
            {"bullets" in item && item.bullets?.length ? (
              <ul className="mt-2 space-y-1 text-sm text-gray-600 list-disc list-inside">
                {item.bullets.map((b) => (
                  <li key={b}>{b}</li>
                ))}
              </ul>
            ) : null}
            {"media" in item && item.media ? (
              <MediaCarousel items={item.media} />
            ) : null}
          </div>
        ))}
      </section>
    </div>
  );
}
