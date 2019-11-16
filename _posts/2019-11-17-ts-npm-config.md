---
title: The in-depth guide to configuring TypeScript NPM packages
description: Configuration is hard to get right. This article discusses configuration options, lists alternative possibilities, and shares some common pitfalls and lessons learned the hard way.
---

When working on a Web project, I find it to be *really hard* to get the tooling configuration right: there are so many tools doing different things, so many options and alternatives to choose from, and oh-so-many ways that things can go wrong. This article is meant as an in-depth, step-by-step guide to a configuration that works really well.

Configuration is a matter of both personal taste and of the needs of the project. The setup that I will show won't work for everybody, and that's fine! That is exactly the reason I wrote this article. Rather than just make a GitHub repo of my arbitrary choices, I wanted to write about the reasoning leading this configuration, discuss alternative options, show some common pitfalls, and share lessons learned the hard way from working on [HashML](https://github.com/hashml/hashml), over the summer.

<!-- More -->

Still, If you'd just like to see the resulting code, I did also make [a GitHub repo](https://github.com/MaximeKjaer/npm-ts-template).

* TOC
{:toc}

## Guiding principles
We should always choose tools that (1) do something we actually need, (2) are widely used and actively maintained, and (3) require the [least amount of configuration](https://en.wikipedia.org/wiki/Convention_over_configuration).

Things should work cross-platform, if possible. This means on any developer's machine (Linux, Windows or macOS), in any language (TypeScript or JavaScript) and in any runtime environment (Node.js or browsers).

Generally, we won't care too much about the size and number of `devDependencies`. These are only installed by contributors to the code, take a fraction of a second to install, and largely make up for it in gained productivity. 

However, we should care a lot about keeping few `dependencies`: these are also installed by projects depending on your code, not just by developers contributing to it. Having too many of these adds to your bundle size and [poses security risks](https://medium.com/intrinsic/common-node-js-attack-vectors-the-dangers-of-malicious-modules-863ae949e7e8).

Many development tools can be configured either with command line flags, or through a configuration file. A configuration file is always preferable, as it enables IDEs to pick up and understand the configuration options.

## Directory structure
We'll aim for the following directory structure:

```
├── dist/                <- Build output folder
|   └── ...
├── src/
|   ├── hello.ts         <- File containing our code
|   ├── index.ts
├── test/
|   └── hello.test.ts    <- Test of src/hello.ts
├── README.md
├── .gitignore
└── package.json
```

## Git
In this article, we'll use [GitHub](https://github.com/), but you could also use [GitLab](https://about.gitlab.com/) or [BitBucket](https://bitbucket.org/product), or whatever else your heart desires. We'll first create a new repo on GitHub by going to [this page](https://github.com/new): we can check the box to initialize the repo with a README, and select the Node `.gitignore`. Once the repo is created, we can grab the URL to clone it:

```console
$ git clone <REPO_URL>
$ cd <REPO_DIR>
```

With the repo on our machine, we can already make our first edit: we don't want to track the output of the build, so we can add `dist` to the `.gitignore`.

## Package manager
The most commonly used package managers are:

- [NPM](https://www.npmjs.com/get-npm)
- [Yarn](https://yarnpkg.com/lang/en/)

Yarn was created [by Facebook in 2016](https://blog.npmjs.org/post/151660845210/hello-yarn) to solve some of the problems that NPM had back then. Since then, NPM has adopted the technical changes that Yarn pioneered, and has achieved feature and performance parity; nowadays, there is [no good reason to pick Yarn anymore](https://iamturns.com/yarn-vs-npm-2018/). Instead, it is best to go for the more popular option, NPM. People are more likely to be familiar with it, which makes contributing easier.

## `package.json`
### Basics
Let's start by configuring the basics. We'll need to create a `package.json` file, which we can do by running:

```console
$ npm init
```

This will ask us a bunch of question, to which we can reply as follows:

- **Package name**: `my-package-name`
  
  This is the name that people will type when doing an `npm install` for our package. If you are publishing as an organization, you should name the package `@my-organization/my-package-name`.

- **Version**: `0.0.0`

  According to Semver 2.0.0, the [0.y.z versions are for the initial development phase](https://semver.org/#how-should-i-deal-with-revisions-in-the-0yz-initial-development-phase), which is probably the phase brand new modules are in.

- **Description**: `A short description of my package`
  
  This is used for `npm search`. Keep it short and sweet.

- **Entry point**: `dist/index.js`
  
  We'll be compiling to JavaScript files, in a folder named `dist`. The `index.js` file is the compiled version of the TypeScript "barrel" file, which we'll talk about in [the TypeScript section](#typescript).

- **Test command**: Let's leave this blank for now. We'll talk about this in the [section on testing](#testing). 

- **Author**: `Firstname Lastname <firstname.lastname@example.com>`
  
  The package registry uses this information to display a small badge with your name and picture on the package's page.
  
- **License**: `MIT`

  The default option is the ISC license, which is legally equivalent to MIT, but with a slightly shorter text. You can read more about different licenses on [choosealicense.com](https://choosealicense.com/).

This creates a very basic `package.json` file; we'll need to add a few fields to it.

### Publishing configuration
We'll be publishing the package publicly on [npmjs.com](https://www.npmjs.com/), but you could also [publish privately](https://docs.npmjs.com/creating-and-publishing-private-packages), or to [your own NPM registry](https://verdaccio.org/en/). To enable publishing publicly, we must add the following to `package.json`:

{% highlight json-doc linenos %}
{
  ...
  "publishConfig": {
    "access": "public"
  }
}
{% endhighlight %}

We also need to declare which files should be published in our package. While we only want source files on Git, we only want build output on NPM. There are two ways of stating which files should go on NPM:

- Blacklisting files through a `.npmignore` file, or
- whitelisting files through a `"files"` key in `package.json`. 

The blacklist approach takes more work and involves [security risks](https://medium.com/@jdxcode/for-the-love-of-god-dont-use-npmignore-f93c08909d8d), so we should always pick the whitelist approach for this. When writing this whitelist, we only need to list our `dist` folder, as all other files NPM needs are [automatically included](https://docs.npmjs.com/files/package.json#files).

{% highlight json-doc linenos %}
{
  ...
  "files": ["/dist"],
}
{% endhighlight %}

We prefix the path with `/` to make sure that we refer to the one at the root of the project. Otherwise, a folder named `./src/dist` would also be included.

### Scripts
NPM scripts allow us to abstract over the exact choice of tool, and provide simple commands for common tasks. To keep things standardized, organized and simple, we'll use [standard NPM task names](https://github.com/voorhoede/npm-style-guide#use-standard-script-names), [grouped by prefix](https://github.com/voorhoede/npm-style-guide#group-related-scripts-by-prefix) as folllows:

- `build`: build the production version of the project
  - `ts`: build TypeScript files
- `clean`: delete build artifacts
- `test`: run all tests
  - `format`: test for formatting errors
  - `lint`: test for linting errors
  - `package`: test for errors in `package.json`
  - `unit`: run unit tests
- `fix`: run all fixes
  - `format`: fix files for formatting errors
  - `lint`: fix files for linting errors

That way, if we want to fix formatting, we can run `npm run fix:format`. To run all fixes, we can run `npm run fix`. Having organized the scripts by prefix means that we can run all the scripts with the same prefix using [npm-run-all](https://www.npmjs.com/package/npm-run-all). With this tool, we can write shorter top-level scripts that do not need to be updated when subscripts are added; a small gain, but a welcome one.

```console
$ npm install --save-dev npm-run-all
```

A little catch when writing the `clean` script is that `rm -rf` won't work on Windows. To ensure that things work cross-platform, most UNIX commands have [Node module equivalents](https://github.com/voorhoede/npm-style-guide#use-npm-modules-for-system-tasks). So instead of `rm -rf`,  we can use the [rimraf package](https://www.npmjs.com/package/rimraf).


```console
$ npm install --save-dev rimraf
```

We can now write the following scripts field in `package.json`:

{% highlight json-doc linenos %}
{
  ...
  "scripts": {
    "build": "npm-run-all build:*",
    "build:ts": "",

    "clean": "rimraf dist",
    
    "test": "npm-run-all test:*",
    "test:format": "",
    "test:lint": "",
    "test:package": "",
    "test:unit": "",
        
    "fix": "npm-run-all fix:lint fix:format",
    "fix:format": "",
    "fix:lint": "",
        
    "preversion": "npm-run-all clean build test",
    "postversion": "git push && git push --tags"
  }
}
{% endhighlight %}

I've left some scripts empty for now, because we'll talk about each of them in more detail later on.

We use a [star notation](https://github.com/mysticatea/npm-run-all/blob/master/docs/npm-run-all.md#glob-like-pattern-matching-for-script-names) (e.g. `npm-run-all test:*`) for all top-level scripts, *except for* `fix`. For this script, it's very important that linting mistakes be fixed before formatting mistakes, as fixing linting mistakes may reintroduce formatting mistakes.

The `preversion` and `postversion` scripts say what should happen when we release a new version of our package using `npm version`. Before the version is updated (`preversion`), we want to make sure everything is fine by running a clean build and tests. If that works, the version number can be updated, and we push everything to GitHub (`postversion`).

### Additional information
We can put more information about the package in `package.json` by adding some [descriptive fields](https://docs.npmjs.com/files/package.json). This is useful for people searching for the package, and for the package to be displayed nicely on the package registry:

{% highlight json-doc linenos %}
{
  ...
  "repository": {
    "type": "git",
    "url": "git+https://github.com/GITHUB-USERNAME/REPO-NAME.git"
  },
  "homepage": "https://github.com/GITHUB-USERNAME/REPO-NAME#readme",
  "bugs": {
    "url": "https://github.com/GITHUB-USERNAME/REPO-NAME/issues"
  },
  "keywords": [
    "typescript",
    ...
  ]
}
{% endhighlight %}

## TypeScript
We'll be writing TypeScript code, so we must obviously install the TypeScript compiler:

```console
$ npm install --save-dev typescript
```

With TypeScript installed, we'll need to configure the build options for our project by defining a [`tsconfig.json` file](https://www.typescriptlang.org/docs/handbook/tsconfig-json.html). 

There's a small trick that comes into play at this point though: we will actually be defining two `tsconfig` files. The reason for this is that we don't want to output the compiled tests to the production build, but we still want the compiler options to apply to all files, including tests.

Therefore, the first file we define is `tsconfig.json`, as usual. This file holds all the compiler options, and applies to all TypeScript files, built or not. However, in this case, its sole purpose is to be picked up by the IDE (say, VS Code or IntelliJ). This allows the IDE to underline errors correctly across all files, built or not. 

{% highlight json linenos %}
{
  "compilerOptions": {
    "noEmit": true
    "target": "esnext",
    "module": "commonjs",
    "sourceMap": true,
    "declaration": true,
    "strict": true,
    "noUnusedLocals": true,
    "jsx": "react",
    "resolveJsonModule": true,
    "removeComments": true,
  },
  "include": [
    "src",
    "test"
  ]
}
{% endhighlight %}

The second file is `tsconfig.build.json`, which extends the base `tsconfig.json` to inherit all the same compiler options, but adds the build instructions.

{% highlight json linenos %}
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./dist",
    "noEmit": false
  },
  "include": ["src"]
}
{% endhighlight %}

Let's go a step back and discuss some of the options in `tsconfig.json`:

- `"noEmit": true`

  The goal of the `tsconfig.json` is not to emit files, but just to be picked up by the IDE. Setting this ensures that we don't accidentally compile with `tsconfig.json` instead of `tsconfig.build.json`, which overrides this option to `false`.

- `"module": "commonjs"`
  
  A long time ago, in a galaxy far, far away, opposing module systems fought a great big battle.

  CommonJS was the first module system, and was most widely used on Node.js. If you've ever written `const add = require('./add.js')` or `module.exports = { add }`, then that is CommonJS.

  CommonJS became popular, but had some drawbacks. Alternative proposals came up: AMD proposed better tree-shaking, UMD tried to bridge the gap between AMD and CommonJS, and eventually, ECMAScript proposed the ESM standard. This is the one where you write your imports as `import { add } from "./add"` and your exports as `export function add(a, b) { ... }`.

  In TypeScript, you can (and should) use the standard ESM syntax. But perhaps the users of your module are writing plain JavaScript with CommonJS (*gasp!* 😱). Long story short, you should just set this option to `"commonjs"` to make sure everybody can use your package, whether they're using TypeScript or JavaScript, and are targeting Node.js or the Web.

- `"declaration": true`

  Since we're emitting and distributing plain JavaScript code, we also need to emit the TypeScript `.d.ts` declaration files for TypeScript users.

- `"sourceMap": true`
  
  This is useful for debugging. However, seeing that we're not distributing `.ts` source files, the source maps should not be distributed either, as they would point to a source file that doesn't exist. We can exclude them from the distribution by adding `"!/dist/**/*.js.map"` to the `"files"` key of `package.json`.

- `"resolveJsonModule": true`
  
  This allows you to `import` JSON files, which can be convenient. But watch out with this feature, there's a trap!
  
  Say you want to `import { version } from '../package.json'`. Seeing that TypeScript needs to place the imported JSON file in `dist`, it will now have to place `dist/index.js` in `dist/src/index.js` to make this relative import possible. Doing so makes the entry point [we defined earlier](#basics) invalid.
  
  The [pkg-ok](https://www.npmjs.com/package/pkg-ok) package can help us catch this type of error: it checks that the build actually matches the information in `package.json`. We can add this as an NPM script, which we'll name `test:package`. If the structure of `dist` changes, this will come up as an error during tests.

  ```console
  $ npm install --save-dev pkg-ok
  ```

Phew, that's quite a few decisions! But with all this in place, we can finally write our contribution to the world, in `src/hello.ts`:

{% highlight ts linenos %}
export function hello(): string {
  return "hello world";
}
{% endhighlight %}

People using the package should be able to `import { hello } from "my-package-name"`. But as things currently stand, we need to do `import { hello } from "my-package-name/hello"`, which is not as pretty. To fix this, we need to write a so-called "[barrel](https://basarat.gitbooks.io/typescript/docs/tips/barrel.html)". This is a file called `src/index.ts` that re-exports everything at the top scope:

{% highlight ts linenos %}
export * from "./hello";
{% endhighlight %}

## Testing
Having written this hello world function, we'd like to test if it actually greets us properly. The most popular JS test frameworks are:

- [Jest](https://jestjs.io/)
- [Mocha](https://mochajs.org/)
- [Jasmine](https://jasmine.github.io/)

Jest seems to be slightly more popular than Mocha and Jasmine nowadays. Generally, Jest comes with more things built in (an assertion library, code coverage, snapshot testing, ...), but they all require the same amount of setup to work with TypeScript. 

They're all great libraries, so it doesn't really matter which one you choose. I'll pick Mocha here, just for the sake of choosing one of them.

```console
$ npm install --save-dev mocha
```

### Testing with TypeScript
Since we're writing our code in TypeScript, it makes a lot of sense to also write the tests in TypeScript. We'll need the Mocha type definitions for this:

```console
$ npm install --save-dev @types/mocha
```

But we're not interested in producing a compiled version of our tests: we just want to run them. For this, we can use [ts-node](https://github.com/TypeStrong/ts-node), a wrapper around Node that allows us to run TypeScript files directly.

```console
$ npm install --save-dev ts-node
```

### Configuring the tests
Since Mocha 6.0.0, we can configure the tests with a `.mocharc.json` file:

{% highlight json-doc linenos %}
{
    "require": "ts-node/register",
    "spec": "test/**/*.test.ts",
    "watch-extensions": "ts"
}
{% endhighlight %}

We can now add the unit test script to `package.json`:

{% highlight json-doc linenos %}
{
  ...
  "scripts": {
    ...
    "test:unit": "mocha"
  }
}
{% endhighlight %}

That's all there is to it!

### Assertion library
Out of the box, we can use [Node's assertion module](https://nodejs.org/api/assert.html). However, seeing that this API easily gets a little limited, Mocha [supports and encourages](https://mochajs.org/#assertions) using *assertion libraries*, which offer different API styles:

{% highlight ts linenos %}
// Should style:
foo.should.equal('bar');

// Expect style:
expect(foo).to.equal('bar');

// Assert style:
assert.equal(foo, 'bar');
{% endhighlight %}

I find the first two to be cute, but at the end of the day, it makes more sense to me to write plain assertions. Yes, they're boring. But we don't write normal code as English sentences either, so why should our tests be written in a different style? Choosing normal assertions over an arbitrary DSL makes it one less thing to learn for your contributors, so I find that to be a nicer choice.

The most complete assertion library is Chai. It includes the plain and boring assert style assertions, so we'll use that:

```console
$ npm install --save-dev chai @types/chai
```

### Putting it all together
If we want to test a certain part of our code, we just need to create a `test/hello.test.ts` file:

{% highlight ts linenos %}
import { assert } from "chai";
import { hello } from "../src";

describe("hello", () => {
  it("says hello", () => {
    assert.strictEqual(hello(), "hello world");
  });
});
{% endhighlight %}

## Formatting
We now have code, and we have tests for it, so it may even be correct code. But is it pretty code? To help us with that, we can use a formatter. The most popular options seem to be:

- [ESLint](https://eslint.org/)
- [Standard JS](https://standardjs.com/)
- [Prettier](https://prettier.io/)

ESLint is a bit of a workhorse. Its name suggest that it's just for linting, but it also has support for formatting options. *Everything* is configurable in ESLint. Really, I counted 290 rules on [the rules list](https://eslint.org/docs/rules/)[^count]! 

[^count]: I took me an hour to count those by hand. Or perhaps I ran `document.querySelectorAll(".rule-list tr").length` in a console, who knows.

That might actually be too much. We can bikeshed on tabs vs spaces forever, but I learned to stop worrying and to love more opinionated formatters, like Standard JS or Prettier. They have sensible defaults, and [don't let you mess with things](https://standardjs.com/#i-disagree-with-rule-x-can-you-change-it) (or [not too much](https://prettier.io/docs/en/options.html), anyway). 

While Standard JS requires [some configuration](https://standardjs.com/#typescript) to work with TypeScript, Prettier works out of the box, so we'll use that.

```console
$ npm install --save-dev prettier
```

The only way to tell Prettier what to format is through the command line, so we'll add the formatting commands to the `package.json`:

{% highlight json-doc linenos %}
{
  ...
  "config": {
    "formatted": "**/*.{json,ts,tsx,js,jsx,yaml,yml}"
  },
  "scripts": {
    "test:formatting": "prettier --write $npm_package_config_formatted",
    "fix:formatting": "prettier --check $npm_package_config_formatted",
    ...
  }
}
{% endhighlight %}

The `"config"` field is a [small trick](https://docs.npmjs.com/files/package.json#config) that allows us to set variables in `package.json`. Using a variable here ensures that the formatting fix and check always run on the exact same files, and that we don't have to repeat the file glob.

To avoid formatting compiled files, we can add a `.prettierignore` file:

{% highlight text linenos %}
dist
{% endhighlight %}

## Linting
With compilation, testing and formatting in place, we have working, tested, pretty code. Still, some things could go wrong; we can still shoot ourselves in the foot (albeit with a lot of style). A linter can help avoid some simple anti-patterns, and enforce some code style rules. The popular linters for TypeScript are:

- [TSLint](https://palantir.github.io/tslint/)
- [ESLint](https://eslint.org/)

TSLint has long been the de-facto linter for TypeScript. However, the maintainers [are deprecating TSLint in 2019](https://github.com/palantir/tslint/issues/4534), and migrating all their linting rules to ESLint.

At the time of this writing, some of the rules we need the most are not yet available in ESLint, so we'll still use TSLint. However, we can take some solace in knowing that there is [a CLI tool](https://github.com/typescript-eslint/tslint-to-eslint-config) that migrates a TSLint setup to ESLint in a single command, so we can easily change this later.

```console
$ npm install --save-dev tslint
```

We can add TSLint as an NPM script by adding the following to `package.json`:

{% highlight json-doc linenos %}
{
  ...
  "scripts": {
    "test:lint": "tslint --project tsconfig.json",
    "fix:lint": "tslint --project tsconfig.json --fix",
    ...
  }
}
{% endhighlight %}

Some of the rules that TSLint can enforce may clash with Prettier. To avoid writing conflicting rules, we can use [tslint-config-prettier](https://www.npmjs.com/package/tslint-config-prettier), which disables all possibly problematic rules.

```console
$ npm install --save-dev tslint-config-prettier
```

We'll write our linting rules in a `tslint.json` file. Note that we must also reference `tslint-config-prettier` to disable bad rules.

{% highlight ts linenos %}
{
  "extends": ["tslint:recommended", "tslint-config-prettier"],
  "rules": {
    "member-access": [true, "no-public"],
    "interface-name": false,
    "no-default-export": true,
    "no-restricted-globals": true
  }
}
{% endhighlight %}

The first two rules disable some defaults that I do not find particularly useful. The next two rules are actually useful:

- `no-default-export`
  
  Using `default export` is problematic [for a number of reasons](https://humanwhocodes.com/blog/2019/01/stop-using-default-exports-javascript-module/), so we enforce the `no-default-export` rule to prevent it. This rule does not exist in ESLint yet, and is one of the reasons we're still using TSLint.

- `no-restricted-globals`
  
  For some variable names (`name`, `location` or `event`), using an undeclared variable type-checks in TypeScript (for historical reasons that have to do with early versions of Internet Explorer). Using the `no-restricted-globals` rule in TSLint can help catch these errors. 

## Continuous Integration
With Continuous Integration (CI), we can catch errors early by running all tests on every commit and PR. It's also quite convenient to have a service do deployments for us. Many CI providers exist:

- [Travis CI](https://travis-ci.org/)
- [Circle CI](https://circleci.com/)
- [AppVeyor](https://www.appveyor.com/)
- [GitLab CI](https://docs.gitlab.com/ee/ci/) (if using GitLab)

All of these are free for open source projects. There's not much difference between them, so for the sake of choosing one, we'll use Travis CI. 

We want the CI to run tests on every commit, and to do deployments to npmjs.com when we release a new version. To have it do that, we can add the following `.travis.yml` file:

{% highlight yml linenos %}
language: node_js
node_js:
- node # Use the latest stable release of node
cache:
  directories:
  - node_modules # Cache node_modules to speed up installation
notifications:
  email: false
script:
- npm run build
- npm run test
deploy:
- provider: npm
  skip_cleanup: true # Do not delete dist before deployment
  email: firstname.lastname@example.com # npmjs.com account email
  on:
    tags: true
    repo: GITHUB-USERNAME/REPO-NAME
{% endhighlight %}

The last thing we need to do is to add an encrypted access token so that Travis CI can deploy for us. The [Travis docs](https://docs.travis-ci.com/user/deployment/npm/#npm-auth-token) has us covered, and is worth a read if you're following along at home. We'll need to install and run the Travis CLI[^install-gem] to add an encrypted auth token to Travis:

[^install-gem]: The CLI is installed with the Ruby package manager, `gem`. This is indeed a little annoying if you don't have `gem` installed. You can run `sudo apt install rubygems` on Ubuntu, or if you're in a good mood, you can set up [rbenv](https://github.com/rbenv/rbenv), a Ruby version manager. If not, this might be enough reason to look into other CIs 🤷‍♂️

```console
$ gem install travis
$ travis encrypt YOUR_AUTH_TOKEN --add deploy.api_key
$ npm run fix:format  # reformat .travis.yml
```

## Conclusion
As you can see, this was all a lot of work, and we saw many examples of how things can go wrong. Hopefully, the configuration I showed can help you set up a stellar development environment from day 1, or at least save you some headaches down the road.

There's a [GitHub repo](https://github.com/MaximeKjaer/npm-ts-template) with all of the above code, and a few bonus explanations about small catches I encountered while coding it. It's a template repo, so you can generate a new repo with the same files and folders from it. Happy coding!
