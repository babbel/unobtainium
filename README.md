# unobtainium
*Obtain the unobtainable: test code covering multiple platforms*

Unobtainium wraps [Selenium](https://github.com/SeleniumHQ/selenium) and
[Appium](https://github.com/appium/ruby_lib) in a simple driver abstraction
so that test code can more easily cover:

  - Desktop browsers
  - Mobile browsers
  - Mobile apps

Some additional useful functionality for the maintenance of test suites is
also added.

[![Gem Version](https://badge.fury.io/rb/unobtainium.svg)](https://badge.fury.io/rb/unobtainium)
[![Build status](https://travis-ci.org/jfinkhaeuser/unobtainium.svg?branch=master)](https://travis-ci.org/jfinkhaeuser/unobtainium)
[![Code Climate](https://codeclimate.com/github/jfinkhaeuser/unobtainium/badges/gpa.svg)](https://codeclimate.com/github/jfinkhaeuser/unobtainium)
[![Test Coverage](https://codeclimate.com/github/jfinkhaeuser/unobtainium/badges/coverage.svg)](https://codeclimate.com/github/jfinkhaeuser/unobtainium/coverage)

# Usage

You can use unobtainium on its own, or use it as part of a
[cucumber](https://cucumber.io/) test suite.

Unobtainium's functionality is in standalone classes, but it's all combined in
the `Unobtainium::World` module.

- The `PathedHash` class extends `Hash` by allowing paths to nested values, e.g.:
  ```ruby
  h = PathedHash.new { "foo" => { "bar" => 42 }}
  h["foo.bar"] == 42 # true
  ```

- The `Config` class is a `PathedHash`, but also reads JSON or YAML files to
  initialize itself with values. See the documentation on (configuration features)[docs/CONFIGURATION.md]
  for details
- The `Runtime` class is a singleton and a `Hash`-like container (but simpler),
  that destroys all of its contents at the end of a script, calling custom
  destructors if required. That allows for clean teardown and avoids everything
  to have to implement the Singleton pattern itself.
- The `Driver` class, of course, wraps either of Appium or Selenium drivers:
  ```ruby
  drv = Driver.create(:firefox) # uses Selenium
  drv = Driver.create(:android) # uses Appium

  drv.navigate.to "..." # delegates to Selenium or Appium
  ```

## World

The World module combines all of the above by providing a simple entry point
for everything:

- `World.config_file` can be set to the path of a config file to be loaded,
  defaulting to `config/config.yml`.
- `World#config` is a `Config` instance containing the above file's contents.
- `World#driver` returns a Driver, initialized to the settings contained in
  the configuration file.

For a simple usage example of the World module, see the [cuke](./cuke)
subdirectory (used with cucumber).

## Configuration File

The configuration file knows two configuration variables:

- `driver` is expected to be a string, specifying the driver to use as if it
  was passed to `Driver.create` (see above), e.g. "android", "chrome", etc.
- `drivers` (note the trailing s) is a Hash. Under each key you can nest an
  options hash you might otherwise pass to `Driver.create` as the second
  parameter.

# Credits
This gem is inspired by [LapisLazuli](https://github.com/spriteCloud/lapis-lazuli),
but vastly less complex, and aims to stay so.
