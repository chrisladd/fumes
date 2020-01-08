#!/usr/bin/env node

const fs = require('fs')
const code_modifier = require('./src/code_modifier')
const path = require('path')

let args = process.argv.slice(2)

function optionsFromArgs(args) {
    if (args.length == 0) {
        return null;
    }

    let inputPath = args[0].trim()

    let inputDir = path.dirname(inputPath)
    let basename = path.basename(inputPath).split('.')[0]

    let outputPath = inputDir;
    if (args.length > 1) {
        outputPath = args[1]
    }    

    return {
        inputDir: inputDir,
        outputDir: outputPath,
        name: basename
    }
}

let options = optionsFromArgs(args)

console.log(options)

if (!options.inputDir) {
    console.log('Please supply an input to convert as your first argument')
    process.exit()
}


let h = fs.readFileSync(options.inputDir + '/' + options.name + '.h', 'utf8')
let m = fs.readFileSync(options.inputDir + '/' + options.name + '.m', 'utf8')

let result = code_modifier.viewWithObject({
    h: h,
    m: m
})

let outputDir = options.outputDir
if (outputDir.lastIndexOf('/') != outputDir.length - 1) {
    outputDir = outputDir + '/'
}

fs.writeFileSync(outputDir + options.name + '.h', result.h)
fs.writeFileSync(outputDir + options.name + '.m', result.m)
