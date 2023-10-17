const mongoose = require('mongoose');
const { PlatformTypes } = require('./IWS.Utils');

const deviceSchema = new mongoose.Schema({
    _id: mongoose.Schema.Types.ObjectId,
    platform: {
        type: String,
        enum: Object.values(PlatformTypes),
        required: true
    },
    osVersion: {
        type: String,
        required: true,
        maxlength: 32
    },
    deviceId: {
        type: String,
        required: true,
        maxlength: 256
    },
    model: {
        type: String,
        required: true,
        maxlength: 256
    },
    appVersion: {
        type: String,
        required: true,
        maxlength: 32
    },
    timezoneOffset: {
        type: Number
    },
    culture: {
        type: String
    },
    pushToken: {
        type: String,
        maxlength: undefined
    },
    lastModified: {
        type: Date,
        default: Date.now
    }
});

const Device = mongoose.model('Device', deviceSchema);


const Device = require('./Device'); // Подключаем модель устройства

// Создание или обновление устройства
async function updateDevice(token, platform, osVersion, deviceId, deviceModel, appVersion, tzOffset, culture) {
    try {
        let device;

        if (token) {
            device = await Device.findById(token);
        }

        if (!device) {
            device = new Device({ _id: token || new mongoose.Types.ObjectId() });
        }

        device.platform = platform;
        device.osVersion = osVersion;
        device.deviceId = deviceId;
        device.model = deviceModel;
        device.appVersion = appVersion;
        device.timezoneOffset = tzOffset;
        device.culture = culture;
        device.lastModified = new Date();

        await device.save();
        return device;
    } catch (error) {
        // Обработка ошибки
        console.error(error);
    }
}

// Загрузка устройства по идентификатору
async function loadDeviceById(id) {
    try {
        return await Device.findById(id);
    } catch (error) {
        // Обработка ошибки
        console.error(error);
    }
}

// Загрузка устройств с установленным push-токеном
async function loadDevicesWithPushToken() {
    try {
        return await Device.find({ platform: { $ne: PlatformTypes.None }, pushToken: { $exists: true, $ne: null } });
    } catch (error) {
        // Обработка ошибки
        console.error(error);
    }
}

// Обновление push-токена устройства
async function updatePushToken(oldToken, newToken) {
    try {
        await Device.updateOne({ pushToken: oldToken }, { $set: { pushToken: newToken } });
    } catch (error) {
        // Обработка ошибки
        console.error(error);
    }
}

module.exports = {
    updateDevice,
    loadDeviceById,
    loadDevicesWithPushToken,
    updatePushToken,
};


module.exports = Device;

