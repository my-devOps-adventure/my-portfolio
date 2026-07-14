import { describe, expect, it } from "vitest";

import { formatTags, profile } from "../src/profile";

describe("profile", () => {
  it("contains DevOps portfolio highlights", () => {
    expect(profile.highlights.length).toBeGreaterThanOrEqual(2);
    expect(profile.summary).toContain("GitHub Actions");
  });

  it("formats project tags for display", () => {
    expect(formatTags(["GitHub Actions", "Docker", "K3s"])).toBe(
      "GitHub Actions / Docker / K3s"
    );
  });
});
