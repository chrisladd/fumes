
const assert = require('chai').assert
let code_modifier = require('../src/code_modifier')
let helper = require('./test_helper')


describe('objects', function(){
    it('should return an object with .h and .m', function() {
        let source = helper.fixtureWithName('CBTuningDiagram')
        let result = code_modifier.viewWithObject(source)

        assert.ok(result.h)
        assert.ok(result.m)
    })

    it('should change the class from NSObject to UIView in .h files', function(){
        let source = helper.fixtureWithName('CBTuningDiagram')
        let result = code_modifier.viewWithObject(source)

        assert.include(result.h, '@interface CBTuningDiagram : UIView')

    })

    it('should convert instance methods to class methods in header files', function() {
        let source = helper.fixtureWithName('CBTuningDiagram')
        let result = code_modifier.viewWithObject(source)

        assert.notInclude(result.h, '+ (')        
    })

    it('should convert instance methods to class methods in implementation files', function() {
        let source = helper.fixtureWithName('CBTuningDiagram')
        let result = code_modifier.viewWithObject(source)

        let matches = result.m.match(/^\+ /g)
        assert.notOk(matches)        
    })

    it('should add a class extension', function() {
        let source = helper.fixtureWithName('CBTuningDiagram')
        let result = code_modifier.viewWithObject(source)

        assert.include(result.m, '@interface CBTuningDiagram()')
    })

    it('should override initWithFrame', function() {
        let source = helper.fixtureWithName('CBTuningDiagram')
        let result = code_modifier.viewWithObject(source)

        assert.include(result.m, '- (instancetype)initWithFrame:')

    })
    
    it('should make names prefixed with a _ private')

    it('should override drawRect')
    it('should remove image drawing code')
    

})