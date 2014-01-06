iconv = require 'iconv-lite'

Token = require './token'

MAX = (1 << 16) - 1

# http://msdn.microsoft.com/en-us/library/dd357254.aspx

class RowToken extends Token
	constructor: (stream, metadata) ->
		for column in metadata.columns
			textPointerNull = false
			value = null

			# --- Ignore pointer
			
			if column.type.hasTextPointer
				length = stream.readByte()
				
				if length isnt 0
					stream.skip length + 8
					
				else
					column.length = 0
					textPointerNull = true
			
			# --- Variable length value
			
			if (column.type.bit & 0x30) is 0x20 # xx10xxxx - 2.2.4.2.1.3 - Variable length
				if column.type.length != MAX
					stream.skip column.type.lengthType

			switch column.type.type
				when 'INT4TYPE'
					value = stream.readInt32LE()
				
				when 'INTNTYPE'
					switch column.length
						when 0
							value = null
						when 1
							value = stream.readInt8()
						when 2
							value = stream.readInt16LE()
						when 4
							value = stream.readInt32LE()
						when 8
							value = stream.readInt64LE()
						else
							throw new Error "Unsupported length #{column.length} for IntN!"

				when 'BIGVARCHRTYPE'
					value = iconv.decode stream.readBytes(column.length), column.collation.codepage
			
			# --- Done
			
			console.log "COL name:", column.name, ", type:", column.type.name, ", length:", column.length, ", value:", value
			

module.exports = RowToken

readChars = (buffer, length, codepage) ->
	if length?
		iconv.decode(buffer.readBuffer(dataLength), codepage)
	else
		null
   
readMaxChars = (buffer, codepage) ->
  readMax(buffer, (valueBuffer) ->
    iconv.decode(valueBuffer, codepage)
  )