const mongodb = require('mongodb');
const pkg = require('mongodb/package.json');
const uri = 'mongodb://admin:FPSCRUSGLHMHFZFP@portal-ssl1430-52.bmix-dal-yp-0ada527c-7794-4fff-8db1-e965ddf8d2bb.3526967433.composedb.com:24325,portal-ssl1304-53.bmix-dal-yp-0ada527c-7794-4fff-8db1-e965ddf8d2bb.3526967433.composedb.com:24325/compose?authSource=admin&ssl=true'
const driverVersion = pkg.version;

async function main(params) {

    const client = await mongodb.MongoClient.connect(uri, { useNewUrlParser: true });
    
    let email = params.email == null ? '' : params.email;

    let doc = { "instanceId": params.instanceId, 
                "givenName": params.givenName, 
                "familyName": params.familyName, 
                "age": params.age,
                "email": email,
                "comment": params.comment,
                "version": params.version,
                "datetime": Date()
    };

    //delete any previous comments
    //await client.db('compose').collection('Feedback').deleteMany({"instanceId":params.instanceId, "deviceId":params.deviceId})
    let result = await client.db('compose').collection('Feedback').insert(doc);
  
    return { body: { result: result, driverVersion } };
}

exports.main = main;
