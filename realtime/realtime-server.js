var app;

// Try to start with a secure server. If the SSL certificate can't be found, use a regular server.
try{
	var fs = require('fs');
	
	var options = {
		// key: fs.readFileSync('/etc/httpd/conf/apps/ssl/passport.key'),
		// cert: fs.readFileSync('/etc/httpd/conf/apps/ssl/passport.crt'),
		// ca: fs.readFileSync('/etc/httpd/conf/apps/ssl/geotrust_ca_bundle.crt')
	};

	app = require('https').createServer(options);
}
catch(e) {
	app = require('http').createServer();
}

var io = require('socket.io').listen(app);
app.listen(5001);

var redis = require('redis').createClient();
var users = {};

// Subscribe to these specific Redis channels.
redis.subscribe('newPost');

// Fires whenever anything is published to any Redis channel.
redis.on('message', function(channel, data) {
	var room;

	if(typeof data === 'string') {
		data = JSON.parse(data);
	}

	switch(channel) {
		case 'newPost':
			room = data.user_id.toString();
			io.sockets.in('Promotion' + room).emit('newPost', data);
			break;
	}
});

io.sockets.on('connection', function(socket) {
	
	// Adds a user to their own room.
	socket.on('addUser', function(data) {
		socket.userId = data.userId;
		socket.join('User' + data.userId);
	});

	// Adds a user to their promotion's room.
	socket.on('addPromotionUser', function(data) {
		socket.promotionId = data.promotionId;
		socket.join('Promotion' + data.promotionId);
	});

	// Adds a user to a chat room.
	socket.on('addChatUser', function(data) {
		
		// Set a new property on the socket object.
		socket.chatUserId = data.userId;
		socket.join('ChatRoom' + data.room);

		if(getUniqueUsersInChatRoom('ChatRoom' + data.room) === 2) {
			
			// Enable chat for this room.
			io.sockets.in('ChatRoom' + data.room).emit('status', true);
		}
	});

	// Removes a user from their room.
	socket.on('removeUser', function(data) {
		socket.leave('User' + data.userId);
	});

	// Removes a user from their promotions's room.
	socket.on('removePromotionUser', function(data) {
		socket.leave('Promotion' + data.promotionId);
	});

	// Removes a user from a chat room.
	socket.on('leaveChat', function(data) {
		socket.leave('ChatRoom' + data.room);
		
		if(getUniqueUsersInChatRoom(data.room) < 2) {
			
			// Disable chat for this room.
			io.sockets.in('ChatRoom' + data.room).emit('status', false);
		}
	});

	socket.on('disconnect', function() {
		// Do nothing?
	});
});

function getUniqueUsersInChatRoom(room) {
	var uniqueUsers = [];
	var usersObject = {};

	// Define userObject keys using connectedUserId values.
	for(var i = 0; i < io.sockets.clients(room).length; i++) {
		usersObject[io.sockets.clients(room)[i].chatUserId] = null;
	}

	for(var userId in usersObject) {
		uniqueUsers.push(userId);
	}

	return uniqueUsers.length;
}