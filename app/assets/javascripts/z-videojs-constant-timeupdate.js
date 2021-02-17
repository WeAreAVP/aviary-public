/**
 * videojs-constant-timeupdate
 * @version 1.0.0
 * @copyright 2018 Arjun Ganesan <me@arjun-g.com>
 * @license MIT
 */
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory(require('./video')) :
	typeof define === 'function' && define.amd ? define(['./video'], factory) :
	(global.videojsConstantTimeupdate = factory(global.videojs));
}(this, (function (videojs) { 'use strict';

videojs = videojs && videojs.hasOwnProperty('default') ? videojs['default'] : videojs;

var version = "1.0.0";

var classCallCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
};











var inherits = function (subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function, not " + typeof superClass);
  }

  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      enumerable: false,
      writable: true,
      configurable: true
    }
  });
  if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass;
};











var possibleConstructorReturn = function (self, call) {
  if (!self) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }

  return call && (typeof call === "object" || typeof call === "function") ? call : self;
};

var Plugin = videojs.getPlugin('plugin');

var ConstantTimeupdatePlugin = function (_Plugin) {
	inherits(ConstantTimeupdatePlugin, _Plugin);

	function ConstantTimeupdatePlugin(player, options) {
		classCallCheck(this, ConstantTimeupdatePlugin);

		var _this = possibleConstructorReturn(this, _Plugin.call(this, player, options));

		var interval = options && options.interval || 1000;
		var roundFn = options && options.roundFn || Math.round;
		player.on('play', function () {
			clearInterval(_this.timeHandler);
			var currentTime = roundFn(player.currentTime());
			_this.timeHandler = setInterval(function () {
				currentTime = roundFn(player.currentTime());
				if (_this.lastTime !== currentTime) {
					player.trigger('constant-timeupdate', currentTime);
					_this.lastTime = currentTime;
				}
			}, interval);
			if (_this.lastTime !== currentTime) {
				player.trigger('constant-timeupdate', currentTime);
				_this.lastTime = currentTime;
			}
		});
		player.on('pause', function () {
			clearInterval(_this.timeHandler);
		});
		player.on('ended', function () {
			clearInterval(_this.timeHandler);
		});
		return _this;
	}

	return ConstantTimeupdatePlugin;
}(Plugin);

ConstantTimeupdatePlugin.VERSION = version;

var registerPlugin = videojs.registerPlugin || videojs.plugin;

registerPlugin('constantTimeupdate', ConstantTimeupdatePlugin);

return ConstantTimeupdatePlugin;

})));
