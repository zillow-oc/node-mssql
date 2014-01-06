# http://msdn.microsoft.com/en-us/library/dd305325.aspx

NULL = (1 << 16) - 1
EPOCH_DATE = new Date(1900, 0, 1)
MAX = (1 << 16) - 1

TYPES =
	# --- 2.2.5.4.1 Fixed-Length Data Types
	
	0x1F:
		bit: 0x1F
		type: 'NULLTYPE'
		name: 'Null'
	
	0x26:
		bit: 0x26
		type: 'INTNTYPE'
		name: 'IntN'
		lengthType: 1
	
	0x30:
		bit: 0x30
		type: 'INT1TYPE'
		name: 'TinyInt'
		declaration: (parameter) -> 'tinyint'
		writeParameterData: (buffer, parameter) ->
			buffer.writeUInt8(typeByName.IntN.id)
			buffer.writeUInt8(1)
	
			if parameter.value?
				buffer.writeUInt8(1)
				buffer.writeInt8(parseInt(parameter.value))
				
			else
				buffer.writeUInt8(0)
				
	0x32:
		bit: 0x32
		type: 'BITTYPE'
		name: 'Bit'
		declaration: (parameter) -> 'bit'
		writeParameterData: (buffer, parameter) ->
			buffer.writeUInt8(typeByName.BitN.id)
			buffer.writeUInt8(1)
			
			if typeof parameter.value == 'undefined' || parameter.value == null
				buffer.writeUInt8(0)
				
			else
				buffer.writeUInt8(1)
				buffer.writeUInt8(if parameter.value then 1 else 0)
	
	0x34:
		bit: 0x34
		type: 'INT2TYPE'
		name: 'SmallInt'
		declaration: (parameter) -> 'smallint'
		writeParameterData: (buffer, parameter) ->
			buffer.writeUInt8(typeByName.IntN.id)
			buffer.writeUInt8(2)
			
			if parameter.value?
				buffer.writeUInt8(2)
				buffer.writeInt16LE(parseInt(parameter.value))
				
			else
				buffer.writeUInt8(0)
	
	0x38:
		bit: 0x38
		type: 'INT4TYPE'
		name: 'Int'
		declaration: (parameter) -> 'int'
		writeParameterData: (buffer, parameter) ->
			buffer.writeUInt8(typeByName.IntN.id)
			buffer.writeUInt8(4)
			
			if parameter.value?
				buffer.writeUInt8(4)
				buffer.writeInt32LE(parseInt(parameter.value))
				
			else
				buffer.writeUInt8(0)
	
	0xA7:
		bit: 0xA7
		type: 'BIGVARCHRTYPE'
		name: 'VarChar'
		hasCollation: true
		lengthType: 2
		maximumLength: 8000
		declaration: (parameter) ->
			if parameter.length
				length = parameter.length
			else if parameter.value?
				length = parameter.value.toString().length
			else
				length = @.maximumLength
			
			if length <= @maximumLength
				"varchar(#{@.maximumLength})"
			else
				"varchar(max)"
			
		writeParameterData: (buffer, parameter) ->
			# TODO

module.exports = TYPES