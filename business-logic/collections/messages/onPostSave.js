function onPostSave(request, response, modules){

  // NB: This routine should not error out, the message has already been
  // saved so errors are not helpful to the user.  On all errors the error
  // should be logged and response.continue() should be called.

  var users = modules.collectionAccess.collection('user');
  var messages = modules.collectionAccess.collection('messages');
  var objectID = modules.collectionAccess.objectID;
  var push = modules.push;
  var log = {
    I: modules.logger.info,
    W: modules.logger.warn,
    E: modules.logger.error,
    F: modules.logger.fatal
  };

  /** Send a push message using the push module
   *
   *  @param user    -- The user document of the recipient
   *  @param payload -- The APS payload document.
   */
  var sendPush = function(user, payload){
        push.sendPayload(user, payload, {}, {});
  };

  /** Send a customized push message to a user
   *
   * This sends a customized push message to the user, looking
   * up the sender and using a easy to read name in the push message.
   *
   *  @param user    -- The user document of the recipient
   *  @param payload -- The APS payload document.
   */
  var sendPushMessage = function(user, payload){
    // We need to find the "human readable" display name for the sender.
    var query = {
      username: request.username
    };

    users.findOne(query, function(err, sender){
      if (err){
        log.E("There was an issue finding sender: " + JSON.stringify(err.message));
      } else if (!sender){
        log.W("Can't find sender! " + JSON.stringify(query));

        // Send what we have
        payload.alert = request.body.message;
        sendPush(user, payload);
      } else {
        var name = sender.formatted_name;

       if (!name){
          name = "Unknown";
        }

        payload.alert = name + ": " + request.body.message;
        sendPush(user, payload);
      }      
      response.continue();
    });
  };

  /** Notifies the target user of new messages
   *
   * This causes the target user to be notified of new messages, if there is a
   * single message then the user recieves an alert, otherwise the user's
   * app icon badge is updated with the number of messages.
   *
   *  @param userId  -- The userId of the target user
   *  @param user    -- The user document of the target user
   */
  var notifyTargetUser = function(userId, user){

    // We need to find ALL other unread messages for this recipient to see
    // what type of push message we need to send.
    var query = {
      targetUser: userId,
      read: false
    };

    messages.find(query, function(err, messages){
      if (err){
        log.E("There was an issue finding messages: " + JSON.stringify(err.message));
        return response.continue();
      } else if (messages.length === 0){
        log.W("No unread messages for user: " + JSON.stringify(userId));
        return response.continue();
      } else {
        var count = messages.length;
        var APSBody = {badge: count};

        if (count === 1 && request.body.message){
          return sendPushMessage(user, APSBody);
        } else {
          // Send push
          sendPush(user, APSBody);
          return response.continue();
        }
      }
    });
  };


  // We only want to send push notifications on receipt of a new (POST) unread message
  if (request.method.toUpperCase() === "POST"){

    // Who the message is going to
    var targetUser = request.body.targetUser;

    // A well formed message has a targetUser.  If this message is well formed
    // we need to find the underlying user document in order to do any push.
    // This is a query on the 'user' collection.
    if (targetUser) {
      users.findOne({"_id": objectID(targetUser)}, function(err, user) {
        if (err) {
          log.E("There was an error finding the target user's username: " + JSON.stringify(err.message));
          return response.continue();
        } else if (!user){
          log.F("No users found for targetUser " + JSON.stringify(targetUser));
          return response.continue();
        } else {
          if (user.notificationsOn === false){
            // User doesn't want to be notified
            return response.continue();
          } else {
            // We have a target user document and the target user id
            return notifyTargetUser(targetUser, user);
          }
        }
      });
    } else {
      return response.continue();
    }
  } else {
    return response.continue();
  }
}
