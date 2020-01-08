# Fumes

Fumes removes the code-smell from PaintCode generated drawing.

## How it works

Fumes automatically parameterizes hard-coded elements like colors, using PaintCode's automatically generated code comments as naming guidelines. It also converts the resulting object from `NSObject` to `UIView`, and sets the hardcoded color values as defaults, while exposing properties for clients to customize.

## Usage

Fumes is installed as a global npm module. You use fumes like so:

`fumes INPUT_PATH OUTPUT_PATH`

TODO: not published yet. Until then, make an alias:

`alias fumes="~/dev/fumes/convert.js"`

Input path is necessary, and can include file extensions, or not—`.h` and `.m` Objective-C files will be found automatically, as will `.swift` files.

Output path is not necessary—if none is supplied, the input will be overwritten.


## Formatting Sketch Files

- Add a trailing underscore to groups or layers to indicate that they're private. These will be added to your private class extension, but not to the public one.