var app;

// Try to start with a secure server. If the SSL certificate can't be found, use a regular server.
try{
	var fs = require('fs');
	
	var options = {
		key: fs.readFileSync('/etc/httpd/conf/apps/ssl/h4h.key'),
		cert: fs.readFileSync('/etc/httpd/conf/apps/ssl/h4h.crt'),
		ca: fs.readFileSync('/etc/httpd/conf/apps/ssl/h4h_ca_bundle.crt')
	};

	app = require('https').createServer(options);
}
catch(e) {
	app = require('http').createServer();
}

var io = require('socket.io').listen(app);
app.listen(8001);

var redis = require('redis').createClient();
var users = {};

// Subscribe to these specific Redis channels.
redis.subscribe('entrySaved');
redis.subscribe('fitbitEntrySaved');
redis.subscribe('jawboneEntrySaved');
redis.subscribe('newMessageCreated');
redis.subscribe('newPostCreated');
redis.subscribe('newTeamPostCreated');
redis.subscribe('notificationPublished');
redis.subscribe('newCoordinatorNotification');
redis.subscribe('welcomeBackMessage');
redis.subscribe('userUpdated');
redis.subscribe('promotionUpdated');
redis.subscribe('TeamInviteAccepted');

// Fires whenever anything is published to any Redis channel.
redis.on('message', function(channel, data) {
	var userId;
	var friendId;

	if(typeof data === 'string') {
		data = JSON.parse(data);
	}

	switch(channel) {
		case 'entrySaved':
			userId = data.user_id.toString();
			io.sockets.in('User' + userId).emit('entrySaved', data);
			break;
		case 'fitbitEntrySaved':
			userId = data.user_id.toString();
			io.sockets.in('User' + userId).emit('fitbitEntrySaved', data);
			break;
		case 'jawboneEntrySaved':
			userId = data.user_id.toString();
			io.sockets.in('User' + userId).emit('jawboneEntrySaved', data);
			break;
		case 'newMessageCreated':
			userId = data.user_id.toString();
			friendId = data.friend_id.toString();
			io.sockets.in('User' + userId).emit('newMessageCreated', data);
			io.sockets.in('User' + friendId).emit('newMessageCreated', data);
			break;
		case 'newPostCreated':
			promotionId = data.user.promotion_id.toString();
			io.sockets.in('Promotion' + promotionId).emit('newPostCreated', data);
			break;
		case 'newTeamPostCreated':
			teamId = data.wallable_id.toString();
			io.sockets.in('Team' + teamId).emit('newPostCreated', data);
			break;
		case 'notificationPublished':
			userId = data.user_id.toString();
			io.sockets.in('User' + userId).emit('notificationPublished', data);
			break;
		case 'newCoordinatorNotification':
			promotionId = data.promotion_id.toString();
			io.sockets.in('Promotion' + promotionId).emit('newCoordinatorNotification', data);
			break;
		case 'welcomeBackMessage':
			userId = data.user_id.toString();
			io.sockets.in('User' + userId).emit('welcomeBackPublished', data);
			break;
		case 'userUpdated':
			userId = data.id.toString();
			io.sockets.in('User' + userId).emit('userUpdated', data);
			break;
		case 'TeamInviteAccepted':
			userId = data.user_id.toString();
			io.sockets.in('User' + userId).emit('TeamInviteAccepted', data);
			break;
		case 'promotionUpdated':
			promotionId = data.id.toString();
			io.sockets.in('Promotion' + promotionId).emit('promotionUpdated', data);
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

	// Adds a user to their promotion's room.
	socket.on('addTeamUser', function(data) {
		socket.teamId = data.teamId;
		socket.join('Team' + data.teamId);
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
