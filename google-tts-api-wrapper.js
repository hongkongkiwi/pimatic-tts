var Speaker = require('speaker');
var lame = require('lame');
var request = require("request");
var platform = process.platform;
var isWin32 = (platform == "win32");
var Promise = require('bluebird');
var googleTTS = require('google-tts-api');

module.exports = function(text,language,speed) {
	return googleTTS(text,language,speed)
	.then(function (url) {
		return new Promise(function(resolve, reject) {
			var r = request({uri:url});
			var length = 5000;
			var timer;
			var decoder = new lame.Decoder();
			var speaker = new Speaker();

			r.on('complete', function(e) {
				length = e.socket.bytesRead/2;
				if(isWin32) {
					timer = setTimeout(function() {
						speaker.close();
						resolve();
					}, length);
				}
			});

			speaker.on("close", function() {
				decoder = null;
				resolve();
			});

			r.pipe(decoder).pipe(speaker);
		});
	});
}
