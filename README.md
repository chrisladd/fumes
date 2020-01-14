# Fumes

Fumes removes the code-smell from PaintCode generated drawing.

## How it works

Fumes automatically parameterizes hard-coded elements like colors, using PaintCode's automatically generated code comments as naming guidelines. It also converts the resulting object from `NSObject` to `UIView`, and sets the hardcoded color values as defaults, while exposing properties for clients to customize.

## Usage

Install `fumes` globaly:

```
npm i @cgl2/fumes --global
```

then specify source and target directories:

`fumes source_dir target_dir`

You may also specify a `--super SuperClass` for the finished code, or accept the default of `UIView`.

Input path is necessary, and can include file extensions, or not—`.h` and `.m` Objective-C files will be found automatically. TODO: as will `.swift` files.

Output path is not necessary—if none is supplied, the input will be overwritten.

## Options

| Option  | Description                                                                                                                                             |  |
|:--------|:--------------------------------------------------------------------------------------------------------------------------------------------------------|:-|
| `$1`     | The first argument is the input, where content should come from. It should include the name of the file, either `.m`, `.h` or, in the future, `.swift`. |  |
| `$2`     | The second argument is the output, where the modified files should be saved to. If omitted, they will overwrite the input. |
| `--super` | The superclass that should be substituted for `NSObject`. `UIView`, by default, but you may use your own view subclass if you like. This is useful, for example, for implementing class clusters. |



## Formatting Sketch Files

- Add a trailing underscore to groups or layers to indicate that they're private. These will be added to your private class extension, but not to the public one.