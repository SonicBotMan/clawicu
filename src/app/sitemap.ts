import type { MetadataRoute } from "next";
import { ISSUES } from "@/content/issues";

export const dynamic = "force-static";

const BASE_URL = "https://xagent.icu";
const LAST_UPDATED = "2026-04-06";

export default function sitemap(): MetadataRoute.Sitemap {
  const issuePages: MetadataRoute.Sitemap = ISSUES.map((issue) => ({
    url: `${BASE_URL}/docs/${issue.slug}/`,
    lastModified: LAST_UPDATED,
    changeFrequency: "monthly",
    priority: issue.severity === "fatal" ? 0.85 : 0.8,
  }));

  return [
    {
      url: `${BASE_URL}/`,
      lastModified: LAST_UPDATED,
      changeFrequency: "weekly",
      priority: 1.0,
    },
    {
      url: `${BASE_URL}/docs/`,
      lastModified: LAST_UPDATED,
      changeFrequency: "weekly",
      priority: 0.9,
    },
    {
      url: `${BASE_URL}/docs/tool-unlock-panel/`,
      lastModified: LAST_UPDATED,
      changeFrequency: "monthly",
      priority: 0.85,
    },
    {
      url: `${BASE_URL}/rescue/`,
      lastModified: LAST_UPDATED,
      changeFrequency: "monthly",
      priority: 0.75,
    },
    {
      url: `${BASE_URL}/download/`,
      lastModified: LAST_UPDATED,
      changeFrequency: "monthly",
      priority: 0.65,
    },
    ...issuePages,
  ];
}
