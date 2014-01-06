###
@ignore
###

IntermediateInheritor = ->
IntermediateInheritor.prototype = Error.prototype

###
StreamParserAssertionError Error.

@param {String} message Error message.

@class
@extends {Error}
@property {String} stack Call stack.
@property {String} message Error message.
###

StreamParserAssertionError = (message) ->
	e = Error.apply @, arguments
	e.name = @name = "StreamParserAssertionError"
	
	@stack = e.stack
	@message = e.message
	
	@

StreamParserAssertionError.prototype = new IntermediateInheritor()

###
TDSError Error.

@param {String} message Error message.

@class
@extends {Error}
@property {String} stack Call stack.
@property {String} message Error message.
###

TDSError = (message) ->
	e = Error.apply @, arguments
	e.name = @name = "TDSError"
	
	@stack = e.stack
	@message = e.message
	
	@

TDSError.prototype = new IntermediateInheritor()

module.exports =
	SQLError: SQLError
	StreamParserAssertionError: StreamParserAssertionError

###
SQLError Error.

@param {String} message Error message.

@class
@extends {Error}
@property {String} stack Call stack.
@property {String} message Error message.
###

SQLError = (message) ->
	e = Error.apply @, arguments
	e.name = @name = "SQLError"
	
	@stack = e.stack
	@message = e.message
	
	@

SQLError.prototype = new IntermediateInheritor()

module.exports =
	SQLError: SQLError
	TDSError: TDSError
	StreamParserAssertionError: StreamParserAssertionError