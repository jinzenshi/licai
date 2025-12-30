// Render Node.js 服务器
const http = require('http');
const fs = require('fs');
const path = require('path');

const API_KEY = process.env.BAIDU_API_KEY;
const SECRET_KEY = process.env.BAIDU_SECRET_KEY;
const PORT = process.env.PORT || 3000;

let accessToken = null;
let tokenTime = 0;
const TOKEN_EXPIRE = 25 * 24 * 60 * 60 * 1000;

// 获取百度token
async function getToken() {
  if (accessToken && Date.now() - tokenTime < TOKEN_EXPIRE) {
    return accessToken;
  }

  const response = await fetch(
    `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${API_KEY}&client_secret=${SECRET_KEY}`,
    { method: 'POST' }
  );

  const data = await response.json();
  if (data.error) throw new Error(data.error_description || '获取token失败');

  accessToken = data.access_token;
  tokenTime = Date.now();
  return accessToken;
}

// 静态文件服务
function serveStatic(req, res, filePath) {
  const ext = path.extname(filePath);
  const contentType = {
    '.html': 'text/html',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg'
  }[ext] || 'text/plain';

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not Found');
      return;
    }
    res.writeHead(200, { 'Content-Type': contentType });
    res.end(data);
  });
}

// HTTP服务器
const server = http.createServer(async (req, res) => {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // OCR API
  if (req.method === 'POST' && req.url === '/api/ocr') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const { image } = JSON.parse(body);
        if (!image) throw new Error('缺少图片数据');

        const token = await getToken();

        const ocrResponse = await fetch(
          `https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=${token}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: new URLSearchParams({ image })
          }
        );

        const data = await ocrResponse.json();
        if (data.error_code) throw new Error(data.error_msg || 'OCR识别失败');

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(data));
      } catch (error) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: error.message }));
      }
    });
    return;
  }

  // 静态文件 (在同一目录)
  let filePath = req.url === '/' ? '/teacher-check.html' : req.url;
  const fullPath = path.join(__dirname, filePath);
  serveStatic(req, res, fullPath);
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
