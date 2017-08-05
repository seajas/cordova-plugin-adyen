# Cordova Adyen Plugin

Minimal plugin providing access to the Adyen SDK. Only the 'quick integration' is supported. Only supported on iOS currently.

## Using

Install the plugin

    $ cordova plugin add https://github.com/seajas/cordova-plugin-adyen.git

`AdyenPlugin` is exposed with a single function, `present(scheme, function(token) { .. }) : Promise`. `scheme` should contain your app's custom URL. This is needed if you use payments which redirect to other apps or websites. `function(token) : Promise` should pass the `token` from the SDK to your backend and return the `payload` inside of a Promise.

Usage example

```js
AdyenPlugin.present('yourapp://', token => $http.get('/your-backend/setup', { "token": token, ... }))
  .then(payload => $http.get('/your-backend/verify', { "payload": payload }))
  .catch(err => /* handle error */);
```
