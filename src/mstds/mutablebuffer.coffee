class MutableBuffer extends Buffer
	buffer: null
	
	constructor: ->
		if arguments.length is 0
			@buffer = new Buffer 0
		
		else
			if arguments[0] instanceof Buffer
				@buffer = arguments[0]
			
			else
				@buffer = new Buffer arguments...
		
		Object.defineProperty @, 'length',
			get: -> @buffer.length
	
	append: (value) ->
		if value instanceof Buffer
			@appendBuffer value
		
		else if value instanceof MutableBuffer
			@appendBuffer value.buffer
		
		else if typeof value is 'string'
			@appendString arguments...
		
		else
			throw new Error "Unknown object to append."
	
	appendBuffer: (buffer) ->
		@buffer = Buffer.concat [@buffer, buffer]
	
	appendUInt8: (value) ->
		@expand 1
		@writeUInt8 value, @buffer.length - 1
		
	appendInt8: (value) ->
		@expand 1
		@writeInt8 value, @buffer.length - 1
		
	appendUInt16LE: (value) ->
		@expand 2
		@writeUInt16LE value, @buffer.length - 2
		
	appendInt16LE: (value) ->
		@expand 2
		@writeInt16LE value, @buffer.length - 2

	appendUInt16BE: (value) ->
		@expand 2
		@writeUInt16BE value, @buffer.length - 2
		
	appendInt16BE: (value) ->
		@expand 2
		@writeInt16BE value, @buffer.length - 2
		
	appendUInt32LE: (value) ->
		@expand 4
		@writeUInt32LE value, @buffer.length - 4
		
	appendInt32LE: (value) ->
		@expand 4
		@writeInt32LE value, @buffer.length - 4

	appendUInt32BE: (value) ->
		@expand 4
		@writeUInt32BE value, @buffer.length - 4
		
	appendInt32BE: (value) ->
		@expand 4
		@writeInt32BE value, @buffer.length - 4
		
	appendFloatLE: (value) ->
		@expand 4
		@writeFloatLE value, @buffer.length - 4
		
	appendDoubleLE: (value) ->
		@expand 8
		@writeDoubleLE value, @buffer.length - 8
	
	appendString: (value, encoding = 'ucs2') ->
		len = Buffer.byteLength value, encoding
		@expand len
		@write value, @buffer.length - len, encoding
		len
	
	copy: ->
		if arguments[0] instanceof MutableBuffer then arguments[0] = arguments[0].buffer
		@buffer.copy arguments...

	expand: (length) ->
		@buffer = Buffer.concat [@buffer, new Buffer(length)]
	
	inspect: ->
		@buffer.inspect arguments...
	
	prepend: (value) ->
		if value instanceof Buffer
			@buffer = Buffer.concat [value, @buffer]
		
		else if value instanceof MutableBuffer
			@buffer = Buffer.concat [value.buffer, @buffer]
		
		else
			throw new Error "Unknown object to prepend."
	
	slice: ->
		@buffer.slice arguments...

	toString: ->
		@buffer.toString arguments...
	
	write: ->
		if arguments[0] instanceof Buffer
			@writeBuffer arguments...
			
		else
			@buffer.write arguments...
	
	writeBuffer: (buffer, offset) ->
		buffer.copy @buffer, offset

	writeUInt8: ->
		@buffer.writeUInt8 arguments...

	writeInt8: ->
		@buffer.writeInt8 arguments...
		
	writeUInt16LE: ->
		@buffer.writeUInt16LE arguments...
		
	writeInt16LE: ->
		@buffer.writeInt16LE arguments...

	writeUInt16BE: ->
		@buffer.writeUInt16BE arguments...
		
	writeInt16BE: ->
		@buffer.writeInt16BE arguments...
		
	writeUInt32LE: ->
		@buffer.writeUInt32LE arguments...
		
	writeInt32LE: ->
		@buffer.writeInt32LE arguments...

	writeUInt32BE: ->
		@buffer.writeUInt32BE arguments...
		
	writeInt32BE: ->
		@buffer.writeInt32BE arguments...
		
	writeFloatLE: ->
		@buffer.writeFloatLE arguments...
		
	writeDoubleLE: ->
		@buffer.writeDoubleLE arguments...
	
	writeString: (value, offset, encoding = 'ucs2') ->
		len = Buffer.byteLength value, encoding
		@write value, offset, encoding
		len
	
	# --- TDS ---
		
	appendByte: (value) ->
		@expand 1
		@writeByte value, @buffer.length - 1
		
	appendUShort: (value) ->
		@expand 2
		@writeUShort value, @buffer.length - 2
	
	appendBVarChar: (value, offset, encoding) ->
		@appendByte value.length
		len = @appendString value, encoding
		len + 1
		len + 1
	
	appendUSVarChar: (value, encoding) ->
		@appendUShort value.length
		len = @appendString value, encoding
		len + 2
	
	writeByte: (byte, offset) ->
		@buffer.writeInt8 byte, offset
	
	writeUShort: (value, offset) ->
		@writeUInt16LE value, offset
	
	writeBVarChar: (value, offset, encoding) ->
		@writeByte value.length
		len = @writeString value, encoding
		len + 1
	
	writeUSVarChar: (value, encoding) ->
		@writeUShort value.length
		len = @writeString value, encoding
		len + 2
	
module.exports = MutableBuffer