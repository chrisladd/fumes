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

## Options

| Option  | Description                                                                                                                                             |  |
|:--------|:--------------------------------------------------------------------------------------------------------------------------------------------------------|:-|
| `0`     | The first argument is the input, where content should come from. It should include the name of the file, either `.m`, `.h` or, in the future, `.swift`. |  |
| `1`     | The second argument is the output, where the modified files should be saved to. If omitted, they will overwrite the input. |
| `super` | The superclass that should be substituted for `NSObject`. `UIView`, by default, but you may use your own view subclass if you like. This is useful, for example, for instituting class clusters. |




## Formatting Sketch Files

- Add a trailing underscore to groups or layers to indicate that they're private. These will be added to your private class extension, but not to the public one.