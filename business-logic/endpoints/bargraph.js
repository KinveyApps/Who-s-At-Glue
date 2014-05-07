function onRequest(request, response, modules){
  var collectionAccess = modules.collectionAccess;
  var logger = modules.logger;
  var input = request.body;
  var logs = collectionAccess.collection('log');
  
  var getStartDate = function(moment){
	  var adjustedDate = moment.subtract('days', 3)
  	                         .set('hour',        0)
    	                       .set('minute',      0)
      	                     .set('second',      0)
        	                   .set('millisecond', 0);
	  var date = new Date(moment.toDate());
	  var string = 'ISODate("' + date.toISOString() + '")';
    
	  return string;
	};

  // Map function
  var map = function(){
    // Bin timestamp
    var outputTime = this.timestamp;

    if (outputTime.substring(0, 7) === "ISODate"){
      // Format is 'ISODate("2014-02-26T19:45:22.211Z")
      //            0123456789 ...               ... 21
      // Strip down to date and time
      outputTime = outputTime.substring(9, outputTime.length-2);
    }

    var parts = outputTime.split(':');

    // Bin the time to the nearest 30 mintues
    var bin = (parts[1] >= 30) ? "30" : "00";
    outputTime = parts[0] + ':' + bin + ':00.000Z';

    // Make it a real ISO date
    outputTime = new Date(outputTime);

    var outputObject = {
      "beacon": this.beacon,
      "user": this.user
    };

    // Emit the time and beacon info
    emit(outputTime.getTime(), outputObject);
  }


  // Reduce function
  // We're already binned by time, now we
  // just need to bin by beacon
  var reduce = function(timeBin, logs){
    var beaconMap = {};
    
    var beacon, key;
    var i = 0;

    // Bin the beacons
    for (i = 0; i < logs.length; i++){
      beacon = logs[i].beacon;
      beaconMap[beacon] ? beaconMap[beacon]++ : beaconMap[beacon] = 1;
    }

    return beaconMap;

  }

  
  // Finialize Function
  // Reduce isn't called on keys that have a
  // single value, finalize needs to normalize
  // these k/v groups.
  // NB: This is probably because we're cheating with how we're using M/R
  //     a bit.

  // NB2: We need this, but KDS doesn't support this, we'll have to
  // "do it live".
  var finalize = function(key, value){
    var newValue = {};

    // If we've still got a user at this point, we've got a single value
    // entity and need to convert it
    if (value.hasOwnProperty("user")){
      newValue[value.beacon] = 1;
    } else {
      newValue = value;
    }

    return newValue;
  }


  var now = modules.moment();
  var startTime = getStartDate(now);
//  var query = {"beacon": {"$exists": true}, "timestamp": {"$gte": 'ISODate("2014-04-05T00:00:00Z")'}};
  var query = {"beacon": {"$exists": true}, "timestamp": {"$gte": startTime}};
  var options = {
    query: query,       // This doesn't actually seem to work due to a difference between KDS and KBL
    finalize: finalize,
    out: {inline: 1}
  };

  logs.mapReduce(map, reduce, options, function(err, collection) {
    // Mapreduce ret
    if (err)  {
      response.error(err);
      return;
    }
  
    /* Format of collection
    {
    "_id": "2014-04-08T22:30:00.000Z",
        "value": {
          "F7826DA6-4FA2-4E98-8024-BC5B71E0893E.33225.41140": 5,
          "F7826DA6-4FA2-4E98-8024-BC5B71E0893E.22197.44518": 4
        }
    },
    {
    "_id": "2014-04-08T23:00:00.000Z",
        "value": {
          "beacon": "F7826DA6-4FA2-4E98-8024-BC5B71E0893E.22197.44518",
          "user": "5344197e7d245f09031c5d05"
        }
    },
    */

    var logCount = function(out, beacon, ts, users){
      if (out[beacon]){
        out[beacon].timestamps.push(ts);
        out[beacon].users.push(users);
      } else {
        out[beacon] = {
          timestamps: [ts],
          users: [users]
        };
      }

      return out;
    };

    var out = {};
    var i, val;
    var beacon, ts, rec, users;
    for (i = 0; i < collection.length; i++){
      rec = collection[i];

      ts = rec._id;

      // Handle the 1 beacon, 1 user case
      if (rec.value.hasOwnProperty("user")){
        beacon = rec.value.beacon;
        users = 1;
        out = logCount(out, beacon, ts, users);
      } else {
        for (val in rec.value){
          // Val can be undefined here (string, value? not sure)
          // This is due to the query not looking like it's working.
          // If this is a problem we can check
          if (rec.value.hasOwnProperty(val)){
            beacon = val;
            users = rec.value[val];
            out = logCount(out, beacon, ts, users);
          }
        }
      }
    }

    response.body = out;
    response.complete(200);
  });
}
