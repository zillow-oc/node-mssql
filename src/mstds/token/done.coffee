Token = require './token'

# http://msdn.microsoft.com/en-us/library/dd340421.aspx

STATUS =
	MORE: 0x0001
	ERROR: 0x0002
	INXACT: 0x0004
	COUNT: 0x0010
	ATTN: 0x0020
	SRVERROR: 0x0100

class DoneToken extends Token
	constructor: (stream) ->
		@status = stream.readUInt16LE()
		@currentCommand = stream.readUInt16LE()
		
		if stream.connection.tdsVersion >= '7_2'
			@rowCount = stream.readUInt64LE()
		else
			@rowCount = stream.readUInt32LE()
		
		Object.defineProperty @, 'hasMore',
			get: => @status & STATUS.MORE isnt 0
			
		Object.defineProperty @, 'isError', =>
			@status & STATUS.ERROR isnt 0
			
		Object.defineProperty @, 'hasRowCount', =>
			@status & STATUS.COUNT isnt 0
			
		Object.defineProperty @, 'isCancelled', =>
			@status & STATUS.ATTN isnt 0
			
		Object.defineProperty @, 'isFatal', =>
			@status & STATUS.SRVERROR isnt 0

module.exports = DoneToken