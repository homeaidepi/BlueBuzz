const mongodb = require('mongodb');
const pkg = require('mongodb/package.json');

const uri = 'mongodb://admin:FPSCRUSGLHMHFZFP@portal-ssl1430-52.bmix-dal-yp-0ada527c-7794-4fff-8db1-e965ddf8d2bb.3526967433.composedb.com:24325,portal-ssl1304-53.bmix-dal-yp-0ada527c-7794-4fff-8db1-e965ddf8d2bb.3526967433.composedb.com:24325/compose?authSource=admin&ssl=true'

async function main(params) {
  const driverVersion = pkg.version;
  const client = await mongodb.MongoClient.connect(uri, { useNewUrlParser: true });

  const docs = await client.db('compose').collection('Location').find({"instanceId":params.instanceId}).toArray();
  
  return { body: { result: docs, driverVersion } };
}

exports.main = main;
