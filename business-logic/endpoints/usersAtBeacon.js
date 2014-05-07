function onRequest(request, response, modules) {
  var logger = modules.logger;
  var collectionAccess = modules.collectionAccess;
  var userCollection = collectionAccess.collection('user');
  var messagesCollection = collectionAccess.collection('messages');
  var body = request.body;
  var timeframe = body.sincetime;
  var beacon = body.beaconId;
  var notlurking = {"$or":[{"lurking":{"$exists":false}},{"lurking":false}]};
  var hasName = {"$or":[{"formatted_name":{"$exists":true}},{"first_name":{"$exists":true}}]};

  var query = {"$and": [notlurking, hasName]};

  if (beacon !== "ALL"){
    query.$and.push({"nearestBeacon.id":beacon});
    query.$and.push({"nearestBeacon.timestamp":{"$gt":timeframe}});
  }


  var fields = {
    "fields": {
      "_id": 1,
      "formatted_name":1,
      "first_name":1,
      "last_name":1,
      "nearestBeacon":1,
      "headline":1,
      "talkInterests":1,
      "pictureUrl":1,
      "pictureLMT":1,
      "event":1
    }
  };

  //TODO: also limit by event
  
  var username = request.username;
  
  
  userCollection.find(query, fields, function(err, users){
    if (err) {
      modules.logger.error("Saw an error " + JSON.stringify(err.message));
      response.error(err);
    } else {
      findMe(username, users, response, modules);
    }
  });
}

function findMe(username, users, response, modules) {
  var info = modules.logger.info;
  var warn = modules.logger.warn;
  var collectionAccess = modules.collectionAccess;
  var userCollection = collectionAccess.collection('user');
  var messagesCollection = collectionAccess.collection('messages');
  
  userCollection.findOne({"username":username}, function(err, user) {
    info("fetch all. found user: "+user.username);
    info("err: " + err + "/user: " + user._id);
    
    if (err) { 
      warn("was an err!");
      response.body = users;
      response.complete(200);
    } else {
      
      if (user){
       	var uid = user._id+"";
        var query = {"$or": [{targetUser: uid}, {"_acl.creator": uid}]};
        messagesCollection.find(query, {"_kmd.ect": 1}, function(err, coll){
          if (err){
            return response.error(err);
          } else if (coll.length === 0){
            response.body = users;
            return response.complete();
          } else {
            var j = 0;
            var i = 0;
            for (j = 0; j < users.length; j++){
              var updatedUser = users[j];
              var userOfInterest = updatedUser._id+"";
              if (!updatedUser.messages){
                updatedUser.messages = [];
              }

              for (i = 0; i < coll.length; i++){
                var creator = coll[i]._acl.creator;
                var target = coll[i].targetUser;

                if (creator === userOfInterest || target === userOfInterest){
                  updatedUser.messages.push(coll[i]);
                }
              }
              users[j] = updatedUser;
            }
            response.body = users;
            response.complete();
          }
        });
      } else {
      	warn("Second case");
        response.body = users;
        response.complete(200);
      }        
    }
  });
}
