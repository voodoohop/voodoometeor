Package.describe({
  summary: "Reactive async pattern helper"
});

Package.on_use(function (api) {
  api.use([
    "deps",
    "underscore"
  ], "client");

  api.add_files([
    "reactive-async.js"
  ], "client");

  api.export("ReactiveAsync");
});