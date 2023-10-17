// https://bitbucket.org/comicapro/comic-editor/src/main/Comics.Web/Areas/Api/TokenAuthorizeAttribute.cs про токены


console.log(1)

const authorizationHeader = req.headers.authorization;
const token = authorizationHeader.match(/Mahabharata\s+(\w+)/);
//console.log(token);
if (token) {
  const extractedToken = token[1]; // Здесь будет ваш токен
  console.log(extractedToken);
} else {
  console.log('Токен не найден в заголовке Authorization.');
}



    //responseData='{"data":{"token":"c5b399842daf49f7bea337f42b889a3e"}}';
    responseData='{"data":{"token":"c5b399842daf49f7bea337f42b88ffff"}}';
    // Отправляем ответ клиенту
