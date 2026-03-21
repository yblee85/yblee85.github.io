"use client";

import { useCallback, useEffect, useState } from "react";

export type MediaItem = {
  type: string;
  url: string;
  description?: string;
};

type Props = {
  items: MediaItem[];
  /** Auto-advance interval in ms (default 5000) */
  intervalMs?: number;
};

export default function MediaCarousel({ items, intervalMs = 5000 }: Props) {
  const [index, setIndex] = useState(0);
  const [paused, setPaused] = useState(false);

  const len = items.length;
  const goNext = useCallback(() => {
    setIndex((i) => (i + 1) % len);
  }, [len]);
  const goPrev = useCallback(() => {
    setIndex((i) => (i - 1 + len) % len);
  }, [len]);

  useEffect(() => {
    if (len <= 1 || paused) return;
    const id = window.setInterval(goNext, intervalMs);
    return () => window.clearInterval(id);
  }, [len, paused, intervalMs, goNext]);

  if (!len) return null;

  const current = items[index];

  return (
    <div
      className="mt-4 max-w-4xl"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
    >
      <figure className="space-y-3">
        <div className="relative overflow-hidden rounded-lg border border-gray-200 bg-gray-50 shadow-sm">
          <div className="flex min-h-[min(70vh,520px)] w-full items-center justify-center p-4 sm:p-6">
            <img
              key={current.url}
              src={current.url}
              alt={current.description ?? "Screenshot"}
              className="max-h-[min(70vh,520px)] w-auto max-w-full object-contain"
            />
          </div>
          {len > 1 ? (
            <>
              <button
                type="button"
                onClick={goPrev}
                className="absolute left-2 top-1/2 -translate-y-1/2 rounded-full bg-white/90 p-2 text-gray-700 shadow ring-1 ring-gray-200 hover:bg-white"
                aria-label="Previous image"
              >
                <svg
                  aria-hidden
                  className="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M15 19l-7-7 7-7"
                  />
                </svg>
              </button>
              <button
                type="button"
                onClick={goNext}
                className="absolute right-2 top-1/2 -translate-y-1/2 rounded-full bg-white/90 p-2 text-gray-700 shadow ring-1 ring-gray-200 hover:bg-white"
                aria-label="Next image"
              >
                <svg
                  aria-hidden
                  className="h-5 w-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </button>
              <div className="absolute bottom-3 left-0 right-0 flex justify-center gap-1.5">
                {items.map((m, i) => (
                  <button
                    key={m.url}
                    type="button"
                    onClick={() => setIndex(i)}
                    className={`h-2 w-2 rounded-full transition-colors ${
                      i === index ? "bg-gray-900" : "bg-gray-300 hover:bg-gray-400"
                    }`}
                    aria-label={`Go to image ${i + 1}`}
                    aria-current={i === index}
                  />
                ))}
              </div>
            </>
          ) : null}
        </div>
        {current.description ? (
          <figcaption className="text-sm leading-snug text-gray-600">
            {current.description}
          </figcaption>
        ) : null}
        {len > 1 ? (
          <p className="text-center text-xs text-gray-400">
            {index + 1} / {len}
            {paused ? " · paused" : ""}
          </p>
        ) : null}
      </figure>
    </div>
  );
}
