// Render Node.js 服务器
const http = require('http');
const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

// 豆包API配置
const DOUBAO_API_KEY = process.env.DOUBAO_API_KEY;
const DOUBAO_ENDPOINT = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
const DOUBAO_MODEL = 'doubao-seed-1-6-flash-250828';

const PORT = process.env.PORT || 3000;

// 加载Excel数据
let excelData = [];
const EXCEL_FILE = path.join(__dirname, '广州市黄埔区教育局庄雪梅在2025年12月29日导出注册数据76699359755211.xlsx');

try {
  if (fs.existsSync(EXCEL_FILE)) {
    const workbook = XLSX.readFile(EXCEL_FILE);
    const sheetName = workbook.SheetNames[0];
    excelData = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName]);
    console.log(`已加载 ${excelData.length} 条教师数据`);
  } else {
    console.log('Excel文件不存在');
  }
} catch (e) {
  console.log('加载Excel失败:', e.message);
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

// 查询数据
function queryData(idNumber) {
  idNumber = idNumber.toUpperCase();
  const match = excelData.find(row => {
    const excelId = String(row['证件号码'] || '').trim().toUpperCase();
    return excelId === idNumber;
  });
  return match || null;
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

  // OCR + 查询 API
  if (req.method === 'POST' && req.url === '/api/query') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const { image } = JSON.parse(body);
        if (!image) throw new Error('缺少图片数据');

        // 调用豆包API（优化提示词，快速回答）
        const response = await fetch(DOUBAO_ENDPOINT, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${DOUBAO_API_KEY}`
          },
          body: JSON.stringify({
            model: DOUBAO_MODEL,
            max_tokens: 100,
            temperature: 0.1,
            messages: [
              {
                role: 'user',
                content: [
                  { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${image}` } },
                  { type: 'text', text: '提取身份证号，只返回18位数字。' }
                ]
              }
            ]
          })
        });

        const data = await response.json();

        if (data.error) {
          throw new Error(data.error.message || 'OCR识别失败');
        }

        // 提取身份证号
        const content = data.choices?.[0]?.message?.content || '';
        const idMatch = content.match(/\d{17}[\dXx]/);
        const idNumber = idMatch ? idMatch[0] : '';

        // 查询数据库
        const match = queryData(idNumber);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          idNumber,
          match: match ? {
            found: true,
            data: {
              姓名: match['姓名'],
              性别: match['性别'],
              资格种类: match['资格种类'],
              任教学科: match['任教学科'],
              确认点: match['确认点'],
              终审注册状态: match['终审注册状态']
            }
          } : { found: false, reason: '该身份证号不在库中' }
        }));
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
