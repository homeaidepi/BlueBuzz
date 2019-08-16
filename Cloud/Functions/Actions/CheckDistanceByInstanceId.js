/**
  *
  * main() will be run when you invoke this action
  *
  * @param Cloud Functions actions accept a single parameter, which must be a JSON object.
  *
  * @return The output of this action, which must be a JSON object.
  *
  */
  
 const mongodb = require('mongodb');
 const pkg = require('mongodb/package.json');
 
 const uri = 'mongodb://admin:FPSCRUSGLHMHFZFP@portal-ssl1430-52.bmix-dal-yp-0ada527c-7794-4fff-8db1-e965ddf8d2bb.3526967433.composedb.com:24325,portal-ssl1304-53.bmix-dal-yp-0ada527c-7794-4fff-8db1-e965ddf8d2bb.3526967433.composedb.com:24325/compose?authSource=admin&ssl=true'
 
 async function main(params) {
   const driverVersion = pkg.version;
   const client = await mongodb.MongoClient.connect(uri);
 
   const watchosRecord = await client.db('compose').collection('Location').findOne({"instanceId":params.instanceId, "deviceId":"watchos"});
   const iphoneRecord = await client.db('compose').collection('Location').findOne({"instanceId":params.instanceId, "deviceId":"ios"});
   
   var lat1="",long1="",lat2="",long2 = ""
   var distance = 0;
   
   if (watchosRecord) {
     lat1 = watchosRecord.latitude;
     long1 = watchosRecord.longitude;
   }
   
   if (iphoneRecord) {
     lat2 = iphoneRecord.latitude;
     long2 = iphoneRecord.longitude;
   }
   
   if (watchosRecord && iphoneRecord) {
       distance = calcDistance(lat1, long1, lat2, long2, 'F');
   }
    
   return { distance: distance, body: { 
       lat1: lat1,
       long1: long1,
       lat2: lat2, 
       long2: long2,
       distance: distance, 
       driverVersion } };
 }
 
 exports.main = main;
 
 //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
 //:::                                                                         :::
 //:::  This routine calculates the distance between two points (given the     :::
 //:::  latitude/longitude of those points). It is being used to calculate     :::
 //:::  the distance between two locations using GeoDataSource (TM) prodducts  :::
 //:::                                                                         :::
 //:::  Definitions:                                                           :::
 //:::    South latitudes are negative, east longitudes are positive           :::
 //:::                                                                         :::
 //:::  Passed to function:                                                    :::
 //:::    lat1, lon1 = Latitude and Longitude of point 1 (in decimal degrees)  :::
 //:::    lat2, lon2 = Latitude and Longitude of point 2 (in decimal degrees)  :::
 //:::    unit = the unit you desire for results                               :::
 //:::           where: 'M' is statute miles (default)                         :::
 //:::                  'K' is kilometers                                      :::
 //:::                  'N' is nautical miles                                  :::
 //:::                                                                         :::
 //:::  Worldwide cities and other features databases with latitude longitude  :::
 //:::  are available at https://www.geodatasource.com                         :::
 //:::                                                                         :::
 //:::  For enquiries, please contact sales@geodatasource.com                  :::
 //:::                                                                         :::
 //:::  Official Web site: https://www.geodatasource.com                       :::
 //:::                                                                         :::
 //:::               GeoDataSource.com (C) All Rights Reserved 2018            :::
 //:::                                                                         :::
 //:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
 
 function calcDistance(lat1, lon1, lat2, lon2, unit) {
     if ((lat1 == lat2) && (lon1 == lon2)) {
         return 0;
     }
     else {
         var radlat1 = Math.PI * lat1/180;
         var radlat2 = Math.PI * lat2/180;
         var theta = lon1-lon2;
         var radtheta = Math.PI * theta/180;
         var dist = Math.sin(radlat1) * Math.sin(radlat2) + Math.cos(radlat1) * Math.cos(radlat2) * Math.cos(radtheta);
         if (dist > 1) {
             dist = 1;
         }
         dist = Math.acos(dist);
         dist = dist * 180/Math.PI;
         dist = dist * 60 * 1.1515;
         if (unit=="K") { dist = dist * 1.609344 }
         if (unit=="N") { dist = dist * 0.8684 }
         if (unit=="F") { dist = dist * 5280 }
         return dist;
     }
 }
 