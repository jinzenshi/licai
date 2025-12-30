// Vercel API 代理 - 解决百度OCR跨域问题

const API_KEY = process.env.BAIDU_API_KEY;
const SECRET_KEY = process.env.BAIDU_SECRET_KEY;

let accessToken = null;
let tokenTime = 0;
const TOKEN_EXPIRE = 25 * 24 * 60 * 60 * 1000; // 25天

// 获取token
async function getToken() {
  if (accessToken && Date.now() - tokenTime < TOKEN_EXPIRE) {
    return accessToken;
  }

  const response = await fetch(
    `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${API_KEY}&client_secret=${SECRET_KEY}`,
    { method: 'POST' }
  );

  const data = await response.json();
  if (data.error) {
    throw new Error(data.error_description || '获取token失败');
  }

  accessToken = data.access_token;
  tokenTime = Date.now();
  return accessToken;
}

export default async function handler(req, res) {
  // 设置CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { image } = req.body;

    if (!image) {
      return res.status(400).json({ error: '缺少图片数据' });
    }

    const token = await getToken();

    // 调用百度OCR
    const response = await fetch(
      `https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=${token}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({ image })
      }
    );

    const data = await response.json();

    if (data.error_code) {
      throw new Error(data.error_msg || 'OCR识别失败');
    }

    res.json(data);
  } catch (error) {
    console.error('OCR Error:', error);
    res.status(500).json({ error: error.message });
  }
}
