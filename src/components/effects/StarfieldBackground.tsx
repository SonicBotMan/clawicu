"use client";

export function StarfieldBackground() {
  return (
    <div
      className="pointer-events-none fixed inset-0 overflow-hidden"
      aria-hidden="true"
    >
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_50%_0%,rgba(255,77,77,0.08)_0%,transparent_60%)]" />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_80%_50%,rgba(0,229,204,0.05)_0%,transparent_40%)]" />

      <svg
        className="absolute inset-0 w-full h-full"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <circle id="star-small" cx="1" cy="1" r="0.5" fill="rgba(255,255,255,0.6)" />
          <circle id="star-medium" cx="1" cy="1" r="1" fill="rgba(255,255,255,0.5)" />
          <circle id="star-large" cx="1" cy="1" r="1.5" fill="rgba(255,77,77,0.6)" />
        </defs>
        <g style={{ animation: "star-drift 150s linear infinite" }}>
          <use href="#star-small" x="50" y="80" />
          <use href="#star-small" x="200" y="150" />
          <use href="#star-small" x="350" y="60" />
          <use href="#star-small" x="500" y="200" />
          <use href="#star-small" x="650" y="100" />
          <use href="#star-small" x="800" y="180" />
          <use href="#star-small" x="950" y="50" />
          <use href="#star-small" x="1100" y="140" />
          <use href="#star-small" x="1250" y="90" />
          <use href="#star-small" x="1400" y="170" />
          <use href="#star-small" x="100" y="300" />
          <use href="#star-small" x="250" y="380" />
          <use href="#star-small" x="400" y="280" />
          <use href="#star-small" x="550" y="350" />
          <use href="#star-small" x="700" y="320" />
          <use href="#star-small" x="850" y="400" />
          <use href="#star-small" x="1000" y="290" />
          <use href="#star-small" x="1150" y="370" />
          <use href="#star-small" x="1300" y="310" />
          <use href="#star-small" x="1450" y="360" />
          <use href="#star-small" x="150" y="500" />
          <use href="#star-small" x="300" y="550" />
          <use href="#star-small" x="450" y="480" />
          <use href="#star-small" x="600" y="530" />
          <use href="#star-small" x="750" y="460" />
          <use href="#star-small" x="900" y="520" />
          <use href="#star-small" x="1050" y="490" />
          <use href="#star-small" x="1200" y="540" />
          <use href="#star-small" x="1350" y="470" />
          <use href="#star-small" x="80" y="650" />
          <use href="#star-small" x="220" y="700" />
          <use href="#star-small" x="380" y="620" />
          <use href="#star-small" x="520" y="680" />
          <use href="#star-small" x="680" y="640" />
          <use href="#star-small" x="820" y="710" />
          <use href="#star-small" x="980" y="600" />
          <use href="#star-small" x="1120" y="670" />
          <use href="#star-small" x="1280" y="630" />
          <use href="#star-small" x="1420" y="690" />
          <use href="#star-medium" x="180" y="200" />
          <use href="#star-medium" x="420" y="350" />
          <use href="#star-medium" x="780" y="150" />
          <use href="#star-medium" x="1050" y="420" />
          <use href="#star-medium" x="1320" y="250" />
          <use href="#star-medium" x="350" y="520" />
          <use href="#star-medium" x="620" y="600" />
          <use href="#star-medium" x="890" y="480" />
          <use href="#star-medium" x="1150" y="550" />
          <use href="#star-medium" x="1380" y="450" />
          <use href="#star-large" x="280" y="120" />
          <use href="#star-large" x="560" y="420" />
          <use href="#star-large" x="920" y="280" />
          <use href="#star-large" x="1180" y="180" />
          <use href="#star-large" x="480" y="620" />
          <use href="#star-large" x="740" y="500" />
          <use href="#star-large" x="1000" y="350" />
          <use href="#star-large" x="1260" y="580" />
        </g>
      </svg>
    </div>
  );
}