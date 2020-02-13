# Fumes

![Fumes logo](../assets/fumes-logo.png?raw=true)

Fumes transpiles PaintCode's static objects into configurable views

## How it works

Fumes automatically parameterizes hard-coded elements like colors, using PaintCode's automatically generated code comments as naming guidelines. It also converts the resulting object from `NSObject` to `UIView`, and sets the hardcoded color values as defaults, while exposing properties for clients to customize.

## Installation

Can copy the `fumes` binary from `bin/fumes` to `/usr/local/bin`. 

This file is updated with each build, so you may modify the source code, rebuild, and find the updated version waiting for you in `bin/fumes`

## Usage

Specify source and target files:

`fumes ./path/to/SourceFile.swift ./path/to/DestinationFile.swift`

or copy modified source code directly to your clipboard:

`fumes ./path/to/SourceFile.swift -c`


## Options

| Flag        |      | Description                                                                                                                 |
|:------------|:-----|:----------------------------------------------------------------------------------------------------------------------------|
| `--input`   | `-i` | a path to get the .swift source code. You may also use the first argument.                                                  |
| `--output`  | `-o` | a path to write the transpiled code You may also use the second argument. Alternatively, you may `--copy` to your clipboard |
| `--copy`    | `-c` | copy source code to clipboard. Alternatively, you may provide an `--output` path to write to                                |
| `--bg`      |      | a string to set the background UIColor for the view. `.clear` by default                                                    |
| `--super`   | `-c` | an optional superclass for the resulting class. UIView by default.                                                          |
| `--verbose` | `-v` | whether to output transpiler warnings.                                                                                      |
| `--help`    | `-h` |                                                                                                                             |


## Formatting Sketch Files

- Add a trailing underscore to groups or layers to indicate that they're private. These will be added to your private class extension, but not to the public one.
