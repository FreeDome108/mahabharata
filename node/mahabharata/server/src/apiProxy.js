const url = require('url');
const fetch = require('node-fetch'); // Импортируем node-fetch

function getHost(myurl) {
  const parsedUrl = new URL(myurl);
  const host = parsedUrl.host;
  return host;
}

authUpdateDevice = async (apiURL, req, res) => {
  var host = getHost(apiURL);
  req.headers["host"] = host;
  console.log(`Send proxy request to ${host} api:${apiURL}`);

  const response = await fetch(apiURL + 'api/Auth/UpdateDevice', {
    method: 'POST',
    headers: 
    req.headers,
    //{
    //  'Content-Type': 'application/json',
    //  'Authorization': 'Mahabharata c5b399842daf49f7bea337f42b889a3e',
    //},
    body: JSON.stringify(req.body), // Передаем тело запроса
  });
  // Получаем ответ от сервера http://new.mbharata.com



  const responseData = await response.text();
  console.log(responseData)
  res.send(responseData);
}

dataSeasons = async (apiURL, req, res) => {
  var host = getHost(apiURL);
  req.headers["host"] = host;
  console.log(`Send proxy request to ${host} api:${apiURL}`);

  const response = await fetch(apiURL + 'api/Data/Seasons', {
    method: 'POST', // Используем метод POST
    headers: 
    req.headers,
    //{
    //  'Content-Type': 'application/json',
    //  'Authorization': 'Mahabharata c5b399842daf49f7bea337f42b889a3e',
    //},
    
    body: JSON.stringify(req.body), // Передаем тело запроса
  });
  const responseData = await response.text();
  console.log(responseData);
  res.send(responseData);
}
 

module.exports = {
  authUpdateDevice,
  dataSeasons
};