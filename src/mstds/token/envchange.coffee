Token = require './token'

# http://msdn.microsoft.com/en-us/library/dd303449.aspx

TYPES =
	1:
		name: 'Database'
		event: 'databaseChange'
		oldValue: 'string'
		newValue: 'string'
	2:
		name: 'Language'
		event: 'languageChange'
		oldValue: 'string'
		newValue: 'string'
	3:
		name: 'Character Set'
		event: 'charsetChange'
		oldValue: 'string'
		newValue: 'string'
	4:
		name: 'Packet Size'
		event: 'packetSizeChange'
		oldValue: 'string'
		newValue: 'string'
	5:
		name: 'Unicode data sorting local id'
		newValue: 'string'
	6:
		name: 'Unicode data sorting comparison flags'
		newValue: 'string'
	7:
		name: 'SQL Collation'
		event: 'collationChange'
		oldValue: 'bytes'
		newValue: 'bytes'
	8:
		name: 'Begin Transaction'
		event: 'beginTransaction'
		newValue: 'bytes'
	9:
		name: 'Commit Transaction'
		event: 'commitTransaction'
		oldValue: 'bytes'
		newValue: 'byte'
	10:
		name: 'Rollback Transaction'
		event: 'rollbackTransaction'
		oldValue: 'bytes'
	11:
		name: 'Enlist DTC Transaction'
		oldValue: 'bytes'
	12:
		name: 'Defect Transaction'
		newValue: 'bytes'
	13:
		name: 'Database Mirroring Partner'
		event: 'partnerNode'
		newValue: 'string'
	15:
		name: 'Promote Transaction'
		newValue: 'longbytes'
	16:
		name: 'Transaction Manager Address'
		newValue: 'bytes'
	17:
		name: 'Transaction Ended'
		oldValue: 'bytes'
	18:
		name: 'Reset Completion Acknowledgement'
		event: 'resetConnection'
	19:
		name: 'User Instance Name'
		newValue: 'string'
	20:
		name: 'Routing'
		oldValue: '2byteskip'
		newValue: 'shortbytes'

class EnvChangeToken extends Token
	constructor: (stream) ->
		length = stream.readUInt16LE()
		stream.assertBytesAvailable length

		@type = TYPES[stream.readUInt8()]
		@now = @_readValue @type.newValue, stream
		@old = @_readValue @type.oldValue, stream
	
	_readValue: (typedef, stream) ->
		if not typedef?
			stream.skip 1
			null
			
		else if typedef is '2byteskip'
			stream.skip 2
			null
			
		else
			switch typedef
				when 'string' then stream.readBVarChar()
				when 'bytes' then stream.readBuffer stream.readUInt8()
				when 'byte' then stream.readUInt8()
				when 'longbytes' then stream.readBuffer stream.readUInt32LE()
				when 'shortbytes' then stream.readBuffer stream.readUInt16LE()
				else throw new Error 'Unrecognized typedef: ' + typedef
	
module.exports = EnvChangeToken