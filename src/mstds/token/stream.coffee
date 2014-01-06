{StreamParserAssertionError, SQLError} = require '../errors'
{EventEmitter} = require 'events'

TYPE =
	ALTMETADATA: 0x88
	ALTROW: 0xD3
	COLMETADATA: 0x81
	COLINFO: 0xA5
	DONE: 0xFD
	DONEPROC: 0xFE
	DONEINPROC: 0xFF
	ENVCHANGE: 0xE3
	ERROR: 0xAA
	INFO: 0xAB
	LOGINACK: 0xAD
	NBCROW: 0xD2
	OFFSET: 0x78
	ORDER: 0xA9
	RETURNSTATUS: 0x79
	RETURNVALUE: 0xAC
	ROW: 0xD1
	SSPI: 0xED
	TABNAME: 0xA4

InfoToken = require './info'
ErrorToken = require './error'
EnvChangeToken = require './envchange'
LoginAckToken = require './loginack'
DoneToken = require './done'
ColMetaDataToken = require './colmetadata'
RowToken = require './row'

class TokenStream extends EventEmitter
	buffer: null
	offset: 0
	metadata: null
	
	constructor: (@connection) ->
		@buffer = new Buffer 0
	
	assertBytesAvailable: (required) ->
		if @offset + required > @buffer.length
			throw new StreamParserAssertionError 'Not enough data in buffer.'
	
	next: ->
		unless @buffer.length then return false
		
		try
			switch @readUInt8()
				when TYPE.ERROR
					token = new ErrorToken @
					err = new SQLError token.message
					err.number = token.number
					err.state = token.state
					err.line = token.line
					err.severity = token.severity
					err.procName = token.procName
					err.serverName = token.serverName
					
					@connection.emit 'error', err
				
				when TYPE.INFO
					token = new InfoToken @
					@connection.emit 'info', token
				
				when TYPE.ENVCHANGE
					token = new EnvChangeToken @
					
					if token.type.event
						@emit token.type.event, token
					
					console.log 'ENVCHANGE', token.type.event, token.old, token.now
				
				when TYPE.LOGINACK
					token = new LoginAckToken @
					
					@emit 'loginack', token
					
					console.log 'LOGINACK', token
				
				when TYPE.DONE
					token = new DoneToken @
					
					console.log 'DONE', token
				
				when TYPE.COLMETADATA
					token = new ColMetaDataToken @
					@metadata = token
					
					console.log 'METDATATA', token
				
				when TYPE.ROW
					token = new RowToken @, @metadata
					
					console.log 'ROW', token
				
				else
					if @connection.verbose then console.error "[tds] unknown token type: 0x#{@buffer.readUInt8(@offset - 1).toString 16}"
					return false
			
			# token successfuly parsed, slice the buffer
			
			@buffer = @buffer.slice @offset
			@offset = 0
			
			return true
		
		catch ex
			if ex instanceof StreamParserAssertionError
				@offset = 0
			else
				console.error ex.stack
			
			return false
	
	skip: (length) ->
		@offset += length
	
	write: (data) ->
		@buffer = Buffer.concat [@buffer, data]
		
		while @next()
			'NOOP'
	
	# --- Stream readers
	
	readUInt8: ->
		@assertBytesAvailable 1
		
		out = @buffer.readUInt8 @offset
		@offset += 1
		
		out
	
	readUInt16BE: ->
		@assertBytesAvailable 2
		
		out = @buffer.readUInt16BE @offset
		@offset += 2
		
		out
		
	readUInt16LE: ->
		@assertBytesAvailable 2
		
		out = @buffer.readUInt16LE @offset
		@offset += 2
		
		out
		
	readInt16LE: ->
		@assertBytesAvailable 2
		
		out = @buffer.readInt16LE @offset
		@offset += 2
		
		out
		
	readUInt32BE: ->
		@assertBytesAvailable 4
		
		out = @buffer.readUInt32BE @offset
		@offset += 4
		
		out
		
	readUInt32LE: ->
		@assertBytesAvailable 4
		
		out = @buffer.readUInt32LE @offset
		@offset += 4
		
		out
		
	readInt32LE: ->
		@assertBytesAvailable 4
		
		out = @buffer.readInt32LE @offset
		@offset += 4
		
		out
	
	readUInt64LE: ->
		low = @readUInt32LE()
		high = @readUInt32LE()
		
		if (high >= (2 << (53 - 32)))
			# If value > 53 bits then it will be incorrect (because Javascript uses IEEE_754 for number representation).
			console.warn("Read UInt64LE > 53 bits : high=#{high}, low=#{low}")
		
		low + (0x100000000 * high)
	
	readBuffer: (length) ->
		@assertBytesAvailable length
		
		out = @buffer.slice @offset, @offset + length
		@offset += length
		
		out
	
	# --- TDS ---
	
	readByte: ->
		@readUInt8()
	
	readBytes: (length) ->
		@readBuffer length
	
	readUShort: ->
		@readUInt16LE()
	
	readULong: ->
		@readUInt32LE()
	
	readString: (length, encoding = 'ucs2') ->
		@assertBytesAvailable length
		
		out = @buffer.toString encoding, @offset, @offset + length
		@offset += length
		
		out
	
	readBVarChar: (encoding = 'ucs2') ->
		@readString @readByte() * 2, encoding
	
	readUSVarChar: (encoding = 'ucs2') ->
		@readString @readUShort() * 2, encoding
	
module.exports = TokenStream