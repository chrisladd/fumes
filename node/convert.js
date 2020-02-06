#!/usr/bin/env node

const fs = require('fs')
const code_modifier = require('./src/code_modifier')
const path = require('path')
let argv = require('minimist')(process.argv.slice(2));

function optionsFromArgs(argv) {
    let args = argv._
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
        name: basename,
        superClass: argv.super
    }
}

let options = optionsFromArgs(argv)

if (!options.inputDir) {
    console.log('Please supply an input to convert as your first argument')
    process.exit()
}

let h = fs.readFileSync(options.inputDir + '/' + options.name + '.h', 'utf8')
let m = fs.readFileSync(options.inputDir + '/' + options.name + '.m', 'utf8')

options.h = h;
options.m = m;

let result = code_modifier.viewWithObject(options)

let outputDir = options.outputDir
if (outputDir.lastIndexOf('/') != outputDir.length - 1) {
    outputDir = outputDir + '/'
}

fs.writeFileSync(outputDir + options.name + '.h', result.h)
fs.writeFileSync(outputDir + options.name + '.m', result.m)
