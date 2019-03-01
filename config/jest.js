const { is_windows } = require("./os");

let testRegex = "/__tests__/.*spec.coffee$";
if (is_windows) {
  testRegex = "\\\\__tests__\\\\.*spec.coffee$";
}

module.exports = {
  testRegex,
  moduleFileExtensions: ["coffee", "js"],
  moduleDirectories: ["node_modules", "."],
  transform: {
    "^.+\\.coffee$": "<rootDir>/config/coffee-jest.js",
    "^.+\\.js$": "babel-jest",
    "^.+\\.pug$": "pug-jest",
    "^.+\\.vue$": "vue-jest"
  }
};
