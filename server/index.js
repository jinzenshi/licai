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

// 查询数据（匹配身份证号、资格种类、任教学科）
function queryData(idNumber, qualificationType, subject) {
  idNumber = idNumber.toUpperCase();
  const match = excelData.find(row => {
    const excelId = String(row['证件号码'] || '').trim().toUpperCase();
    return excelId === idNumber;
  });

  if (!match) return null; // 身份证号不在库中

  // 如果没有识别到资格种类和学科，直接返回匹配成功
  if (!qualificationType && !subject) return match;

  // 检查资格种类是否匹配（允许部分匹配）
  if (qualificationType) {
    const excelQual = match['资格种类'] || '';
    const isQualMatch = excelQual.includes(qualificationType) ||
                        qualificationType.includes(excelQual.replace('教师资格', '')) ||
                        qualificationType.includes(excelQual);
    if (!isQualMatch) {
      return { reason: `资格种类不匹配：库中为"${excelQual}"，识别为"${qualificationType}"` };
    }
  }

  // 检查任教学科是否匹配（允许部分匹配）
  if (subject) {
    const excelSubject = match['任教学科'] || '';
    const isSubjectMatch = excelSubject.includes(subject) || subject.includes(excelSubject);
    if (!isSubjectMatch) {
      return { reason: `任教学科不匹配：库中为"${excelSubject}"，识别为"${subject}"` };
    }
  }

  return match;
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

        // 调用豆包API（提取身份证号、资格种类、任教学科）
        const response = await fetch(DOUBAO_ENDPOINT, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${DOUBAO_API_KEY}`
          },
          body: JSON.stringify({
            model: DOUBAO_MODEL,
            max_tokens: 80,
            temperature: 0.1,
            messages: [
              {
                role: 'user',
                content: [
                  { type: 'image_url', image_url: { url: `data:image/jpeg;base64,${image}` } },
                  { type: 'text', text: '从图片提取信息，只返回JSON：{"idNumber":"身份证号18位","qualificationType":"资格种类(高级中学/中等职业学校/初级中学/小学/幼儿园)","subject":"任教学科(如语文/数学/英语等)"}。如果某项未识别到，值设为空字符串。只返回JSON。' }
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
        let ocrData = { idNumber: '', qualificationType: '', subject: '' };
        try {
          const jsonMatch = content.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            const parsed = JSON.parse(jsonMatch[0]);
            ocrData.idNumber = parsed.idNumber || '';
            ocrData.qualificationType = parsed.qualificationType || '';
            ocrData.subject = parsed.subject || '';
          } else {
            // 如果不是JSON，尝试提取身份证号
            const idMatch = content.match(/\d{17}[\dXx]/);
            ocrData.idNumber = idMatch ? idMatch[0] : '';
          }
        } catch (e) {
          // JSON解析失败，尝试提取身份证号
          const idMatch = content.match(/\d{17}[\dXx]/);
          ocrData.idNumber = idMatch ? idMatch[0] : '';
        }

        // 查询数据库（匹配身份证号、资格种类、任教学科）
        const match = queryData(ocrData.idNumber, ocrData.qualificationType, ocrData.subject);

        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          idNumber: ocrData.idNumber,
          qualificationType: ocrData.qualificationType,
          subject: ocrData.subject,
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
          } : match === null ? { found: false, reason: '该身份证号不在库中' } : { found: false, reason: match.reason }
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
