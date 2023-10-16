// Импортируйте библиотеку Express.js
const express = require('express');
const bodyParser = require('body-parser');
const fetch = require('node-fetch'); // Импортируем node-fetch


// Создайте экземпляр Express
const app = express();
const port = 80;

const translationRuData = require('./i18n/ru.json');
const translationHiData = require('./i18n/hi.json');
const translationThData = require('./i18n/th.json');

const seasonsData = require('./conf/data_s2.json');

function translate(data,translation)
{
  var translated = JSON.parse(JSON.stringify(data));  // Создаем копию входных данных, чтобы не изменять исходные данные
  for (var key in translated.data) {
    //console.log(key)
    season_id=translated.data[key].id
    console.log("season_id",season_id)

    if (translation.seasons.hasOwnProperty(season_id)) {
      console.log("original",translated.data[key].name)
      console.log("translated", translation.seasons[season_id])
      translated.data[key].name = translation.seasons[season_id];
    }

    for (var episode_key in translated.data[key].episodes) {
      episode_id=translated.data[key].episodes[episode_key].id
      console.log("--episode_id",episode_id)
      if (translation.episodes.hasOwnProperty(episode_id)) {
        console.log("--original",translated.data[key].episodes[episode_key].name)
        console.log("--translated", translation.episodes[episode_id])
        translated.data[key].episodes[episode_key].name = translation.episodes[episode_id];
      }
    }
  }

  return translated;
}

var seasonsRuData=translate(seasonsData,translationRuData);
var seasonsThData=translate(seasonsData,translationThData);
var seasonsHiData=translate(seasonsData,translationHiData);
//console.log(seasonsRuData)
//console.log(seasonsRuData.data[0].episodes)

// Парсинг JSON-тела запроса
app.use(bodyParser.json());

// Middleware для логирования запросов
app.use((req, res, next) => {
  console.log('Received a request:');
  console.log('HTTP Method:', req.method);
  console.log('Endpoint:', req.path);
  console.log('Headers:', req.headers);
  console.log('Request Body:', req.body);
  next();
});


// Обработчик для PUT /api/Auth/UpdateDevice
app.post('/api/Auth/UpdateDevice', async (req, res) => {
  // Отправка ответа
  try {

    console.log(1)
    req.headers["host"]="new.mbharata.com"
    //const response = await fetch('http://localhost:81/', {
    const response = await fetch('https://new.mbharata.com/api/Auth/UpdateDevice', {
      method: 'POST', // Используем метод POST
      headers: req.headers/*{
        'Content-Type': 'application/json',
        'Authorization': 'Mahabharata c5b399842daf49f7bea337f42b889a3e',
      }*/,
      body: JSON.stringify(req.body), // Передаем тело запроса
    });
   // Получаем ответ от сервера http://new.mbharata.com
    console.log(2)

    //const responseData = await response.json();
    const responseData = await response.text();


    console.log(3)
    console.log(responseData);

    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    
    // Отправляем ответ клиенту
    res.send(responseData);
    

    //res.json(responseData);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});


app.post('/api/Data/Seasons', async (req, res) => {
  // Отправка ответа
  try {

    console.log(1)
  /*
    req.headers["host"]="new.mbharata.com"
    //const response = await fetch('http://localhost:81/', {
    const response = await fetch('https://new.mbharata.com/api/Data/Seasons', {
      method: 'POST', // Используем метод POST
      headers: req.headers
      //{
      //  'Content-Type': 'application/json',
      //  'Authorization': 'Mahabharata c5b399842daf49f7bea337f42b889a3e',
      //}
      ,
      body: JSON.stringify(req.body), // Передаем тело запроса
    });
   // Получаем ответ от сервера http://new.mbharata.com
    console.log(2)

    //const responseData = await response.json();
    const responseData = await response.text();


    console.log(3)
    console.log(responseData);
*/

    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    
    // Отправляем ответ клиенту
    //res.send(responseData);
    if(req.headers["accept-language"]=="ru")
      res.send(seasonsRuData);
    else if(req.headers["accept-language"]=="th")
      res.send(seasonsThData);
    else if(req.headers["accept-language"]=="hi")
      res.send(seasonsHiData);
    else
      res.send(seasonsData);

    //res.json(responseData);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Обработчик для корневого маршрута "/"
app.get('/', (req, res) => {
  res.send('Hi node.js dev');
});

// Обработчик для корневого маршрута "/"
app.get('test', (req, res) => {
  res.send('test dev');
});

app.use((err, req, res, next) => {
  console.error('Bad Request:', err);
  res.status(400).send('Bad Request');
});

// Запуск сервера
app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
});
