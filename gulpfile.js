const { parallel } = require("gulp");
const { src, dest } = require("gulp");
const autoprefixer = require("gulp-autoprefixer");
const brotli = require("gulp-brotli");
const changed = require("gulp-changed");
const del = require("del");
const filter = require("gulp-filter");
const git = require("gulp-git");
const imagemin = require("gulp-imagemin");
const merge = require("merge-stream");
const path = require("path");
const readYaml = require("read-yaml");
const rename = require("gulp-rename");
const responsive = require("gulp-responsive");
const webp = require("gulp-webp");
const zopfli = require("gulp-zopfli-green");

const config = readYaml.sync("_config.yml");

const paths = {
  images: {
    src: ["images/**/*.{png,jpg,jpeg,svg,gif}", "!images/hero/*"],
    dest: "_site/images/"
  },
  heroImages: {
    src: "images/hero/*.{png,jpg,jpeg,svg,gif}",
    dest: "_site/images/hero/"
  },
  css: {
    src: "_site/css/*.css",
    dest: "_site/css"
  },
  html: {
    src: "_site/**/*.{html,xml}",
    dest: "_site/"
  }
};

function clean() {
  return del(["_site"]);
}

function styles() {
  return modified(paths.css)
    .pipe(autoprefixer())
    .pipe(dest(paths.css.dest))
    .pipe(zopfli())
    .pipe(dest(paths.css.dest))
    .pipe(brotli.compress())
    .pipe(dest(paths.css.dest));
}

function html() {
  const modifiedExt = ext => modified(paths.html, transform(p => p + ext));
  const gz = modifiedExt(".gz").pipe(zopfli());
  const br = modifiedExt(".br").pipe(brotli.compress());
  return merge(gz, br).pipe(dest(paths.html.dest));
}

function heroImages() {
  const sizes = config.hero.breakpoints;
  const pipes = sizes.map(size => {
    return modified(paths.heroImages, transform(suffix(`-${size}`)))
      .pipe(
        responsive(
          {
            "*": {
              width: size,
              rename: { suffix: `-${size}` },
              withoutEnlargement: false
            }
          },
          {
            silent: true,
            errorOnUnusedConfig: false
          }
        )
      )
      .pipe(renameExt(".jpeg", ".jpg"))
      .pipe(imagemin())
      .pipe(dest(paths.heroImages.dest));
  });

  const fullSize = modified(paths.heroImages).pipe(imagemin());
  return (
    merge(fullSize, ...pipes)
      .pipe(changed(paths.heroImages.dest, transform(replaceExt(".webp"))))
      // .pipe(webp())
      .pipe(dest(paths.heroImages.dest))
  );
}

function images() {
  return (
    modified(paths.images)
      .pipe(imagemin())
      // .pipe(webp())
      .pipe(dest(paths.images.dest))
  );
}

// Utility functions
function renameExt(from, to) {
  return rename(path => {
    if (path.extname === from) path.extname = to;
  });
}

function modified(paths, changedOptions) {
  if (process.env.CI) {
    return src(paths.src);
    // return git
    //   .diff("master", { cwd: "_site", log: false })
    //   .pipe(filter(paths.src));
  } else {
    return src(paths.src).pipe(changed(paths.dest, changedOptions));
  }
}

// Utility functions for transformPath in gulp-changed:
function transform(transformPath) {
  return { transformPath };
}
function suffix(suff) {
  return p =>
    path.join(
      path.dirname(p),
      path.basename(p, path.extname(p)) + suff + path.extname(p)
    );
}
function replaceExt(ext) {
  return p =>
    path.join(path.dirname(p), path.basename(p, path.extname(p)) + ext);
}

exports.clean = clean;
exports.optimize = parallel(images, styles, html, heroImages);
exports.default = exports.build;
