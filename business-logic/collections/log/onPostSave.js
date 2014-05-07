function onPostSave(request, response, modules){
var push = modules.push, collectionAccess = modules.collectionAccess;
  var logger = modules.logger;
  collectionAccess.collection('user').findOne({"username": request.username}, function (err, User) {
  if (err) {
    logger.error('Query failed: '+ err);
    response.continue();
  } else {
    logger.info('Got User: '+ User.username);
//    userColl.forEach(function (user) {
//      logger.info('Pushing message to ' + user);
//      push.sendMessage(user, "People who are named " + user.firstName + " are awesome!");
//    });
    var location = User.location;
    if (location && location.beacon) {
      var beacon = location.beacon; logger.info('beacon:' +beacon);
      var stalkees = User.favoritePeople; logger.info('stalkees: '+stalkees);
      if (stalkees && stalkees.length) {
        logger.info("here1");
        //var bs = collectionAccess.objectID.apply(stalkees);
        var bs = [];
        stalkees.forEach(function (s) {
          bs.push(collectionAccess.objectID(s));
        });
        logger.info("?i="+bs);
        collectionAccess.collection('user').find({"_id": {"$in":bs}}, function (err, targetUsers) {
              logger.info("here3,"+err+","+targetUsers.length);
              if (err) {
                  logger.error('Query failed: '+ err);
              } else {
                  logger.info('Got users: '+ targetUsers);
                  targetUsers.forEach(function (user) {
                      logger.info('Pushing message to ' + user);
                      //push.sendMessage(user, "People who are named " + user.firstName + " are awesome!");
                    //TODO: even w/o push have message waiting
                  }); 
              }
              response.continue();
         });
      } else {
         logger.info("here2");
         response.continue();
      }
    } else {
       response.continue();
    }
  }
    
});
}