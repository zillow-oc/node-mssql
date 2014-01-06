Payload = require '../payload'
MutableBuffer = require '../mutablebuffer'

# http://msdn.microsoft.com/en-us/library/dd357559.aspx

class PreLoginPayload extends Payload
	constructor: (connection) ->
		super 0x12 # Pre-login
		
		options = []
		
		options.push
			token: 0x00 # version
			data: do ->
				buffer = new MutableBuffer 6
				buffer.writeUInt32BE 0x000000001, 0
				buffer.writeUInt16BE 0x0001, 4
				buffer
		
		options.push
			token: 0x01 # encryption
			data: do ->
				buffer = new MutableBuffer 1
				buffer.writeUInt8 0x02, 0 # not supported
				buffer
		
		options.push
			token: 0x02 # instopt
			data: do ->
				buffer = new MutableBuffer 1
				buffer.writeUInt8 0x00, 0
				buffer
		
		options.push
			token: 0x03 # threadid
			data: do ->
				buffer = new MutableBuffer 4
				buffer.writeUInt32BE 0x00, 0
				buffer
		
		options.push
			token: 0x04 # mars
			data: do ->
				buffer = new MutableBuffer 1
				buffer.writeUInt8 0x00, 0
				buffer
		
		# count buffer size
		
		dataOffset = options.length * 5 + 1
		dataLength = 0
		
		for opt in options
			dataLength += opt.data.length
		
		@expand dataOffset + dataLength

		# write buffer
		
		offset = 0
		
		for opt in options
			@writeUInt8 opt.token, offset
			@writeUInt16BE dataOffset, offset + 1
			@writeUInt16BE opt.data.length, offset + 3
			opt.data.copy @, dataOffset
			
			offset += 5
			dataOffset += opt.data.length

		@writeUInt8 0xFF, offset # token terinator
	
	@response: (buffer) ->
		return # TODO
		
		offset = 0
		while buffer[offset] isnt 0xFF
			dataOffset = buffer.readUInt16BE offset + 1
			dataLength = buffer.readUInt16BE offset + 3
			
			switch buffer[offset]
				when 0x00
					console.log "Version:",
						major: buffer.readUInt8 dataOffset + 0
						minor: buffer.readUInt8 dataOffset + 1
						patch: buffer.readUInt8 dataOffset + 2
						trivial: buffer.readUInt8 dataOffset + 3
						subbuild: buffer.readUInt16BE dataOffset + 4
					
				when 0x01
					console.log "Encryption:", buffer.readUInt8 dataOffset
					
				when 0x02
					console.log "INSTOPT:", buffer.readUInt8 dataOffset
					
				when 0x03
					if (dataLength > 0)
						console.log "THREADID:", buffer.readUInt32BE dataOffset
						
				when 0x04
					console.log "MARS:", buffer.readUInt8 dataOffset
			
			offset += 5
			dataOffset += dataLength

module.exports = PreLoginPayload