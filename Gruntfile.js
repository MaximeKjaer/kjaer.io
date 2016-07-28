module.exports = function(grunt) {
	grunt.loadNpmTasks('grunt-postcss');
	grunt.loadNpmTasks('grunt-responsive-images');

	// Read what image breakpoints have been specified in _config.yml
	var breakpoints = grunt.file.readYAML('_config.yml').hero.breakpoints;
	var sizes = [];
	for (i = 0; i < breakpoints.length; i++)
		sizes.push({width: breakpoints[i],
					name: breakpoints[i]});

	grunt.initConfig({
		postcss: {
			options: {
				map: false,
				processors: [
					require('autoprefixer')({
						browsers: ['last 2 versions']
					})
				]
			},
			dist: {
				src: '_site/css/*.css'
			}
		},

		responsive_images: {
			dist: {
				options: {
					sizes: sizes,
					quality: 80
				},
				files: [{
					expand: true,
					src: ['images/hero/**.{jpg,gif,png}'],
					cwd: '_site/',
					dest: '_site/'
				}]
			}
		}
	});


	grunt.registerTask('build', ['postcss:dist', 'responsive_images:dist']);

};
