var exec = require('cordova/exec');

exports.present = (scheme, paymentData) => {
    return new Promise((resolve, reject) => {
        exec(resolve, reject, 'AdyenPlugin', 'initializeCheckout', [ scheme ]);
    })
    .then(token => paymentData(token))
    .then(payload => new Promise((resolve, reject) => {
        exec(resolve, reject, 'AdyenPlugin', 'supplyPaymentData', [ payload ]);
    }));
};
