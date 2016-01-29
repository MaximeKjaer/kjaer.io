module.exports = function(grunt) {
	grunt.loadNpmTasks('grunt-postcss');

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
		}
	});

	grunt.registerTask('build', ['postcss:dist']);
};
