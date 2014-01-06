Token = require './token'

# http://msdn.microsoft.com/en-us/library/dd340651.aspx

TDS_VERSIONS =
	0x70000000: '7_0'		# 7.0
	0x71000000: '7_1'		# 2000
	0x71000001: '7_1_1'		# 2000 SP1
	0x72090002: '7_2'		# 2005
	0x730A0003: '7_3_A'		# 2008
	0x730B0003: '7_3_B'		# 2008 R2
	0x74000004: '7_4'		# 2012

class LoginAckToken extends Token
	constructor: (stream) ->
		length = stream.readUInt16LE()
		stream.assertBytesAvailable length
		
		@interface = stream.readUInt8()
		@tdsVersion = TDS_VERSIONS[stream.readUInt32BE()]
		@progName = stream.readBVarChar()
		@majorVer = stream.readUInt8()
		@minorVer = stream.readUInt8()
		@buildNum = stream.readUInt8() << 8
		@buildNum += stream.readUInt8()

module.exports = LoginAckToken