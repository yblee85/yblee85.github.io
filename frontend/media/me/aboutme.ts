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
        url: "/media/images/rt7-reports.png",
        description: "BI Analytics Platform - Sales reports",
      },
      {
        type: "image",
        url: "/media/images/rt7-inventory-management.png",
        description: "Inventory management",
      },
      {
        type: "image",
        url: "/media/images/rt7-menu-management.png",
        description: "Menu management",
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
    period: "Sep 2023 – Sep 2023",
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

export { profile, skills, experience, personalExperience };
