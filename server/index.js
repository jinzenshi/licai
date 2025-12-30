// Render Node.js 服务器
const http = require('http');
const fs = require('fs');
const path = require('path');

// 豆包API配置
const DOUBAO_API_KEY = process.env.DOUBAO_API_KEY;
const DOUBAO_ENDPOINT = 'https://ark.cn-beijing.volces.com/api/v3/chat/completions';
const DOUBAO_MODEL = 'doubao-seed-1-6-flash-250828';

const PORT = process.env.PORT || 3000;

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

  // OCR API - 豆包模型
  if (req.method === 'POST' && req.url === '/api/ocr') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', async () => {
      try {
        const { image } = JSON.parse(body);
        if (!image) throw new Error('缺少图片数据');

        // 调用豆包API
        const response = await fetch(DOUBAO_ENDPOINT, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${DOUBAO_API_KEY}`
          },
          body: JSON.stringify({
            model: DOUBAO_MODEL,
            messages: [
              {
                role: 'user',
                content: [
                  {
                    type: 'image_url',
                    image_url: { url: `data:image/jpeg;base64,${image}` }
                  },
                  {
                    type: 'text',
                    text: '请从图片中提取以下信息，按JSON格式返回：{"idNumber":"身份证号","qualificationType":"资格种类(如高级中学)","subject":"任教学科"}。如果某项未识别到，设为空字符串。只返回JSON，不要其他文字。'
                  }
                ]
              }
            ]
          })
        });

        const data = await response.json();

        if (data.error) {
          throw new Error(data.error.message || 'OCR识别失败');
        }

        // 解析豆包返回的JSON
        const content = data.choices?.[0]?.message?.content || '';
        let ocrResult;

        try {
          // 尝试解析JSON
          const jsonMatch = content.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            ocrResult = JSON.parse(jsonMatch[0]);
          } else {
            throw new Error('无法解析返回内容');
          }
        } catch (e) {
          // 如果JSON解析失败，返回原始文本作为rawText
          ocrResult = {
            rawText: content,
            idNumber: '',
            qualificationType: '',
            subject: ''
          };
        }

        // 转换为兼容格式
        const result = {
          words_result: ocrResult.rawText ? ocrResult.rawText.split('\n').map(w => ({ words: w })) : [],
          extracted: {
            idNumber: ocrResult.idNumber || '',
            qualificationType: ocrResult.qualificationType || '',
            subject: ocrResult.subject || ''
          }
        };

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
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
