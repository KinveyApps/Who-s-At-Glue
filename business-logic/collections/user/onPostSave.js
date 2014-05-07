function onPostSave(request,response,modules) {

	var async = modules.async;

	var getMessages = function(callback) {
		var messagesCollection = modules.collectionAccess.collection("messages");
		var user = response.body;
		messagesCollection.find({"targetUser":user._id, "read":false}, function(err,messages){
			if (!err) {
				response.body.unreadMessages = messages;
			}
			callback(null, null);
		});
	}

	var callback = function(error, results) {
    if (error) {
      response.body = {error: error.message};
      response.complete(400);
      return;
    } else {
	    response.complete(200);
	    return;
	  }
  };

  async.parallel([getMessages], callback);
}

