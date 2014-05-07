function onPreSave(request, response, modules){
	var beacon = request.body;
  beacon.beaconId = beacon.uuid+"."+beacon.major+"."+beacon.minor;
  request.body = beacon;
  response.continue();
}