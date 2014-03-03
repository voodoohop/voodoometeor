Package.describe({ summary: 'Bootstrap 3, with Less files (v3.0.3).' });

Package.on_use(function (api) {
	api.use('jquery', 'client');
	api.use('less', 'client');

	// javascript

    api.add_files('lib/js/bootstrap.js', 'client');

	// fonts
    api.add_files('lib/fonts/glyphicons-halflings-regular.eot', 'client');
    api.add_files('lib/fonts/glyphicons-halflings-regular.svg', 'client');
    api.add_files('lib/fonts/glyphicons-halflings-regular.ttf', 'client');
    api.add_files('lib/fonts/glyphicons-halflings-regular.woff', 'client');
});
