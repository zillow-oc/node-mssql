{mstds} = require '../'
tds = require 'tds'

c = new mstds.Connection
c.connect
	user: 'xsp_test'
	password: 'sweet'
	server: '192.168.2.2'
	port: 1433
	database: 'xsp'

c.on 'error', (err) ->
	console.dir err

c.on 'connect', (err) ->
	if err then return console.error err
	
	r = new mstds.Request
	r.command = 'select 12 as number, \'asdf+ěščřž\' as text, null as nula'
	c.execute r, (err) ->
		console.log arguments

return

t = new tds.Connection
	userName: 'xsp_test'
	password: 'sweet'
	host: '192.168.2.2'
	port: 1433
	database: 'xsp'

t.connect ->
	console.log "tds connected"
	
	t.end()