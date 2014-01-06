Token = require './token'

# http://msdn.microsoft.com/en-us/library/dd304156.aspx

class ErrorToken extends Token
	constructor: (stream) ->
		length = stream.readUInt16LE()
		stream.assertBytesAvailable length
		
		@number = stream.readUInt32LE()
		@state = stream.readUInt8()
		@severity = stream.readUInt8()
		@message = stream.readUcs2String stream.readUInt16LE()
		@serverName = stream.readUcs2String stream.readUInt8()
		@procName = stream.readUcs2String stream.readUInt8()
		
		if stream.connection.tdsVersion >= '7_2'
			@line = stream.readUInt32LE()
		else
			@line = stream.readUInt16LE()

module.exports = ErrorToken