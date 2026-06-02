import MediaCarousel from "@/components/MediaCarousel";
import { experience } from "@/media/me/aboutme";

export default function Career() {
  return (
    <div className="space-y-12">
      <h1 className="text-2xl font-bold tracking-tight">Career</h1>

      {/* Work experience */}
      <section className="space-y-6">
        <h2 className="text-xs font-semibold uppercase tracking-wider text-gray-400">
          Experience
        </h2>
        <div className="space-y-10">
          {experience.map((job) => (
            <div key={job.company}>
              <div className="flex items-baseline justify-between">
                <div>
                  <span className="font-semibold">{job.company}</span>
                  <span className="mx-2 text-gray-300">·</span>
                  <span className="text-gray-600">{job.role}</span>
                </div>
                <span className="text-xs text-gray-400 whitespace-nowrap ml-4">
                  {job.period}
                </span>
              </div>
              <p className="mt-0.5 text-xs text-gray-400">{job.location}</p>
              <ul className="mt-2 space-y-1 text-sm text-gray-600 list-disc list-inside">
                {job.bullets.map((b) => (
                  <li key={b}>{b}</li>
                ))}
              </ul>
              <MediaCarousel items={job.media} />
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
