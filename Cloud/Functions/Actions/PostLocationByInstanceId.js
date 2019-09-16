const mongodb = require('mongodb');
const pkg = require('mongodb/package.json');
//const uri = 'mongodb://admin:FPSCRUSGLHMHFZFP@portal-ssl1430-52.bmix-dal-yp-0ada527c-7794-4fff-8db1-e965ddf8d2bb.3526967433.composedb.com:24325,portal-ssl1304-53.bmix-dal-yp-0ada527c-7794-4fff-8db1-e965ddf8d2bb.3526967433.composedb.com:24325/compose?authSource=admin&ssl=true'
const uri = 'mongodb://ibm_cloud_36ebc60d_641a_42d5_918d_151d7eddc912:0d913498eb189bb0b73377126dc08ec14d6c7b33986172fa5306775e2b14947e@bec49fc5-5959-4818-8adf-f1388499ca11-0.2adb0220806343e3ae11df79c89b377f.databases.appdomain.cloud:32045,bec49fc5-5959-4818-8adf-f1388499ca11-1.2adb0220806343e3ae11df79c89b377f.databases.appdomain.cloud:32045/ibmclouddb?authSource=admin&replicaSet=replset&ssl=true'
const driverVersion = pkg.version;

async function main(params) {

    const client = await mongodb.MongoClient.connect(uri, { useNewUrlParser: true });

    let doc = { "instanceId": params.instanceId, 
                "deviceId": params.deviceId, 
                "latitude": params.latitude, 
                "longitude": params.longitude,
                "datetime": Date()
    } 

    await client.db('compose').collection('Location').deleteMany({"instanceId":params.instanceId, "deviceId":params.deviceId})
    let result = await client.db('compose').collection('Location').insertOne(doc);
  
    return { body: { result: result, driverVersion } };
}

exports.main = main;
