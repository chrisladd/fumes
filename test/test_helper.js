
const fs = require('fs')

module.exports.fixtureWithName = function(name) {
    return {
        h: fs.readFileSync(`./test/fixtures/${name}.h`, 'utf8'),
        m: fs.readFileSync(`./test/fixtures/${name}.m`, 'utf8')
    }
}