function onPreFetch(request, response, modules){
   var logger = modules.logger;
  logger.info(request.params+"/"+request.entityId);
  response.continue();
}