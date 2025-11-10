const http = require('http');
const path = require('path');
const fs = require('fs');

const PORT = process.env.PORT || 5173;
const PUBLIC_DIR = path.join(__dirname, 'public');

function serveFile(res, filePath, contentType = 'text/html') {
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(500, { 'Content-Type': 'text/plain' });
      res.end('Internal Server Error');
      return;
    }

    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/index.html') {
    serveFile(res, path.join(PUBLIC_DIR, 'index.html'));
  } else if (req.url === '/styles.css') {
    serveFile(res, path.join(PUBLIC_DIR, 'styles.css'), 'text/css');
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`Beatmatchr frontend available at http://localhost:${PORT}`);
});
