const translations = require('../src/translation.js');


authUpdateDevice = async (req, res) => {

    //console.log(req.body.deviceId)

    const authorizationHeader = req.headers.authorization;
    const token = authorizationHeader.match(/Mahabharata\s+(\w+)/);
    //console.log(token);
    if (token) {
        const extractedToken = token[1]; // Здесь будет ваш токен
        console.log(extractedToken);

        responseData = `{"data":{"token":"${extractedToken}"}}`;
        //responseData = '{"data":{"token":"c5b399842daf49f7bea337f42b889a3e"}}';
        
        res.send(responseData);

    } else {
        console.log('Токен не найден в заголовке Authorization.');
        const deviceId=req.body.deviceId;
        responseData = `{"data":{"token":"${deviceId}"}}`;
        //responseData = '{"data":{"token":"c5b399842daf49f7bea337f42b889a3e"}}';
        
        res.send(responseData);
    }


    //responseData = '{"data":{"token":"c5b399842daf49f7bea337f42b889a3e"}}';
    //responseData='{"data":{"token":"c5b399842daf49f7bea337f42b88ffff"}}';
    //res.send(responseData);
}


dataSeasons = async (req, res) => {

    var lang = req.headers["accept-language"];
    if (!(lang in translations.seasonsData)) lang = "en";

    res.send(translations.seasonsData[lang]);
}

module.exports = {
    authUpdateDevice,
    dataSeasons
};