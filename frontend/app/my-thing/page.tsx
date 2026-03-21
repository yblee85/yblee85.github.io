import MediaCarousel from "@/components/MediaCarousel";
import { personalExperience } from "@/media/me/aboutme";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "MyThing · Yunbo Lee",
  description: "Certifications, learning, and community outside day-to-day work.",
};

export default function MyThingPage() {
  return (
    <div className="space-y-12">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">MyThing</h1>
        <p className="mt-2 text-sm text-gray-500">
          Certifications, learning, and community outside day-to-day work.
        </p>
      </div>

      <section className="space-y-10">
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
