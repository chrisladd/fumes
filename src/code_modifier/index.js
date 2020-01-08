
const fs = require('fs')
const camelCase = require('change-case').camelCase

function convertInterfaceToView(interface){
    interface = interface.replace(/NSObject/g, 'UIView')
    return interface
}

function replaceClassMethodsWithInstanceMethods(code) {
    return code.replace(/^\+ \(/gm, '- (')
}

function insertCodeAfter(source, insertable, regex) {
    let match = source.match(regex)

    if (match.length && match.index > 0) {
        let splitIndex = match.index + match[0].length

        let first = source.substring(0, splitIndex)
        let last = source.substring(splitIndex)

        return first + '\n\n' + insertable + '\n' +  last
    }

    return source
}

function insertCodeBefore(source, insertable, regex) {
    let match = source.match(regex)

    if (match.length && match.index > 0) {
        let splitIndex = match.index

        let first = source.substring(0, splitIndex)
        let last = source.substring(splitIndex)

        return first + '\n' + insertable + '\n\n' +  last
    }

    return source
}

function initWithFrameWithOptions(options) {

    let leadingSpace = '        '
    let variableInit = ''


    if (options.colors) {
        let colorNames = Object.keys(options.colors).sort()    
        for (let name of colorNames) {
            let color = options.colors[name]
            variableInit += leadingSpace + '_' + name + ' = ' + color.color + ';\n'
        }
    }



    return `- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if (self) {
${variableInit}
    }

    return self
}`

}

// looks for a //! generated sketch label preceding a given layer
function nearestLabelPrecedingIndex(code, index) {
    let sentinel = '//! '
    let lineStart = code.lastIndexOf(sentinel, index)
    let lineEnd = code.indexOf('\n', lineStart)

    let label = code.substring(lineStart + sentinel.length, lineEnd).trim().replace(/\s/g, '_')

    return label
}

function colorMatchesOf(regex, code) {
    let colorRegex = /\[UIColor [^;\]]+\]/ 
    let matches = []

    while ((match = regex.exec(code)) !== null) {
        let text = match[0]
        let type = 'stroke'
        if (text.indexOf('Fill') > 0) {
            type = 'fill'
        }

        let label = nearestLabelPrecedingIndex(code, match.index) + '_' + type + '_color'
        let isPrivate = label.indexOf('_') == 0
        label = camelCase(label)

        matches.push({
            color: text.match(colorRegex)[0],
            text: text,
            type: type,
            start: match.index,
            end: regex.lastIndex,
            label: label,
            private: isPrivate
        })
    }

    return matches
}

function replaceColorWithVariable(code, color, label, index) {
    let startIdx = index + 1; // account for leading `[`
    let endIdx = startIdx + color.length
    let first = code.substring(0, startIdx)
    let last = code.substring(endIdx)

    return first + 'self.' + label + last
}

// returns an object with variable names, as well as an object of those variables
function replaceColorsInImplementation(code, result) {
    let fillRegex = /\[\[UIColor [^;]+ setFill];/g
    let strokeRegex = /\[\[UIColor [^;]+ setStroke];/g

    let fills = colorMatchesOf(fillRegex, code)
    let strokes = colorMatchesOf(strokeRegex, code)

    let matches = fills.concat(strokes)

    // sort in reverse order
    matches.sort(function(a, b) {
        if (a.start < b.start) {
            return 1
        }

        if (a.start > b.start) {
            return -1
        }

        return 0
    })

    // replace all hardcoded color values with variables
    let refactored = code + ''
    let colors = {}
    for (let match of matches) {
        refactored = replaceColorWithVariable(refactored, match.color, match.label, match.start)

        if (!colors[match.label]) {
            colors[match.label] = {
                color: match.color,
                private: match.private
            }
        }
    }

    return {
        m: refactored,
        colors: colors
    }
}

function classNameFromImplementation(code) {
    let match = code.match(/@implementation ([\w]+)/)
    if (match && match.length > 0) {
        return match[1]
    }

    return null
}

function isVariablePrivate(variableName) {
    if (variableName.indexOf('_') == 0) {
        return true
    }

    return false
}

function classExtensionWithOptions(options, className) {
    let indent = '    '
    let code = '@interface ' + className + '()\n'

    let properties = interfacePropertiesWithOptions(options, true)
    code += properties
    code += '\n@end\n'

    return code
}

function interfacePropertiesWithOptions(options, shouldBePrivate) {
    let indent = '    '
    let code = ''

    if (options.colors) {
        let colorNames = Object.keys(options.colors).sort()   

        for (let name of colorNames) {
            let color = options.colors[name]
            if (color.private == shouldBePrivate) {
                code += '@property (nonatomic) UIColor *' + name + ';\n'
            }
        }
    }

    return code
}

function drawMethodCallFrom(code) {
    let regex = /\[[\w]+ draw[\w]+WithFrame:CGRectMake\(\d+,\s+\d+,\s+\d+,\s+\d+\)\s+resizing:[\w]+\]/
    let match = code.match(regex)
    return match[0]
}

function sizeThatFitsWithCode(code) {
    let methodCall = drawMethodCallFrom(code)
    let sizeRegex = /CGRectMake\(\d+,\s+\d+,\s+(\d+),\s+(\d+)+\)/

    let width = 100;
    let height = 100;

    let match = methodCall.match(sizeRegex)
    if (match.length > 2) {
        width = parseInt(match[1], 10)
        height = parseInt(match[2], 10)
    }

    return `- (CGSize)sizeThatFits:(CGSize)size {
     CGSize nativeSize = CGSizeMake(${width}, ${height});
     CGFloat aspect = size.width / nativeSize.width;
     CGFloat height = nativeSize.height * aspect;
    
     return CGSizeMake(size.width, height);
}`

}

function drawRectMethodWithCode(code) {
    let methodCall = drawMethodCallFrom(code)

    let method = ''
    method += '- (void)drawRect:(CGRect)rect {\n'
    method += '    [super drawRect:rect];\n'

    let sizeRegex = /CGRectMake\(\d+,\s+\d+,\s+\d+,\s+\d+\)/
    let sizeMatch = methodCall.match(sizeRegex)[0]
    methodCall = methodCall.replace(sizeMatch, 'rect')

    method += '    ' + methodCall + ';'
    method += '\n}\n\n'

    return method
}


/**
 * Converts genertated code from static NSObjects to UIViews.
 * @param  {string} options.h  Objective-C header code
 * @param  {string} options.m  Objective-C implementation code
 * 
 * @return {string} result.h   Objective-C header code
 * @return {string} result.m   Objective-C implementation code
 */
module.exports.viewWithObject = function(options) {
    let interface = convertInterfaceToView(options.h)
    interface = replaceClassMethodsWithInstanceMethods(interface)

    let implemenation = options.m
    implemenation = replaceClassMethodsWithInstanceMethods(implemenation)

    let replaceResult = replaceColorsInImplementation(implemenation)
    implemenation = replaceResult.m


    let initCode = initWithFrameWithOptions(replaceResult)
    implemenation = insertCodeAfter(implemenation, initCode, /@implementation [\w]+\n/)

    let className = classNameFromImplementation(implemenation)
    let classExtension = classExtensionWithOptions(replaceResult, className)
    implemenation = insertCodeBefore(implemenation, classExtension, /@implementation [\w]+\n/)

    let drawCall = drawRectMethodWithCode(implemenation)
    let sizeCall = sizeThatFitsWithCode(implemenation)
    // console.log(drawCall);
    implemenation = insertCodeBefore(implemenation, drawCall, /- \(instancetype\)initWithFrame/)
    implemenation = insertCodeBefore(implemenation, sizeCall, /- \(instancetype\)initWithFrame/)

    let publicProperties = interfacePropertiesWithOptions(replaceResult, false)
    interface = insertCodeAfter(interface, publicProperties, /: UIView\n/)

    return {
        h: interface,
        m: implemenation
    }
}