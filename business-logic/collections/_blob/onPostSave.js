function onPostSave(request, response, modules){
  var context = modules.backendContext;
  var req = modules.request;
  var uri = 'https://' + request.headers.host + '/blob/'+ context.getAppKey() +'/' + response.body._id;
  var auth = {
    user: context.getAppKey(),
    pass: context.getMasterSecret()
  };

  modules.logger.info("Auth: " + JSON.stringify(auth));
  modules.logger.info("Request: " + JSON.stringify(request));
  modules.logger.info("URI: " + JSON.stringify(uri));
  
  var oldBody = response.body;

  
  req.get({uri: uri, auth: auth}, function(err, res, body){
    if (err){
      return response.error(err);
    } else {
			modules.logger.info("get_body1: " + body);
      var dlurl = JSON.parse(body)._downloadURL;
      modules.logger.info("download url: " + dlurl);
      oldBody._downloadURL = dlurl;
      modules.logger.info("get_body3: " + JSON.stringify(oldBody));
      response.body = oldBody;
			modules.logger.info("get_body2: " + JSON.stringify(response.body));
      return response.complete();
    }
  });
}