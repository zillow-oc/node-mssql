Token = require './token'

TYPES = require '../types'

MAX = (1 << 16) - 1
LCID_TO_CODEPAGE = require '../collations'

# http://msdn.microsoft.com/en-us/library/dd357363.aspx

class ColMetaDataToken extends Token
	constructor: (stream) ->
		@columns = new Array
		
		count = stream.readUShort()

		for i in [1..count]
			column =
				userType: stream.readUShort()
				flags: if stream.connection.tdsVersion >= '7_2' then stream.readULong() else stream.readUShort()
				type: TYPES[stream.readByte()]
			
			unless column.type then return new Error "Unknown column type 0x#{stream.buffer.readUInt8(stream.offset-1).toString(16)}"
			
			column.isNullable = (column.flags & 0x01) isnt 0
			column.isCaseSensitive = (column.flags & 0x02) isnt 0
			column.isIdentity = (column.flags & 0x10) isnt 0
			column.isWriteable = (column.flags & 0x0C) isnt 0

			unless column.type.length?
				switch column.type.bit & 0x30
					when 0x10 # xx01xxxx - 2.2.4.2.1.1 - Zero length
						column.length = 0
						
					when 0x20 # xx10xxxx - 2.2.4.2.1.3 - Variable length
						switch column.type.lengthType
							when 1
								column.length = stream.readByte()
							when 2
								column.length = stream.readUShort()
							when 4
								column.length = stream.readULong()
									
					when 0x30 # xx11xxxx - 2.2.4.2.1.2 - Fixed length
						column.length = 1 << ((column.type.bit & 0x0C) >> 2)
	
					else
						column.length = undefined
			
			else
				column.length = column.type.length
			
			if column.type.hasPrecision
				column.precision = stream.readByte()
				
			if column.type.hasScale
				column.scale = stream.readByte()
			
			if column.type.hasTableName
				column.tableName = stream.readUSVarChar()

			if column.type.hasCollation # 2.2.5.1.2
				data = stream.readBytes 5
				
				lcid = (data[2] & 0x0F) << 16
				lcid |= data[1] << 8
				lcid |= data[0]

				column.collation =
					codepage: LCID_TO_CODEPAGE[lcid]
			
			column.name = stream.readBVarChar()
			
			@columns.push column

module.exports = ColMetaDataToken