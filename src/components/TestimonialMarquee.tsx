const testimonials = [
  { text: "ClawICU saved me hours of debugging when my OpenClaw gateway crashed.", author: "DevOps Lead" },
  { text: "The automated diagnostics caught a config issue I would have missed.", author: "Systems Engineer" },
  { text: "One command to fix everything. Incredible tool.", author: "Backend Developer" },
  { text: "The rescue process is remarkably thorough and fast.", author: "Platform Engineer" },
  { text: "Every issue was resolved in under 60 seconds.", author: "SRE Manager" },
  { text: "The guided repair menu is genuinely helpful.", author: "Full-Stack Developer" },
  { text: "The rollback safety gave me confidence to try repairs.", author: "Infrastructure Lead" },
  { text: "Replaced three internal scripts with one ClawICU command.", author: "Tech Lead" },
];

export function TestimonialMarquee() {
  return (
    <section className="relative w-full overflow-hidden py-12">
      <div className="mx-auto max-w-6xl px-6">
        <p className="mb-8 text-center text-sm font-medium uppercase tracking-widest text-muted-foreground">
          Trusted by developers worldwide
        </p>
      </div>

      <div className="relative">
        <div className="pointer-events-none absolute left-0 top-0 bottom-0 z-10 w-32 bg-gradient-to-r from-[#050810] to-transparent" />
        <div className="pointer-events-none absolute right-0 top-0 bottom-0 z-10 w-32 bg-gradient-to-l from-[#050810] to-transparent" />

        <div className="flex" style={{ animation: "marquee 60s linear infinite" }}>
          {testimonials.map((t, i) => (
            <div
              key={`${t.author}-${i}`}
              className="mr-4 flex-shrink-0 rounded-xl border border-border bg-card/60 backdrop-blur-sm p-6 w-80"
            >
              <p className="text-sm leading-relaxed text-foreground">"{t.text}"</p>
              <p className="mt-3 text-xs font-medium text-[#8892b0]">{t.author}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}