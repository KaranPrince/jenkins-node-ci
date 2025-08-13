// Minimal HTTP server (no external deps) that injects env vars into index.html

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const indexPath = path.join(__dirname, 'index.html');

function renderIndex() {
  let html = fs.readFileSync(indexPath, 'utf8');

  const mapping = {
    '__BUILD_NUMBER__': process.env.BUILD_NUMBER || 'N/A',
    '__GIT_DATE__':     process.env.GIT_DATE || new Date().toISOString(),
    '__GIT_BRANCH__':   process.env.GIT_BRANCH || 'unknown',
    '__GIT_COMMIT__':   process.env.GIT_COMMIT || 'unknown',
    '__GIT_AUTHOR__':   process.env.GIT_AUTHOR || 'unknown',
    '__GIT_MESSAGE__':  process.env.GIT_MESSAGE || 'n/a',
    '__ENVIRONMENT__':  process.env.ENVIRONMENT || 'local'
  };

  for (const [placeholder, value] of Object.entries(mapping)) {
    const re = new RegExp(placeholder, 'g');
    html = html.replace(re, String(value));
  }
  return html;
}

const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/index.html') {
    const html = renderIndex();
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(html);
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
