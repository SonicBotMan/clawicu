import type { Metadata } from "next";
import { Header } from "@/components/layout/Header";
import { Footer } from "@/components/layout/Footer";
import { ISSUES, getIssueBySlug } from "@/content/issues";
import Link from "next/link";
import { notFound } from "next/navigation";
import { ArrowLeft, AlertTriangle, Wrench, Search } from "lucide-react";

interface PageProps {
  params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
  return ISSUES.map((issue) => ({
    slug: issue.slug,
  }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const issue = getIssueBySlug(slug);
  if (!issue) return { title: "Not Found" };
  return {
    title: `${issue.title} — How to Diagnose & Fix`,
    description: issue.description,
    alternates: {
      canonical: `/docs/${slug}/`,
    },
    openGraph: {
      title: `${issue.title} | ClawICU Docs`,
      description: issue.description,
      url: `https://xagent.icu/docs/${slug}/`,
      type: "article",
      publishedTime: "2026-04-04",
      modifiedTime: "2026-04-06",
    },
    twitter: {
      card: "summary",
      title: `${issue.title} | ClawICU`,
      description: issue.description,
    },
  };
}

export default async function DocPage({ params }: PageProps) {
  const { slug } = await params;
  const issue = getIssueBySlug(slug);
  if (!issue) notFound();

  const articleJsonLd = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "BreadcrumbList",
        itemListElement: [
          { "@type": "ListItem", position: 1, name: "Home", item: "https://xagent.icu/" },
          { "@type": "ListItem", position: 2, name: "Docs", item: "https://xagent.icu/docs/" },
          { "@type": "ListItem", position: 3, name: issue.title, item: `https://xagent.icu/docs/${slug}/` },
        ],
      },
      {
        "@type": "TechArticle",
        "@id": `https://xagent.icu/docs/${slug}/#article`,
        headline: `${issue.title} — How to Diagnose & Fix`,
        description: issue.description,
        url: `https://xagent.icu/docs/${slug}/`,
        inLanguage: "en-US",
        datePublished: "2026-04-04",
        dateModified: "2026-04-06",
        author: { "@type": "Organization", name: "ClawICU", url: "https://xagent.icu" },
        publisher: { "@type": "Organization", name: "ClawICU", url: "https://xagent.icu" },
        isPartOf: { "@type": "WebSite", url: "https://xagent.icu" },
        about: { "@type": "SoftwareApplication", name: "OpenClaw" },
        proficiencyLevel: "Beginner",
        articleSection: "Troubleshooting",
      },
      {
        "@type": "HowTo",
        name: `How to fix: ${issue.title}`,
        description: issue.diagnosis,
        url: `https://xagent.icu/docs/${slug}/`,
        step: issue.steps.map((step, i) => ({
          "@type": "HowToStep",
          position: i + 1,
          text: step,
        })),
      },
    ],
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(articleJsonLd) }}
      />
      <Header />
      <main className="min-h-screen pt-24 pb-16">
        <div className="mx-auto max-w-3xl px-6">
          <Link
            href="/docs"
            className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground mb-8 transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to all issues
          </Link>

          <div className="mb-12">
            <div className="inline-flex items-center gap-2 rounded-full border border-border bg-card backdrop-blur-[12px] px-4 py-1.5 font-mono text-xs text-[#8892b0] mb-6">
              <AlertTriangle className="h-3 w-3 text-primary" />
              {issue.severity.toUpperCase()}
            </div>
            <h1 className="font-heading text-4xl font-bold tracking-tight text-foreground">
              {issue.title}
            </h1>
            <p className="mt-4 text-lg text-muted-foreground">
              {issue.description}
            </p>
          </div>

          <section className="mb-12">
            <h2 className="font-heading text-xl font-semibold text-foreground mb-4 flex items-center gap-2">
              <Search className="h-5 w-5 text-primary" />
              How to Diagnose
            </h2>
            <div className="rounded-xl border border-border bg-card backdrop-blur-[12px] p-6">
              <p className="text-muted-foreground">{issue.diagnosis}</p>
            </div>
          </section>

          <section className="mb-12">
            <h2 className="font-heading text-xl font-semibold text-foreground mb-4 flex items-center gap-2">
              <Wrench className="h-5 w-5 text-primary" />
              Fix Steps
            </h2>
            <ol className="space-y-4">
              {issue.steps.map((step, i) => (
                <li key={i} className="flex gap-4">
                  <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary font-mono text-sm">
                    {i + 1}
                  </span>
                  <span className="pt-1 text-muted-foreground">{step}</span>
                </li>
              ))}
            </ol>
          </section>

          <section className="mb-12">
            <h2 className="font-heading text-xl font-semibold text-foreground mb-4">
              Related Modules
            </h2>
            <div className="flex flex-wrap gap-2">
              {issue.relatedChecks.map((check) => (
                <span
                  key={check}
                  className="rounded-full bg-surface px-3 py-1 font-mono text-xs text-muted-foreground"
                >
                  {check}
                </span>
              ))}
              {issue.relatedRepairs.map((repair) => (
                <span
                  key={repair}
                  className="rounded-full bg-primary/10 px-3 py-1 font-mono text-xs text-primary"
                >
                  {repair}
                </span>
              ))}
            </div>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
