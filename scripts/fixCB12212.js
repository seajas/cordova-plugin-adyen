var fs = require('fs');

var configFile = 'platforms/ios/cordova/build.xcconfig';
var text = fs.readFileSync(configFile, 'utf-8');

var index = text.search(/^\s?CODE_SIGN_ENTITLEMENTS/gm);

if (index != -1) {
    fs.writeFileSync(configFile, text.slice(0, index) + "// [Commented out to fix CB-12212] " + text.slice(index), 'utf-8');
}
