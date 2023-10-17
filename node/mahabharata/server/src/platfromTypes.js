const PlatformTypes = {
    None: 0,
    Android: 1,
    iOS: 2,
    WindowsPhone: 3
};

const All = Object.values(PlatformTypes).filter((value) => value !== PlatformTypes.None);

module.exports = { PlatformTypes, All };