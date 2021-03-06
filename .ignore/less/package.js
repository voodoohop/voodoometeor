Package.describe({
  summary: "The dynamic stylesheet language"
});

Package._transitional_registerBuildPlugin({
  name: "compileLess",
  use: [],
  sources: [
    'plugin/compile-less.js'
  ],
  npmDependencies: {"less": "1.5.0"}
});

Package.on_test(function (api) {
  api.use(['test-helpers', 'tinytest', 'less']);
  api.use(['spark']);
  api.add_files(['less_tests.less', 'less_tests.js'], 'client');
});
