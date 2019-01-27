global.SupercondActor_HostedScript_a34efe7d1bf2496fa15560fb788db7f4 = async function (_SupercondActor_Request, _SupercondActor_Response) {
    //[ExternalScript]
};

global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4 = {};

global._SupercondActor = {
    Logger: {
        logVerbose: function (arg) {
            global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.LogVerbose(arg, function (error, result) { if (error) throw error; });
        },
        logInfo: function (arg) {
            global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.LogInfo(arg, function (error, result) { if (error) throw error; });
        },
        logWarning: function (arg) {
            global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.LogWarning(arg, function (error, result) { if (error) throw error; });
        },
        logError: function (arg) {
            global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.LogError(arg, function (error, result) { if (error) throw error; });
        }
    },
    Context: {
        saveLocalStateAsync: function (key, value) {
            return new Promise(function (resolve, reject) {
                try {
                    let json = value === null ? null : JSON.stringify(value);
                    let dictKey = !key ? '' : '' + key;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.SaveState({ key: dictKey, value: json }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = result === null ? null : JSON.parse(result);
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
        },
        getLocalStateAsync: function (key) {
            return new Promise(function (resolve, reject) {
                try {
                    let dictKey = !key ? '' : '' + key;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.GetState(dictKey, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = result === null ? null : JSON.parse(result);
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
        },
        getLocalStateKeysAsync: function () {
            return new Promise(function (resolve, reject) {
                try {
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.GetStateKeys('', function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = result === null ? null : JSON.parse(result);
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
        },
        getServiceDescriptorAsync: function () {
            return new Promise(function (resolve, reject) {
                try {
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.GetServiceDescriptor('', function (error, result) {
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
        },
        getApiServicesAsync: function (appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    let appUrlStr = !appUrl ? '' : '' + appUrl;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.GetApiServices({ appUrl: appUrlStr }, function (error, result) {
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
        },
        getLongRunningServicesAsync: function (appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    let appUrlStr = !appUrl ? '' : '' + appUrl;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.GetLongRunningServices({ appUrl: appUrlStr }, function (error, result) {
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
        },
        getScheduledServicesAsync: function (appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    let appUrlStr = !appUrl ? '' : '' + appUrl;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.GetScheduledServices({ appUrl: appUrlStr }, function (error, result) {
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
        },
        createOrUpdateApiServiceAsync: function (serviceConfig, appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    if (!serviceConfig) {
                        reject('createOrUpdateApiServiceAsync: serviceConfig must be provided');
                        return;
                    }
                    let appUrlStr = !appUrl ? '' : '' + appUrl;
                    let serviceConfigJson = JSON.stringify(serviceConfig);
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.CreateOrUpdateApiService({ appUrl: appUrlStr, serviceConfig: serviceConfigJson }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = !result ? null : '' + result;
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
        },
        createOrUpdateLongRunningServiceAsync: function (serviceConfig, appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    if (!serviceConfig) {
                        reject('createOrUpdateLongRunningServiceAsync: serviceConfig must be provided');
                        return;
                    }
                    let appUrlStr = !appUrl ? '' : '' + appUrl;
                    let serviceConfigJson = JSON.stringify(serviceConfig);
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.CreateOrUpdateLongRunningService({ appUrl: appUrlStr, serviceConfig: serviceConfigJson }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = !result ? null : '' + result;
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
        },
        createOrUpdateScheduledServiceAsync: function (serviceConfig, appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    if (!serviceConfig) {
                        reject('createOrUpdateScheduledActorAsync: serviceConfig must be provided');
                        return;
                    }
                    let appUrlStr = !appUrl ? '' : '' + appUrl;
                    let serviceConfigJson = JSON.stringify(serviceConfig);
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.CreateOrUpdateScheduledService({ appUrl: appUrlStr, serviceConfig: serviceConfigJson }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = !result ? null : '' + result;
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
        },
        deleteServiceAsync: function (serviceID, appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    if (!serviceID) {
                        reject('deleteServiceAsync: serviceID must be provided');
                        return;
                    }
                    let appUrlStr = !appUrl ? '' : '' + appUrl;
                    let serviceIDStr = '' + serviceID;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.DeleteService({ appUrl: appUrlStr, serviceID: serviceIDStr }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = !result ? null : '' + result;
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
        },
        callScheduledServiceAsync: function (serviceID, paramObj, appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    if (!serviceID) {
                        reject('callScheduledActorAsync: serviceID must be provided');
                        return;
                    }
                    let paramJson = '';
                    if (typeof paramObj !== "undefined") {
                        paramJson = JSON.stringify(paramObj);
                    }
                    let appUrlStr = !appUrl ? '' : '' + appUrl;
                    let serviceIDStr = '' + serviceID;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.CallScheduledService({ appUrl: appUrlStr, serviceID: serviceIDStr, paramJson: paramJson }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = result === null ? null : JSON.parse(result);
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
        },
        createApplicationAsync: function (appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    if (!appUrl) {
                        reject('createApplicationAsync: appUrl must be provided');
                        return;
                    }
                    let appUrlStr = '' + appUrl;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.CreateApplication({ appUrl: appUrlStr }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = !result ? null : '' + result;
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
        },
        deleteApplicationAsync: function (appUrl) {
            return new Promise(function (resolve, reject) {
                try {
                    if (!appUrl) {
                        reject('deleteServiceAsync: appUrl must be provided');
                        return;
                    }
                    let appUrlStr = '' + appUrl;
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.DeleteApplication({ appUrl: appUrlStr }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = !result ? null : '' + result;
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
    },
    Config: {
        getSecretsFromVaultAsync: function (vaultUrl, keys) {
            return new Promise(function (resolve, reject) {
                try {
                    if (!vaultUrl) {
                        reject('getSecretsFromVaultAsync: vaultUrl must be provided');
                        return;
                    }
                    if (!keys) {
                        reject('getSecretsFromVaultAsync: keys must be provided');
                        return;
                    }

                    let keysStr = JSON.stringify(keys);

                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.ReadSecretsFromVault({ vaultUrl: vaultUrl, keys: keysStr }, function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = result === null ? null : JSON.parse(result);
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
        },
        getApiAuthConfigurationAsync: function () {
            return new Promise(function (resolve, reject) {
                try {
                    global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4.GetApiAuthConfiguration('', function (error, result) {
                        if (error) {
                            reject(error);
                        }
                        else {
                            try {
                                let resObj = result === null ? null : JSON.parse(result);
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
};

console.assert = function () {
    if (arguments.length <= 0 || !!arguments[0]) {
        return;
    }
    var args = [];
    for (var i = 1; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    var trace = (new Error()).stack.substr(5);
    trace = trace.substring(trace.indexOf("\n", trace.indexOf("\n") + 1) + 1);
    args.push('Trace:\n' + trace);
    global._SupercondActor.Logger.LogWarning(args);
};
console.debug = function () {
    var args = [];
    for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    global._SupercondActor.Logger.logVerbose(args);
};
console.error = function () {
    var args = [];
    for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    global._SupercondActor.Logger.logError(args);
};
console.exception = function () {
    var args = [];
    for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    global._SupercondActor.Logger.logError(args);
};
console.info = function () {
    var args = [];
    for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    global._SupercondActor.Logger.logInfo(args);
};
console.log = function () {
    var args = [];
    for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    global._SupercondActor.Logger.logInfo(args);
};
console.trace = function () {
    var args = [];
    for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    var trace = (new Error()).stack;
    trace = trace.substring(trace.indexOf("\n", trace.indexOf("\n") + 1) + 1);
    args.push('Trace:\n' + trace);
    global._SupercondActor.Logger.logInfo(args);
};
console.warn = function () {
    var args = [];
    for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
    }
    global._SupercondActor.Logger.logWarning(args);
};

function _SupercondActor_Response_a34efe7d1bf2496fa15560fb788db7f4() {
    this.body = null;
    this.contentType = 'application/json';
    this.statusCode = 200;
    this._headers = [];
    this._cookies = [];
    this.setHeader = function (key, value) {
        value = value || '';
        if (!Array.isArray(value)) {
            value = [value];
        }
        this._headers.push({ key: key, value: value });
    };
    this.setCookie = function (key, value, options) {
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
    };
}

return async function (execObj, cb) {
    try {
        global.hostFunctions_a34efe7d1bf2496fa15560fb788db7f4 = execObj.hostFunctions;

        let _SupercondActor_Response = new _SupercondActor_Response_a34efe7d1bf2496fa15560fb788db7f4();

        let result = await global.SupercondActor_HostedScript_a34efe7d1bf2496fa15560fb788db7f4(execObj.request, _SupercondActor_Response);

        let response = null;
        if (result === _SupercondActor_Response) {
            response = result;
        }
        else {
            response = Object.assign({}, _SupercondActor_Response);
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