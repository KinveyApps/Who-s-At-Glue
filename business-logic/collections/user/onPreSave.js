function onPreSave(request,response,modules){
//  modules.logger.info(request.method);
  
  delete request.body.messages;
  
	if (request.method.toUpperCase() === "POST") {
		//this is a new user
    //todo - fix this
    request.body.event = "Kinvey";
		var user = request.body;
		if (hasLinkedInCredentials(user)) {
      fetchLinkedInCrednetials(user,modules,request,response);
    } else {
    	response.continue(); //do nothing if this is a regular username&password user 
    }
	} else {
    updateLog(request,response,modules);
	}
  
}

function hasLinkedInCredentials(user) {
   return user && user._socialIdentity && user._socialIdentity.linkedIn;
}

function fetchLinkedInCrednetials(user,modules,request,response) {
  var logger = modules.logger;
	var linkedIn = user._socialIdentity.linkedIn;
  //TODO test picture URL - original size
	var URL = "https://api.linkedin.com/v1/people/~:(first-name,last-name,headline,formatted-name,email-address,picture-urls::(original))?secure-urls=true&format=json";
	var oauth = 
        { consumer_key: "77cdl7j7gegcic"
        , consumer_secret: "8WjPL8fHRqFNDCDU"
        , token: linkedIn.access_token
        , token_secret: linkedIn.access_token_secret
        };
  modules.request.get({url:URL, oauth:oauth, json:true}, function (e, r, linkedInInfo) {
    logger.info("l"+JSON.stringify(linkedInInfo));
    if (linkedInInfo) {
      var incomingUser = request.body;
      if (linkedInInfo.firstName && !user.first_name) {user.first_name = linkedInInfo.firstName;};
      if (linkedInInfo.lastName && !user.last_name) {user.last_name = linkedInInfo.lastName;};
      if (linkedInInfo.formattedName && !user.formatted_name) {user.formatted_name = linkedInInfo.formattedName;};
      if (linkedInInfo.emailAddress && !user.email) {user.email = linkedInInfo.emailAddress;};
      if (linkedInInfo.headline && !user.headline) {user.headline = linkedInInfo.headline;};
      if (linkedInInfo.pictureUrls) {
        var urls = linkedInInfo.pictureUrls;
        if (urls._total) {
          var url = urls.values[0];
          if (url) {
            user.pictureUrl = url;
            user.pictureLMT = new Date();
          }
        }
      } else {
      	if (linkedInInfo.pictureUrl && !user.pictureUrl) {user.pictureUrl = linkedInInfo.pictureUrl;};      
      }
      logger.info("u"+JSON.stringify(user));
      request.body = user;
    }
    response.continue();
  });
}

function updateLog (request, response, modules) {
  var collectionAccess = modules.collectionAccess;
  var nearestBeacon = request.body.nearestBeacon;
  if (nearestBeacon) {
    var _id = collectionAccess.objectID(request.body._id);
    collectionAccess.collection('user').findOne({"_id":_id}, function(error, user){
      if (error) {
        modules.logger.error("Error seen: " + JSON.stringify(error.message));
        response.error(error);
//        response.body.error = error;
//        response.complete(400);
      } else {
        if (nearestBeacon != user.nearestBeacon) {
//          modules.logger.info("nb:"+JSON.stringify(nearestBeacon));
          var beaconInfo = {};
          beaconInfo.beacon = nearestBeacon.id;
          beaconInfo.user = request.body._id;
          beaconInfo.accuracy = nearestBeacon.accuracy;
          beaconInfo.timestamp = nearestBeacon.timestamp;
          var entry = modules.utils.kinveyEntity(beaconInfo);
          collectionAccess.collection('log').insert(entry, function(error,user){
            if (error) modules.logger.error(error);
            response.continue();
          });
        };
      }
    });
  } else {
    response.continue();
  }
}