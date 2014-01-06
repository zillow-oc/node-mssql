Token = require './token'

# http://msdn.microsoft.com/en-us/library/dd303398.aspx

class InfoToken extends Token
	constructor: (stream) ->
		length = stream.readUInt16LE()
		stream.assertBytesAvailable length
		
		@number = stream.readUInt32LE()
		@state = stream.readUInt8()
		@severity = stream.readUInt8()
		@message = stream.readUSVarChar()
		@serverName = stream.readBVarChar()
		@procName = stream.readBVarChar()
		
		if stream.connection.tdsVersion >= '7_2'
			@line = stream.readUInt32LE()
		else
			@line = stream.readUInt16LE()

module.exports = InfoToken