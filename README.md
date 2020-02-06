# Fumes

Fumes transpiles PaintCode's static objects into configurable views

## How it works

Fumes automatically parameterizes hard-coded elements like colors, using PaintCode's automatically generated code comments as naming guidelines. It also converts the resulting object from `NSObject` to `UIView`, and sets the hardcoded color values as defaults, while exposing properties for clients to customize.

## Usage

Copy the `fumes` binary to `usr/local/bin`

then specify source and target directories:

`fumes source_dir target_dir`

You may also specify a `--super SuperClass` for the finished code, or accept the default of `UIView`.

## Options


| Flag    |       | Description |
|:----------|:--------|:-------|
| `--input`	| `-i`   |	a path to get the .swift source code. You may also use the first argument.  |
| `--output`| `-o`	 |  a path to write the transpiled code You may also use the second argument.  |
| `--super`	|  `-c`  |	an optional superclass for the resulting class. UIView by default.  |
| `--help`	|  `-h`  |	                |



## Formatting Sketch Files

- Add a trailing underscore to groups or layers to indicate that they're private. These will be added to your private class extension, but not to the public one.
