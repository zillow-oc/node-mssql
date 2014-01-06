Payload = require '../payload'

# http://msdn.microsoft.com/en-us/library/dd358575.aspx



class SQLBatchPayload extends Payload
	constructor: (connection, request) ->
		super 0x01 # SQL Batch

		# --- All Headers

		@writeAllHeaders connection._transactionDescriptors[connection._transactionDescriptors.length - 1]
		
		# --- SQL command
		
		@appendString request.command, 'ucs2'

module.exports = SQLBatchPayload