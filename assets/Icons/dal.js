"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports["default"] = void 0;

var _react = _interopRequireDefault(require("react"));

var _propTypes = _interopRequireDefault(require("prop-types"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { "default": obj }; }

var DAL = function DAL(props) {
  var size = props.size;
  return /*#__PURE__*/_react["default"].createElement("svg", {
    width: size,
    height: size,
    preserveAspectRatio: "xMidYMid slice",
    clipRule: "evenodd",
    fillRule: "evenodd",
    strokeLinejoin: "round",
    strokeMiterlimit: "1.41421",
    viewBox: "0 0 560 400",
    xmlns: "http://www.w3.org/2000/svg"
  }, /*#__PURE__*/_react["default"].createElement("g", {
    fillRule: "nonzero",
    transform: "matrix(.628872 0 0 .628872 144.164 70.8008)"
  }, /*#__PURE__*/_react["default"].createElement("path", {
    d: "m216 1.282 132.674 408.328-347.344-252.36h429.34l-347.344 252.36z",
    fill: "#024"
  }), /*#__PURE__*/_react["default"].createElement("path", {
    d: "m216 38.987 110.511 340.119-289.322-210.205h357.622l-289.322 210.205z",
    fill: "#fff"
  }), /*#__PURE__*/_react["default"].createElement("path", {
    d: "m216 68.272 93.298 287.142-244.257-177.464h301.918l-244.257 177.464z",
    fill: "#024"
  })));
};

DAL.propTypes = {
  size: _propTypes["default"].oneOfType([_propTypes["default"].string, _propTypes["default"].number])
};
DAL.defaultProps = {
  size: '100'
};
var _default = DAL;
exports["default"] = _default;