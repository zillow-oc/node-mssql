MutableBuffer = require './mutablebuffer'
Packet = require './packet'

ALL_HEADERS_TYPE =
	QUERY_NOTIFICATIONS: 1
	TXN_DESCRIPTOR: 2
	TRACE_ACTIVITY: 3

class Payload extends MutableBuffer
	type: null
	
	constructor: (@type) ->
		super()
	
	finalize: ->
		packets = []
		count = Math.floor((@length - 1) / Packet.PACKET_SIZE) + 1
		
		for index in [0..count - 1]
			start = index * Packet.PACKET_SIZE
			
			if index < count - 1
				end = start + Packet.PACKET_SIZE
			else
				end = @length
			
			packet = new Packet @slice(start, end)
			packet.type = @type
			packet.eom = index is count - 1
			packet.id = index + 1

			packets.push packet
		
		packets
	
	###
	http://msdn.microsoft.com/en-us/library/dd304953.aspx
	###
	
	writeAllHeaders: (transactionDescriptor) ->
		headerDataLength = 4 + 8
		headerLength = 4 + 2 + headerDataLength

		@expand headerLength + 4

		@writeUInt32LE headerLength, 4							# Header length; including itself
		@writeUInt16LE ALL_HEADERS_TYPE.TXN_DESCRIPTOR, 8
		
		# Header data
		@writeBuffer transactionDescriptor, 10					# 8b TransactionDescriptor
		@writeUInt32LE 1, 18									# 4b OutstandingRequestCount
		
		@writeUInt32LE headerLength + 4, 0						# Complete header length; including itself

module.exports = Payload