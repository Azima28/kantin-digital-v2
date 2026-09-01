{{flutter_js}}
{{flutter_build_config}}

// Apply dynamic cache-busting versioning to main.dart.js entrypoint
if (typeof _flutter !== 'undefined' && _flutter.buildConfig && _flutter.buildConfig.builds) {
  var buildTimestamp = Date.now();
  for (var i = 0; i < _flutter.buildConfig.builds.length; i++) {
    var b = _flutter.buildConfig.builds[i];
    if (b.mainJsPath) {
      b.mainJsPath = b.mainJsPath + '?v=' + buildTimestamp;
    }
  }
}

_flutter.loader.load();
