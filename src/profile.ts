export interface ProjectHighlight {
  title: string;
  description: string;
  tags: string[];
}

export interface Profile {
  name: string;
  role: string;
  summary: string;
  highlights: ProjectHighlight[];
}

export const profile: Profile = {
  name: "Badr Zineddaine",
  role: "DevOps Learner",
  summary:
    "Practicing real delivery workflows with Jira, GitHub Actions, containers, and K3s.",
  highlights: [
    {
      title: "Jira Infrastructure as Code",
      description:
        "A TypeScript CLI that reconciles Jira backlog state, statuses, and work items from YAML.",
      tags: ["TypeScript", "Jira", "IaC"],
    },
    {
      title: "Portfolio Delivery Pipeline",
      description:
        "A portfolio app built, tested, containerized, and deployed through GitHub Actions.",
      tags: ["GitHub Actions", "Docker", "K3s"],
    },
  ],
};

export function formatTags(tags: string[]): string {
  return tags.join(" / ");
}
