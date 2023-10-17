const { PlatformTypes } = require('./IWS.Utils');

class DeviceInfo {
    constructor() {
        this.Platform = PlatformTypes.None;
        this.OsVersion = '';
        this.Model = '';
        this.AppId = '';
        this.AppVersion = '';
    }

    parseVersion() {
        const version = Version.parse(this.AppVersion);
        return version;
    }

    isValid() {
        return this.Platform !== PlatformTypes.None && this.OsVersion !== '' && this.Model !== '' && this.AppId !== '' && this.AppVersion !== '';
    }

    static create(userAgent) {
        const product = userAgent.find(x => x.Product !== null);
        const comment = userAgent.find(x => x.Comment !== null);
        if (!product || !comment) {
            return null;
        }

        const match = comment.match(/\((.+);\s(\w+)\s(.+)\)/);
        if (!match || match.length !== 4) {
            return null;
        }

        const device = new DeviceInfo();
        device.Model = match[1];
        device.OsVersion = match[3];
        device.AppId = product.Name;
        device.AppVersion = product.Version;

        const platform = PlatformTypes[match[2].toLowerCase()];
        device.Platform = platform !== undefined ? platform : PlatformTypes.None;

        return device.isValid() ? device : null;
    }
}

module.exports = DeviceInfo;