function onPostFetch(request,response,modules){
	var messagesCollection = modules.collectionAccess.collection("messages");
  var userCollection = modules.collectionAccess.collection("user");
  var info = modules.logger.info;
  
  var username = request.username;
  
  info("fetch all users. uname="+username);
  
  userCollection.findOne({"username":username}, function(err, user) {
    info("fetch all. found user"+user);
    info("err" + err + "/" + user);
  
    if (err) { 
      info("was an err!");
      response.continue();
    } else {
      
      if (user) {
     // info("no err: " + response.body);
      
    	var thisUserId = user._id+"";
     
      
      modules.async.each(response.body, function(aUser, callback) {
          var thatUserId = aUser._id+"";
         info("this user="+thisUserId+" / that user=" + thatUserId);
        messagesCollection.find({"$or":[{"$and":[{"targetUser":thatUserId}, {"_acl.creator":thisUserId}]},{"$and":[{"targetUser":thisUserId}, {"_acl.creator":thatUserId}]}]}, {'_kmd.ect': 1}, function(err,messages){
            info("[" + aUser._id + "] found ("+messages.length+") : "+ err);
            if (!err) {
              aUser.messages = messages;
              info(aUser);
            }
            callback();
          });  
      }, function(err){
      //  info(response.body);
        response.continue();
      });
      } else { 
        response.continue(); }
    }
  });
  
  /*

  var user = response.body;
  
  
  if (user instanceof Array) {
	  modules.logger.info(user);
    response.continue();
  } else {
  
  messagesCollection.find({"$or":[{"targetUser":user._id},{"_acl.creator":user._id}]}, function(err,messages){
		if (!err) {
			response.body.messages = messages;
		}
		response.continue();
	});  
  }
*/
}