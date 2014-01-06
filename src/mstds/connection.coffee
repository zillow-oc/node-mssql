{Socket} = require 'net'
Packet = require './packet'
Payload = require './payload'
TokenStream = require './token/stream'
{TDSError, SQLError} = require './errors'
Request = require './request'
{EventEmitter} = require 'events'

PreLoginPayload = require './payload/prelogin'
Login7Payload = require './payload/login7'
RPCPayload = require './payload/rpc'
SQLBatchPayload = require './payload/sqlbatch'

KEEP_ALIVE_INITIAL_DELAY = 30 * 1000
DEFAULT_CONNECT_TIMEOUT = 15 * 1000
DEFAULT_CLIENT_REQUEST_TIMEOUT = 15 * 1000
DEFAULT_CANCEL_TIMEOUT = 5 * 1000
DEFAULT_TEXTSIZE = '2147483647'

STATE =
	IDLE: 0
	CONNECTING: 1
	PRELOGIN: 2
	LOGIN: 3
	LOGGED: 4
	REQUEST: 5

LCID_TO_CODEPAGE = require './collations'

###

@property {Boolean} verbose Verbose.
@property {Number} state State.
@property {String} database Current database.

@event error Dispatched when error occur.
	@param {Error} err Error.

@event error Dispatched when error occur.
	@param {InfoToken} info Info token.
###

class Connection extends EventEmitter
	verbose: true
	socket: null
	buffer: null
	tdsbuffer: null
	tokenStream: null
	tdsVersion: '7_4'
	state: STATE.IDLE
	database: 'master'
	codepage: 'utf8'
	
	_transactionDescriptors: null
	
	constructor: ->
		@socket = new Socket
		@buffer = new Buffer 0
		@tdsbuffer = new Buffer 0
		@tokenStream = new TokenStream @
		@_transactionDescriptors = [new Buffer([0, 0, 0, 0, 0, 0, 0, 0])]
		
		# --- Socket ---
		
		@socket.on 'connect', =>
			if @verbose then console.log "[net] connected"
			@state = STATE.PRELOGIN
			
			@socket.setTimeout 0
			@send new PreLoginPayload @
		
		@socket.on 'timeout', =>
			if @verbose then console.log "[net] timeouted"
			
			@emit 'connect', new TDSError "CONNECTION_TIMEOUT"
			@socket.destroy()

		@socket.on 'close', (had_error) =>
			if @verbose then console.log "[net] disconnected"
			
			if @state isnt STATE.IDLE
				@emit 'disconnect'
				
			@database = 'master'
			@state = STATE.IDLE
		
		@socket.on 'data', (data) =>
			if @verbose then console.log "[net] received:", data
			
			@buffer = Buffer.concat [@buffer, data]
			
			data = []
			while @buffer.length >= 8 and @buffer.length >= (length = @buffer.readUInt16BE 2)
				packet = Packet.parse @buffer.slice(0, length)
				@buffer = @buffer.slice length
				data.push packet.buffer
				
				if packet.eom
					@socket.emit 'tdsdata', Buffer.concat data
					@socket.emit 'tdsmessage'
					
					data = []
		
		@socket.on 'tdsdata', (data) =>
			switch @state
				when STATE.PRELOGIN
					@tdsbuffer = Buffer.concat [@tdsbuffer, data]
				
				when STATE.LOGIN, STATE.LOGGED, STATE.REQUEST
					@tokenStream.write data
		
		@socket.on 'tdsmessage', =>
			switch @state
				when STATE.PRELOGIN
					# parse server details
					PreLoginPayload.response @tdsbuffer
					
					@state = STATE.LOGIN
					
					# login user
					@send new Login7Payload @
				
				when STATE.REQUEST
					console.log "REQUEST MESSAGE"
				
		@socket.setKeepAlive true, KEEP_ALIVE_INITIAL_DELAY
		
		# --- TokenStream ---
		
		@tokenStream.on 'loginack', (token) =>
			@state = STATE.LOGGED
			
			# let the parser parse rest of init tokens before we let user know we are connected
			process.nextTick =>
				@emit 'connect', null
		
		@tokenStream.on 'databaseChange', (token) =>
			@database = token.now
		
		@tokenStream.on 'collationChange', (token) =>
			lcid = (token.now[2] & 0x0F) << 16
			lcid |= token.now[1] << 8
			lcid |= token.now[0]

			@codepage = LCID_TO_CODEPAGE[lcid]
		
		@tokenStream.on 'beginTransaction', (token) =>
			@_transactionDescriptors.push token.now
		
		@tokenStream.on 'commitTransaction', (token) =>
			@_transactionDescriptors.pop()
		
		@tokenStream.on 'rollbackTransaction', (token) =>
			@_transactionDescriptors.pop()

	close: ->
		@socket.destroy()
	
	connect: (@config = {}) ->
		unless @state is STATE.IDLE
			return process.nextTick => @emit 'connect', new TDSError "INVALID_CONNECTION_STATE"
		
		@config.port ?= 1433
		
		if @verbose then console.log "[net] connecting to #{@config.server}:#{@config.port}"
		@state = STATE.CONNECTING
		
		@socket.connect @config.port, @config.server
		
		@socket.setTimeout DEFAULT_CONNECT_TIMEOUT
	
	execute: (request, callback) ->
		unless request instanceof Request then return throw new TypeError "Request expected!"
		unless @state is STATE.LOGGED then return callback new TDSError "INVALID_CONNECTION_STATE"
		
		@state = STATE.REQUEST
		
		@send new SQLBatchPayload @, request
	
	send: (payload) ->
		if @verbose then console.log "[tds] sending '#{payload.constructor.name}' payload"

		unless payload instanceof Payload then throw new TypeError "Payload expected!"
		
		for packet in payload.finalize()
			packet = packet.finalize()
			
			#console.log packet
			@socket.write packet

module.exports = Connection