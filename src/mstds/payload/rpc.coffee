Payload = require '../payload'

# http://msdn.microsoft.com/en-us/library/dd357576.aspx

OPTION =
	WITH_RECOMPILE: 0x01
	NO_METADATA: 0x02
	REUSE_METADATA: 0x04

STATUS =
	BY_REF_VALUE: 0x01						# Output parameter
	DEFAULT_VALUE: 0x02

class RPCPayload extends Payload
	constructor: (connection, request) ->
		super 0x03 # RPC

		# --- All Headers

		@writeAllHeaders connection._transactionDescriptors[connection._transactionDescriptors.length - 1]
		
		# --- SQL command

		command = ''

		if typeof command is 'string'
			@appendUSVarChar command	# ProcName

		else
			@appendUShort 0xFFFF		# ProcIDSwitch
			@appendUShort command		# ProcID
		
		# --- Option Flags
		
		optionFlags = 0
		@appendUInt16LE optionFlags
		
		# --- Parameters
		
		for name, param of @request.parameters
			statusFlags = 0
			
			if param.output
				statusFlags |= STATUS.BY_REF_VALUE

			# ParamMetaData
			@appendBVarchar "@#{param.name}"
			@appendUInt8 statusFlags
			
			param.type.writeParameterData(buffer, parameter)

module.exports = RPCPayload