const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = process.env.PORT || 3000; // Порт, на котором будет работать сервер

// Middleware для парсинга JSON и логгирования запросов
app.use(bodyParser.json());

app.use((req, res, next) => {
  console.log('Received Request:');
  console.log('HTTP метод:', req.method);
  console.log('Эндпоинт:', req.url);
  console.log('Заголовки запроса:', req.headers);
  if (req.method === 'PUT') {
    console.log('Тело запроса:', req.body);
  }
  next();
});

// Эндпоинт PUT /api/Auth/UpdateDevice
app.put('/api/Auth/UpdateDevice', (req, res) => {
  if (req.get('Accept-Language') === 'en' && req.is('application/json')) {
    res.status(200).json({ "status": "ok" });
  } else {
    res.status(400).send("Bad Request");
  }
});

// Эндпоинт GET /
app.get('/', (req, res) => {
  res.send("Hi");
});

// Запуск сервера
app.listen(port, '0.0.0.0', () => {
  console.log(`Сервер запущен на порту ${port}`);
});
