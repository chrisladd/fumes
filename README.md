# Fumes

![Fumes logo](../assets/fumes-logo.png?raw=true)

Fumes transpiles PaintCode's static objects into configurable views

## How it works

Fumes automatically parameterizes hard-coded elements like colors, using PaintCode's automatically generated code comments as naming guidelines. It also converts the resulting object from `NSObject` to `UIView`, and sets the hardcoded color values as defaults, while exposing properties for clients to customize.

## Installation

Download and build the project located at `mac-cli`--this will install the `fumes` executable to your `/usr/local/bin`.

Alternatively, you can copy the `fumes` binary from `bin/fumes` to `/usr/local/bin`

## Usage

Specify source and target files:

`fumes ./path/to/SourceFile.swift ./path/to/DestinationFile.swift`

## Options


| Flag    |       | Description |
|:----------|:--------|:-------|
| `--input`	| `-i`   |	a path to get the .swift source code. You may also use the first argument.  |
| `--output`| `-o`	 |  a path to write the transpiled code You may also use the second argument.  |
| `--super`	|  `-c`  |	an optional superclass for the resulting class. UIView by default.  |
| `--help`	|  `-h`  |	                |
| `--bg`  |  | a string to set the background UIColor for the view. `.clear` by default |


## Formatting Sketch Files

- Add a trailing underscore to groups or layers to indicate that they're private. These will be added to your private class extension, but not to the public one.
