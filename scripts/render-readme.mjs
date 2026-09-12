#!/usr/bin/env node
// Renders README.md into site/index.html for GitHub Pages.
//
// Run locally with:  npm install && npm run docs:build
// CI runs the same thing, so what you see locally is what gets published.

import { readFile, writeFile, mkdir, cp, access } from 'node:fs/promises';
import { marked } from 'marked';

const SOURCE = 'README.md';
const OUT_DIR = 'site';
const OUT_FILE = `${OUT_DIR}/index.html`;
const IMG_DIR = 'docs/img';

const markdown = await readFile(SOURCE, 'utf8');

// Page title comes from the first level-1 heading, falling back to the repo
// name so the tab is never just "index".
const title = markdown.match(/^#\s+(.+)$/m)?.[1].trim() ?? 'devops-bootcamp-project';

marked.setOptions({ gfm: true, breaks: false });
let body = marked.parse(markdown);

// GitHub renders ```mermaid fences natively; a plain Markdown converter does
// not. marked turns them into <pre><code class="language-mermaid">, with the
// contents HTML-escaped. Mermaid needs <pre class="mermaid"> holding the raw
// source, so rewrite the block and undo the escaping.
const unescape = (s) =>
  s
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, '&');

body = body.replace(
  /<pre><code class="language-mermaid">([\s\S]*?)<\/code><\/pre>/g,
  (_match, code) => `<pre class="mermaid">${unescape(code)}</pre>`
);

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
<style>
  :root {
    color-scheme: light dark;
    --bg: #ffffff;
    --fg: #1f2328;
    --muted: #59636e;
    --rule: #d1d9e0;
    --code-bg: #f6f8fa;
    --link: #0969da;
    --accent: #0969da;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #0d1117;
      --fg: #e6edf3;
      --muted: #9198a1;
      --rule: #3d444d;
      --code-bg: #161b22;
      --link: #4493f8;
      --accent: #4493f8;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    padding: 2.5rem 1.25rem 6rem;
    background: var(--bg);
    color: var(--fg);
    font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  main { max-width: 60rem; margin: 0 auto; }
  h1, h2, h3 { line-height: 1.25; margin-top: 2em; margin-bottom: .6em; font-weight: 600; }
  h1 { font-size: 2rem; margin-top: 0; padding-bottom: .3em; border-bottom: 1px solid var(--rule); }
  h2 { font-size: 1.4rem; padding-bottom: .3em; border-bottom: 1px solid var(--rule); }
  h3 { font-size: 1.1rem; }
  p, li { color: var(--fg); }
  a { color: var(--link); text-decoration: none; }
  a:hover { text-decoration: underline; }
  code {
    background: var(--code-bg);
    padding: .15em .4em;
    border-radius: 6px;
    font: .875em/1.5 ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, monospace;
  }
  pre {
    background: var(--code-bg);
    padding: 1rem;
    border-radius: 8px;
    overflow-x: auto;
    border: 1px solid var(--rule);
  }
  pre code { background: none; padding: 0; }
  table {
    border-collapse: collapse;
    width: 100%;
    margin: 1rem 0;
    display: block;
    overflow-x: auto;
  }
  th, td { border: 1px solid var(--rule); padding: .5rem .75rem; text-align: left; }
  th { background: var(--code-bg); font-weight: 600; }
  blockquote {
    margin: 1rem 0;
    padding: 0 1rem;
    border-left: .25rem solid var(--rule);
    color: var(--muted);
  }
  hr { border: 0; border-top: 1px solid var(--rule); margin: 2rem 0; }
  pre.mermaid {
    background: var(--code-bg);
    text-align: center;
    line-height: normal;
  }
  footer {
    max-width: 60rem;
    margin: 4rem auto 0;
    padding-top: 1rem;
    border-top: 1px solid var(--rule);
    color: var(--muted);
    font-size: .85rem;
  }
</style>
</head>
<body>
<main>
${body}
</main>
<footer>
  Generated from <code>README.md</code> by GitHub Actions.
</footer>
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
  const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  mermaid.initialize({ startOnLoad: true, theme: dark ? 'dark' : 'default' });
</script>
</body>
</html>
`;

await mkdir(OUT_DIR, { recursive: true });
await writeFile(OUT_FILE, html, 'utf8');

// The README references screenshots as docs/img/*.png. Those paths are
// relative, so the images have to sit at the same relative location inside the
// published site or every one of them renders as a broken image.
try {
  await access(IMG_DIR);
  await cp(IMG_DIR, `${OUT_DIR}/${IMG_DIR}`, { recursive: true });
  console.log(`Copied ${IMG_DIR} -> ${OUT_DIR}/${IMG_DIR}`);
} catch {
  console.log(`No ${IMG_DIR} directory - skipping image copy`);
}

console.log(`Rendered ${SOURCE} -> ${OUT_FILE} (${html.length} bytes, title: "${title}")`);
