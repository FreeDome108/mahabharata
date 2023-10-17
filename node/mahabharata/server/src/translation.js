const translationRuData = require('../i18n/ru.json');
const translationHiData = require('../i18n/hi.json');
const translationThData = require('../i18n/th.json');

//const seasonsData = require('../seasons/example_3seasons.json');
const seasonsData = require('../seasons/app.json');


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

module.exports = {
  seasonsData:{
        "en":seasonsData,
        "ru":seasonsRuData,
        "th":seasonsThData,
        "hi":seasonsHiData,
    }
};