const experience = [
  {
    company: "Mappedin",
    role: "Senior Software Engineer",
    period: "Jan 2025 – Jan 2026",
    location: "Canada (Remote)",
    bullets: [
      "Led ETL migration from ClickHouse/MongoDB to Snowflake, covering ~4B records.",
      "Designed and built a high-throughput data processing application into Snowflake handling ~1.8B events/year.",
      "Strengthened platform security by migrating authentication token algorithms.",
      "Reduced critical web application page load time by ~80%.",
      "Implemented OTEL across microservices in the ecosystem.",
    ],
    media: [
      {
        type: "image",
        url: "/media/images/mappedin.png",
        description:
          "Mappedin (https://www.mappedin.com/), Indoor mapping/wayfinding solution.",
      },
      {
        type: "image",
        url: "/media/images/yankees-map.png",
        description:
          "MLB Yankees Stadium Map (https://www.mlb.com/yankees/ballpark/concourse-map)",
      },
      {
        type: "image",
        url: "/media/images/lax-map.png",
        description: "LAX Airport Map (https://www.flylax.com/map#/)",
      },
    ],
  },
  {
    company: "MedStack",
    role: "Senior Software Engineer",
    period: "Jun 2021 – Nov 2024",
    location: "Canada (Remote)",
    bullets: [
      "Built REST APIs for AWS, achieving feature parity with existing Azure offerings.",
      "Led frontend modernization, migrating Ruby-based UI to React for better maintainability and velocity.",
      "Migrated VM monitoring from Elasticsearch to OpenSearch to improve sustainability and cost control.",
      "Implemented SIEM solution using OpenSearch and Filebeat.",
      "Built cloud resource metrics APIs to provide real-time operational insights.",
      "Developed Azure cost-saving scripts to find optimization opportunities and reduce infrastructure spend.",
      "Created automated Azure credential expiry warning reports to prevent outages and improve reliability.",
      "Authored ~90% of on-call playbooks, cutting incident resolution time and improving on-call effectiveness.",
    ],
    media: [
      {
        type: "image",
        url: "/media/images/medstack.png",
        description:
          "MedStack (https://www.medstack.com/), HIPAA-compliant platform to build, maintain and audit digital health application.",
      },
      {
        type: "image",
        url: "/media/images/medstack-compliance.png",
        description:
          "MedStack (https://www.medstack.com/), HIPAA-compliant platform to build, maintain and audit digital health application.",
      },
      {
        type: "image",
        url: "/media/images/medstack-case-study.png",
        description: "Customers",
      },
    ],
  },
  {
    company: "RT7 Incorporated",
    role: "Staff Software Engineer",
    period: "May 2011 – May 2021",
    location: "Toronto, ON",
    bullets: [
      "Designed and built a full-featured POS system integrated with multiple payment gateways",
      "Scaled to ~300 transactions/day/store across ~500 US & Canada stores, processing ~50M yearly.",
      "Built a comprehensive BI analytics web platform for store and franchise owners.",
      "Sales, inventory, tax, and tip reports",
      "Customer management",
      "Rewards & gift card management",
      "Employee management",
      "Advertising management",
      "Engineered backend systems processing ~55M records per year.",
      "Built backend APIs for mobile ordering and rewards apps integrated with the POS ecosystem.",
      "Fully integrated third-party delivery services (Postmates, Trackin) into the POS ecosystem.",
      "Supported ~1M transactions per year with high reliability.",
      "Led on-premises to AWS migration, improving scalability, reliability, and operational efficiency.",
    ],
    media: [
      {
        type: "image",
        url: "/media/images/rt7-management-reports-1.png",
        description: "BI analytics platform - report dashboard",
      },
      {
        type: "image",
        url: "/media/images/rt7-management-reports-2.png",
        description: "BI analytics platform - detailed reports",
      },
      {
        type: "image",
        url: "/media/images/rt7-management-inventory.png",
        description: "Inventory management",
      },
      {
        type: "image",
        url: "/media/images/rt7-management-menu.png",
        description: "Menu management",
      },
      {
        type: "image",
        url: "/media/images/rt7-management-campaigns.png",
        description: "Campaign management",
      },
      {
        type: "image",
        url: "/media/images/rt7-management-employees.png",
        description: "Employee management",
      },
      {
        type: "image",
        url: "/media/images/rt7-management-rewards.png",
        description: "Rewards management",
      },
      {
        type: "image",
        url: "/media/images/rt7-mobile-app-home.png",
        description: "Mobile app to place order for pickup/delivery",
      },
      {
        type: "image",
        url: "/media/images/rt7-mobile-app-stores.png",
        description: "Find stores near you",
      },
      {
        type: "image",
        url: "/media/images/rt7-mobile-apps.png",
        description: "RT7 solution customers",
      },
    ],
  },
];

const personalProjects = [
  {
    "name": "Receipt Organizer",
    "role": "Personal full-stack project",
    "period": "2026",
    "summary": "End-to-end receipt capture app: upload a photo or PDF, OCR with Google Document AI, review extracted fields in a Next.js UI, and append a validated row to a shared Google Sheet — with Auth0 login and an email allow-list so only trusted users can access it.",
    "bullets": [
      "Designed a domain-driven backend (users + receipts bounded contexts) with rich entities, ports/adapters, and thin application services — refactored from a layer-based Express codebase without changing the public API.",
      "Built an OCR pipeline with Google Document AI Expense Parser, an anti-corruption layer for Google entity types, and parse-quality warnings (missing, low-confidence, defaulted fields) so users fix uncertain reads before saving.",
      "Persisted receipts to Google Sheets via a service account — auto year tabs, insert-above-TOTAL rows, live SUM formulas, and duplicate detection (409 Conflict) — no application database.",
      "Secured the app with Auth0 (server-side OAuth, encrypted session cookies, allow-list + optional admin flag); frontend stays thin — no secrets or auth logic in the browser.",
      "Shipped with Docker Compose, domain/API/integration tests, and documented the full system in ARCHITECTURE.md."
    ],
    "stack": [
      "Next.js",
      "TypeScript",
      "Express",
      "Google Document AI",
      "Google Sheets API",
      "Auth0",
      "Docker",
      "Domain-Driven Design",
      "Node.js"
    ],
    "links": [
      {
        "label": "Source code",
        "href": "https://github.com/yblee85/receipt-organizer"
      },
      {
        "label": "Architecture",
        "href": "https://github.com/yblee85/receipt-organizer/blob/main/ARCHITECTURE.md"
      }
    ],
    "media": [
      {
        "type": "image",
        "url": "/media/images/receipt-organizer-1.png",
        "description": "Upload screen — Auth0 sign-in, file upload or manual entry.",
      },
      {
        "type": "image",
        "url": "/media/images/receipt-organizer-2.png",
        "description": "Review screen — Document AI OCR with low-confidence field warnings before save.",
      },
      {
        "type": "image",
        "url": "/media/images/receipt-organizer-3.png",
        "description": "Google Sheet output — receipt row appended with live TOTAL formula.",
      },
    ]
  },
  {
    name: "This very site! (Portfolio site + AI career agent)",
    role: "Personal full-stack project",
    period: "2026",
    summary:
      "This site is both my portfolio and a working demo: a static Next.js frontend on GitHub Pages talks to a Ruby API on DigitalOcean that answers career questions with retrieval-augmented generation (RAG).",
    bullets: [
      "Built a RAG pipeline — chunk portfolio JSON, embed with Voyage AI (or local TEI), cosine search in memory, synthesize answers with Claude.",
      "Split deployment: static frontend (GitHub Pages + Actions) and API backend (Docker on DigitalOcean App Platform).",
      "Protected chat with OAuth2 (Auth0 → Google, GitHub, LinkedIn), session cookies across origins, CSRF tokens, and per-user rate limits.",
      "Added admin reindex, event bus, optional Slack notifications, and documented the full system in ARCHITECTURE.md.",
    ],
    stack: [
      "Next.js",
      "TypeScript",
      "Ruby",
      "Sinatra",
      "Claude API",
      "RAG",
      "Auth0",
      "Docker",
      "GitHub Actions",
    ],
    links: [
      { label: "Live site", href: "https://yunbo-lee.me/" },
      { label: "Try the agent", href: "https://yunbo-lee.me/chat/" },
      { label: "Source code", href: "https://github.com/yblee85/yblee85.github.io" },
      {
        label: "Architecture",
        href: "https://github.com/yblee85/yblee85.github.io/blob/main/ARCHITECTURE.md",
      },
    ],
  },
];

const personalExperience = [
  {
    company: "The Linux Foundation",
    role: "Certified Kubernetes Application Developer",
    period: "Nov 2023 – Nov 2023",
    location: "Toronto, ON",
    media: [
      {
        type: "image",
        url: "/media/images/ckad-certification.png",
      },
    ],
  },
  {
    company: "MaRS Energy Hackathon",
    role: "Backend Developer",
    period: "Sep 2013 – Sep 2013",
    location: "Toronto, ON",
    bullets: [
      "Built a backend for a mobile app to help people reduce cost of energy consumption.",
    ],
    link: "https://www.marsdd.com/our-story/mars-energy-hackathon-spawns-apps-to-help-people-manage-energy-consumption/",
    media: [
      {
        type: "image",
        url: "/media/images/mars-energy-hackathon.png",
      },
    ],
  },
];

const skills = [
  {
    category: "System Design & Architecture",
    items:
      "REST APIs, Microservices, Distributed Systems, Scalability, High Availability, Load Balancing",
  },
  {
    category: "Languages & Frameworks",
    items: "TypeScript, Ruby, Java, Bash, Node.js, Nest.js, Roda (Ruby), React",
  },
  {
    category: "Cloud & DevOps",
    items:
      "AWS, Azure, Cloudflare, Docker, K8s (CKAD), CI/CD pipelines, Terraform, Ansible, Github, Buildkite, Jenkins",
  },
  {
    category: "Data & Analytics",
    items:
      "Snowflake, ClickHouse, OpenSearch/Elasticsearch, Postgres, MongoDB, CouchDB, Redis, Superset",
  },
  {
    category: "Observability & Debugging",
    items: "OpenTelemetry (OTEL), Sentry, PagerDuty, Grafana(Loki, Tempo), Kibana",
  },
  {
    category: "Security",
    items: "OAuth2, OIDC, JWT, API security protocol, SIEM (OpenSearch + filebeat)",
  },
];

const profile = {
  name: "Yunbo Lee",
  title: "Senior Software Engineer",
  description:
    "Senior Software Engineer with extensive experience building and scaling high‑volume, mission‑critical systems in retail, healthcare, and indoor mapping platforms. Proven track record delivering POS systems processing 50M+ transactions/year, large‑scale data pipelines handling 1.8B+ events/year, and leading major cloud, data, and performance migrations. Strong in backend systems, cloud infrastructure, data engineering, observability, and technical leadership.",
  contact: {
    email: "mailto:yblee85@gmail.com",
    github: "https://github.com/yblee85",
    linkedin: "https://linkedin.com/in/yunbo-lee",
  },
};

export { profile, skills, experience, personalProjects, personalExperience };
