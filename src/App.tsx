import { formatTags, profile } from "./profile";
import "./styles.css";

export function App() {
  return (
    <main className="page-shell">
      <section className="hero">
        <p className="eyebrow">Portfolio built as DevOps practice</p>
        <h1>{profile.name}</h1>
        <h2>{profile.role}</h2>
        <p>{profile.summary}</p>
        <div className="hero-actions">
          <a href="https://github.com/Pedro-99" target="_blank" rel="noreferrer">
            GitHub
          </a>
          <a href="#projects">Projects</a>
        </div>
      </section>

      <section id="projects" className="projects" aria-labelledby="projects-title">
        <h2 id="projects-title">Project Highlights</h2>
        <div className="project-grid">
          {profile.highlights.map((project) => (
            <article key={project.title} className="project-card">
              <h3>{project.title}</h3>
              <p>{project.description}</p>
              <span>{formatTags(project.tags)}</span>
            </article>
          ))}
        </div>
      </section>
    </main>
  );
}
