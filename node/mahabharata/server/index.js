// Импортируйте библиотеку Express.js
const express = require('express');
const bodyParser = require('body-parser');



// Создайте экземпляр Express
const app = express();
const { config } = require('./conf/config.js');
const api = require('./src/api.js');
const apiProxy = require('./src/apiProxy.js');

// Парсинг JSON-тела запроса
app.use(bodyParser.json());

// Middleware для логирования запросов
app.use((req, res, next) => {
  try {
    console.log('eceived a request Endpoint:', req.path);
    if (config.debug == false) { next(); return; }

    console.log('HTTP Method:', req.method);
    console.log('Headers:', req.headers);
    console.log('Request Body:', req.body);
    next();
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});


app.post('/api/Auth/UpdateDevice', async (req, res) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  if (config.proxyApiURL != false) {
    await apiProxy.authUpdateDevice(config.proxyApiURL, req, res);
  } else {
    await api.authUpdateDevice(req, res);
  }
});


app.post('/api/Data/Seasons', async (req, res) => {
  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  if (config.proxyApiURL != false) { 
    await apiProxy.dataSeasons(config.proxyApiURL, req, res); 
  } else {
    await api.dataSeasons(req, res);
  }
});


// Обработчик для корневого маршрута "/"
app.get('/', (req, res) => {
  res.send('Hi! node.js');
});


app.get('test', (req, res) => {
  res.send('test');
});

app.get('/pub/health_check.php', (req, res) => {
  res.send('{test:ok}');
});



app.use((err, req, res, next) => {
  console.error('Bad Request:', err);
  res.status(400).send('Bad Request');
});

// Запуск сервера
app.listen(config.port, '0.0.0.0', () => {
  console.log(`Server is running on port ${config.port}`);
});

console.log(config)