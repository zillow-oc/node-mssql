MutableBuffer = require './mutablebuffer'

# Status - http://msdn.microsoft.com/en-us/library/dd358342.aspx

STATUS =
	NORMAL: 0x00,					# "Normal" message.
	EOM: 0x01,                      # End of message (EOM). The packet is the last packet in the whole request.
	IGNORE: 0x02,                   # (From client to server) Ignore this event (0x01 MUST also be set).
	RESETCONNECTION: 0x08,
	RESETCONNECTIONSKIPTRAN: 0x10

# Type - http://msdn.microsoft.com/en-us/library/dd304214.aspx

TYPE =
	SQL_BATCH: 0x01					# SQL batch. This can be any language that the server understands.
	RPC: 0x03						# RPC.
	TABULAR_RESULT: 0x04			# Tabular result. This indicates a stream that contains the server response to a client request.
	TRANSACTION_MANAGER: 0x0E		# Transaction manager request.
	TDS7: 0x10						# TDS7 login (MUST be used by all clients that support SQL Server 7.0 or later).
	PRELOGIN: 0x12					# Pre-login message.

class Packet extends MutableBuffer
	type: 0
	status: STATUS.EOM
	spid: 0
	id: 1
	window: 0
	
	constructor: (buffer) ->
		super buffer
		
		Object.defineProperty @, 'eom',
			get: -> @status is STATUS.EOM
			set: (value) -> @status = if value then STATUS.EOM else STATUS.NORMAL

	finalize: ->
		header = new Buffer 8
		header.writeUInt8 @type, 0 					# Type
		header.writeUInt8 @status, 1 				# Status
		header.writeUInt16BE @buffer.length + 8, 2	# Length
		header.writeUInt16BE @spid, 4 				# SPID
		header.writeUInt8 @id, 6 					# PacketID
		header.writeUInt8 @window, 7 				# Window

		Buffer.concat [header, @buffer]
	
	@parse: (buffer) ->
		packet = new Packet buffer.slice 8 # data without header
		packet.type = buffer.readUInt8 0
		packet.status = buffer.readUInt8 1
		packet.spid = buffer.readUInt16BE 4
		packet.id = buffer.readUInt8 6
		packet.window = buffer.readUInt8 7
		packet
	
	@PACKET_SIZE: 4 * 1024

module.exports = Packet