class SupercondActor_Service_a34efe7d1bf2496fa15560fb788db7f4 {
    constructor(hostFunctions) {
        this._hostFunctions = hostFunctions;
    }

    saveLocalStateAsync(key, value) {
        let paramsObj = {
            key: !key ? '' : '' + key,
            value: value === null ? null : JSON.stringify(value)
        };
        return this._callFunc(paramsObj, this._hostFunctions.SaveState);
    }

    getLocalStateAsync(key) {
        let dictKey = !key ? '' : '' + key;
        return this._callFunc(dictKey, this._hostFunctions.GetState);
    }

    getLocalStateKeysAsync() {
        return this._callFunc('', this._hostFunctions.GetStateKeys);
    }

    getServiceDescriptorAsync() {
        return this._callFunc('', this._hostFunctions.GetServiceDescriptor);
    }

    getApiServicesAsync(appUrl) {
        let paramsObj = {
            appUrl: !appUrl ? '' : '' + appUrl
        };
        return this._callFunc(paramsObj, this._hostFunctions.GetApiServices);
    }

    getLongRunningServicesAsync(appUrl) {
        let paramsObj = {
            appUrl: !appUrl ? '' : '' + appUrl
        };
        return this._callFunc(paramsObj, this._hostFunctions.GetLongRunningServices);
    }

    getScheduledServicesAsync(appUrl) {
        let paramsObj = {
            appUrl: !appUrl ? '' : '' + appUrl
        };
        return this._callFunc(paramsObj, this._hostFunctions.GetScheduledServices);
    }

    createOrUpdateApiServiceAsync(serviceConfig, appUrl) {
        if (!serviceConfig) {
            return new Promise(function (resolve, reject) { reject('createOrUpdateApiServiceAsync: serviceConfig must be provided'); });
        }
        let paramsObj = {
            appUrl: !appUrl ? '' : '' + appUrl,
            serviceConfig: JSON.stringify(serviceConfig)
        };
        return this._callFunc(paramsObj, this._hostFunctions.CreateOrUpdateApiService, true);
    }

    createOrUpdateLongRunningServiceAsync(serviceConfig, appUrl) {
        if (!serviceConfig) {
            return new Promise(function (resolve, reject) { reject('createOrUpdateLongRunningServiceAsync: serviceConfig must be provided'); });
        }
        let paramsObj = {
            appUrl: !appUrl ? '' : '' + appUrl,
            serviceConfig: JSON.stringify(serviceConfig)
        };
        return this._callFunc(paramsObj, this._hostFunctions.CreateOrUpdateLongRunningService, true);
    }

    createOrUpdateScheduledServiceAsync(serviceConfig, appUrl) {
        if (!serviceConfig) {
            return new Promise(function (resolve, reject) { reject('createOrUpdateScheduledServiceAsync: serviceConfig must be provided'); });
        }
        let paramsObj = {
            appUrl: !appUrl ? '' : '' + appUrl,
            serviceConfig: JSON.stringify(serviceConfig)
        };
        return this._callFunc(paramsObj, this._hostFunctions.CreateOrUpdateScheduledService, true);
    }

    deleteServiceAsync(serviceID, appUrl) {
        if (!serviceID) {
            return new Promise(function (resolve, reject) { reject('deleteServiceAsync: serviceID must be provided'); });
        }
        let paramsObj = {
            appUrl: !appUrl ? '' : '' + appUrl,
            serviceID: '' + serviceID
        };
        return this._callFunc(paramsObj, this._hostFunctions.DeleteService, true);
    }

    callScheduledServiceAsync(serviceID, paramObj, appUrl) {
        if (!serviceID) {
            return new Promise(function (resolve, reject) { reject('callScheduledServiceAsync: serviceID must be provided'); });
        }
        let paramJson = '';
        if (typeof paramObj !== "undefined") {
            paramJson = JSON.stringify(paramObj);
        }
        let paramsObj = {
            appUrl: !appUrl ? '' : '' + appUrl,
            serviceID: '' + serviceID,
            paramJson: paramJson
        };
        return this._callFunc(paramsObj, this._hostFunctions.CallScheduledService);
    }

    getApplicationsAsync() {
        return this._callFunc('', this._hostFunctions.GetApplications);
    }

    createApplicationAsync(appUrl) {
        if (!appUrl) {
            return new Promise(function (resolve, reject) { reject('createApplicationAsync: appUrl must be provided'); });
        }
        let paramsObj = {
            appUrl: '' + appUrl
        };
        return this._callFunc(paramsObj, this._hostFunctions.CreateApplication, true);
    }

    deleteApplicationAsync(appUrl) {
        if (!appUrl) {
            return new Promise(function (resolve, reject) { reject('deleteApplicationAsync: appUrl must be provided'); });
        }
        let paramsObj = {
            appUrl: '' + appUrl
        };
        return this._callFunc(paramsObj, this._hostFunctions.DeleteApplication, true);
    }

    _callFunc(paramsObj, func, fromString) {
        return new Promise(function (resolve, reject) {
            try {
                func(paramsObj, function (error, result) {
                    if (error) {
                        reject(error);
                    }
                    else {
                        try {
                            let resObj = null;
                            if (fromString) {
                                resObj = typeof result !== "undefined" && result !== null ? '' + result : null;
                            }
                            else {
                                resObj = !result ? null : JSON.parse(result);
                            }
                            //let resObj = result === null ? null : JSON.parse(result);
                            resolve(resObj);
                        } catch (e) {
                            reject(e);
                        }
                    }
                });
            } catch (er) {
                reject(er);
            }
        });
    }
}

class SupercondActor_Config_a34efe7d1bf2496fa15560fb788db7f4 {
    constructor(hostFunctions) {
        this._hostFunctions = hostFunctions;
    }

    getSecretsFromVaultAsync(vaultUrl, keys) {
        if (!vaultUrl) {
            return new Promise(function (resolve, reject) { reject('getSecretsFromVaultAsync: vaultUrl must be provided'); });
        }
        if (!keys) {
            return new Promise(function (resolve, reject) { reject('getSecretsFromVaultAsync: keys must be provided'); });
        }

        let paramsObj = {
            vaultUrl: '' + vaultUrl,
            keys: JSON.stringify(keys)
        };
        return this._callFunc(paramsObj, this._hostFunctions.ReadSecretsFromVault);
    }

    getApiAuthConfigurationAsync() {
        return this._callFunc('', this._hostFunctions.GetApiAuthConfiguration);
    }

    _callFunc(paramsObj, func) {
        return new Promise(function (resolve, reject) {
            try {
                func(paramsObj, function (error, result) {
                    if (error) {
                        reject(error);
                    }
                    else {
                        try {
                            let resObj = !result ? null : JSON.parse(result);
                            resolve(resObj);
                        } catch (e) {
                            reject(e);
                        }
                    }
                });
            } catch (er) {
                reject(er);
            }
        });
    }
}

class SupercondActor_Logger_a34efe7d1bf2496fa15560fb788db7f4 {
    constructor(hostFunctions) {
        this._hostFunctions = hostFunctions;
    }

    logVerbose(...args) {
        this._hostFunctions.LogVerbose(args, function (error, result) { if (error) throw error; });
    }

    logInfo(...args) {
        this._hostFunctions.LogInfo(args, function (error, result) { if (error) throw error; });
    }

    logWarning(...args) {
        this._hostFunctions.LogWarning(args, function (error, result) { if (error) throw error; });
    }

    logError(...args) {
        this._hostFunctions.LogError(args, function (error, result) { if (error) throw error; });
    }
}

class SupercondActor_Context_a34efe7d1bf2496fa15560fb788db7f4 {
    constructor(hostFunctions) {
        this._config = new SupercondActor_Config_a34efe7d1bf2496fa15560fb788db7f4(hostFunctions);
        this._service = new SupercondActor_Service_a34efe7d1bf2496fa15560fb788db7f4(hostFunctions);
        this._logger = new SupercondActor_Logger_a34efe7d1bf2496fa15560fb788db7f4(hostFunctions);
    }

    get Config() {
        return this._config;
    }

    get Service() {
        return this._service;
    }

    get Logger() {
        return this._logger;
    }
}

class SupercondActor_Response_a34efe7d1bf2496fa15560fb788db7f4 {
    constructor() {
        this.body = null;
        this.contentType = 'application/json';
        this.statusCode = 200;
        this._headers = [];
        this._cookies = [];
    }

    setHeader(key, value) {
        value = value || '';
        if (!Array.isArray(value)) {
            value = [value];
        }
        this._headers.push({ key: key, value: value });
    }

    setCookie(key, value, options) {
        options = options || {};
        let cookie = {
            key: key,
            value: value,
            domain: options.domain || null,
            expires: options.expires || null,
            httpOnly: options.httpOnly || false,
            maxAge: options.maxAge || null,
            path: options.path || '/',
            secure: options.secure || false,
            signed: options.signed || false,
            sameSite: options.sameSite || null
        };
        this._cookies.push(cookie);
    }
}


// execObj:
//  hostFunctions
//  request
//  serviceScript
return async function (execObj, cb) {
    try {
        let AsyncFunction = Object.getPrototypeOf(async function () { }).constructor;

        let serviceScriptWrapperFunc =
            new AsyncFunction('_SupercondActor', '_SupercondActor_Request', '_SupercondActor_Response', execObj.serviceScript);

        let httpResponse = new SupercondActor_Response_a34efe7d1bf2496fa15560fb788db7f4();

        let context = new SupercondActor_Context_a34efe7d1bf2496fa15560fb788db7f4(execObj.hostFunctions);

        let result = await serviceScriptWrapperFunc(context, execObj.request, httpResponse);

        let response = null;
        if (result === httpResponse) {
            response = result;
        }
        else {
            response = Object.assign({}, httpResponse);
            response.body = result;
        }

        if (response.body === undefined) {
            response.body = null;
        }
        else if ((response.contentType || '').toLowerCase() === 'application/json' || !(typeof response.body === 'string' || response.body instanceof String)) {
            response.body = JSON.stringify(response.body);
        }

        cb(null, JSON.stringify(response));
    } catch (e) {
        cb(e, null);
    }
};