os = require 'os'

Packet = require '../packet'
Payload = require '../payload'
MutableBuffer = require '../mutablebuffer'

# http://msdn.microsoft.com/en-us/library/dd304019.aspx

TDS_VERSIONS =
	'7_0': 0x70000000		# 7.0
	'7_1': 0x71000000		# 2000
	'7_1_1': 0x71000001		# 2000 SP1
	'7_2': 0x72090002		# 2005
	'7_3_A': 0x730A0003		# 2008
	'7_3_B': 0x730B0003		# 2008 R2
	'7_4': 0x74000004		# 2012

FLAGS_1 =
	# fByteOrder: The byte order used by client for numeric and datetime data types.
	ENDIAN_LITTLE: 0x00,
	ENDIAN_BIG: 0x01,
	
	# fChar: The character set used on the client.
	CHARSET_ASCII: 0x00,
	CHARSET_EBCDIC: 0x02,
	
	# fFloat: The type of floating point representation used by the client.
	FLOAT_IEEE_754: 0x00,
	FLOAT_VAX: 0x04,
	FLOAT_ND5000: 0x08,
	
	# fDumpLoad: Set is dump/load or BCP capabilities are needed by the client.
	BCP_DUMPLOAD_ON: 0x00,
	BCP_DUMPLOAD_OFF: 0x10,
	
	# fUseDB: Set if the client desires warning messages on execution of the USE SQL statement. If this flag is not set, the server MUST NOT inform the client when the database changes, and therefore the client will be unaware of any accompanying collation changes.
	USE_DB_ON: 0x00,
	USE_DB_OFF: 0x20,
	
	# fDatabase: Set if the change to initial database needs to succeed if the connection is to succeed.
	INIT_DB_WARN: 0x00,
	INIT_DB_FATAL: 0x40,
	
	# fSetLang: Set if the client desires warning messages on execution of a language change statement.
	SET_LANG_WARN_OFF: 0x00,
	SET_LANG_WARN_ON: 0x80,

FLAGS_2 =
	# fLanguage: Set if the change to initial language needs to succeed if the connect is to succeed.
	INIT_LANG_WARN: 0x00,
	INIT_LANG_FATAL: 0x01,
	
	# fODBC: Set if the client is the ODBC driver. This causes the server to set ANSI_DEFAULTS to ON, IMPLICIT_TRANSACTIONS to OFF, TEXTSIZE to 0x7FFFFFFF (2GB) (TDS 7.2 and earlier), TEXTSIZE to infinite (introduced in TDS 7.3), and ROWCOUNT to infinite.
	ODBC_OFF: 0x00,
	ODBC_ON: 0x02,
	
	# Removed in TDS 7.2
	F_TRAN_BOUNDARY: 0x04,
	F_CACHE_CONNECT: 0x08,
	
	# fUserType: The type of user connecting to the server.
	USER_NORMAL: 0x00,
	USER_SERVER: 0x10,
	USER_REMUSER: 0x20,
	USER_SQLREPL: 0x40,
	
	# fIntSecurity: The type of security required by the client.
	INTEGRATED_SECURITY_OFF: 0x00,
	INTEGRATED_SECURITY_ON: 0x80

TYPE_FLAGS =
	# fSQLType: The type of SQL the client sends to the server.
	SQL_DFLT: 0x00,
	SQL_TSQL: 0x01,
	
	# fOLEDB: Set if the client is the OLEDB driver. This causes the server to set ANSI_DEFAULTS to ON, IMPLICIT_TRANSACTIONS to OFF, TEXTSIZE to 0x7FFFFFFF (2GB) (TDS 7.2 and earlier), TEXTSIZE to infinite (introduced in TDS 7.3), and ROWCOUNT to infinite.
	OLEDB_OFF: 0x00,
	OLEDB_ON: 0x02,						# Introduced in TDS 7.2
	
	# fReadOnlyIntent: This bit is introduced in TDS 7.4; however, TDS 7.1, 7.2, and 7.3 clients can also use this bit in LOGIN7 to specify that the application intent of the connection is read-only. The server SHOULD ignore this bit if the highest TDS version supported by the server is lower than TDS 7.4.
	READ_ONLY_INTENT: 0x04				# Introduced in TDS 7.4

FLAGS_3 =
	# fChangePassword: Specifies whether the login request SHOULD change password.
	CHANGE_PASSWORD_NO: 0x00,
	CHANGE_PASSWORD_YES: 0x01,			# Introduced in TDS 7.2
	
	# fSendYukonBinaryXML: 1 if XML data type instances are returned as binary XML.
	BINARY_XML: 0x02,					# Introduced in TDS 7.2
	
	# fUserInstance: 1 if client is requesting separate process to be spawned as user instance.
	SPAWN_USER_INSTANCE: 0x04,			# Introduced in TDS 7.2
	
	# fUnknownCollationHandling: This bit is used by the server to determine if a client is able to properly handle collations introduced after TDS 7.2. TDS 7.2 and earlier clients are encouraged to use this login packet bit. Servers MUST ignore this bit when it is sent by TDS 7.3 or 7.4 clients. See [MSDN-SQLCollation] and [MS-LCID] documents for the complete list of collations for a database server that supports SQL and LCIDs.
	UNKNOWN_COLLATION_HANDLING: 0x08	# Introduced in TDS 7.3
	
	# fExtension: Specifies whether ibExtension/cbExtension fields are used.
	EXTENSION: 0x10						# Introduced in TDS 7.4

encryptPassword = (password) ->
	pwd = new Buffer password, 'ucs2'
	
	for i in [0..pwd.length - 1]
		pwd[i] = (((pwd[i] & 0x0f) << 4) | (pwd[i] >> 4)) ^ 0xA5

	pwd

class Login7Payload extends Payload
	constructor: (connection) ->
		super 0x10 # Login7
		
		@expand 36

		# Fixed

		@writeUInt32LE TDS_VERSIONS[connection.tdsVersion], 4
		@writeUInt32LE Packet.PACKET_SIZE, 8
		@writeUInt32LE 7, 12
		@writeUInt32LE process.pid, 16
		@writeUInt32LE 0, 20
		
		@writeUInt8 FLAGS_1.ENDIAN_LITTLE | FLAGS_1.CHARSET_ASCII | FLAGS_1.FLOAT_IEEE_754 | FLAGS_1.BCD_DUMPLOAD_OFF | FLAGS_1.USE_DB_OFF | FLAGS_1.INIT_DB_WARN | FLAGS_1.SET_LANG_WARN_ON, 24
		@writeUInt8 FLAGS_2.INIT_LANG_WARN | FLAGS_2.ODBC_OFF | FLAGS_2.USER_NORMAL | FLAGS_2.INTEGRATED_SECURITY_OFF, 25
		@writeUInt8 TYPE_FLAGS.SQL_DFLT | TYPE_FLAGS.OLEDB_OFF, 26
		@writeUInt8 FLAGS_3.CHANGE_PASSWORD_NO | FLAGS_3.UNKNOWN_COLLATION_HANDLING, 27

		@writeInt32LE new Date().getTimezoneOffset(), 28
		@writeUInt32LE 0x00000409, 32 # http://msdn.microsoft.com/en-us/library/cc233965.aspx

		# Variables
		
		hostname = os.hostname() ? ''
		username = connection.config.user ? ''
		password = connection.config.password ? ''
		appname = connection.config.appName ? 'node-mssql'
		libname = 'node-mssql'
		language = connection.config.language ? ''
		database = connection.config.database ? ''
		clientid = new Buffer([1, 2, 3, 4, 5, 6]) # TODO: Use mac address.
		
		# summarize headers + data length
		
		headerLength = 11 * 4 		# 11 variables * (2b offset + 2b length)
		headerLength += 6 			# 6b clientid

		if connection.tdsVersion >= '7_2'
			headerLength += 1 * 4	# 1 variable * (2b offset + 2b length)
			headerLength += 4		# 4b sspilong
			
		#if connection.tdsVersion >= '7_4'
		#	headerLength += 1 * 4	# 1 variable * (2b offset + 2b length)
		
		dataLength = 2 * (hostname.length + username.length + password.length + appname.length + libname.length + language.length + database.length)
		headerOffset = @length
		dataOffset = headerOffset + headerLength

		write = (value) =>
			if value instanceof Buffer
				@writeUInt16LE dataOffset, headerOffset
				@writeUInt16LE value.length / 2, headerOffset + 2
				headerOffset += 4

				@write value, dataOffset
				dataOffset += value.length
				
			else
				@writeUInt16LE dataOffset, headerOffset
				@writeUInt16LE value.length, headerOffset + 2
				headerOffset += 4

				@write value, dataOffset, 'ucs2'
				dataOffset += value.length * 2
		
		# write payload length
		@writeUInt32LE @length + headerLength + dataLength, 0
		
		# expand buffer
		@expand headerLength + dataLength

		write hostname							# The client machine name.
		write username							# The client user ID.
		write encryptPassword password			# The password supplied by the client.
		write appname							# The client application name.
		write ''								# The server name.
		write ''								# These parameters were reserved until TDS 7.4.
		
		#if connection.tdsVersion >= '7_4'
		#	write ''							# This points to an extension block. Introduced in TDS 7.4 when fExtension is 1.
		
		write libname							# The interface library name (ODBC or OLEDB).
		write language							# The initial language (overrides the user ID's default language).
		write database							# The initial database (overrides the user ID's default database).

		@write clientid, headerOffset			# The unique client ID (created used NIC address).
		headerOffset += 6
		
		write ''								# SSPI data.
		write ''								# The file name for a database that is to be attached during the connection process.
		
		if connection.tdsVersion >= '7_2'
			write ''							# New password for the specified login. Introduced in TDS 7.2.
			
			@writeUInt32LE 0, headerOffset		# Used for large SSPI data when cbSSPI==USHRT_MAX. Introduced in TDS 7.2.
			headerOffset += 4

module.exports = Login7Payload