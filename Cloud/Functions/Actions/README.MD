## NodeJS Actions

### sign in ibm cli using sso
```
$ ibmcloud login --sso
```
1. press Y to go to browser for one-time code
1. copy from browser the one time code, paste in terminal
1. select the correct account
```
$ ibmcloud resource group
```
```
$ ibmcloud target -g Default
```
```
$ ibmcloud plugin install cloud-functions
```
```
$ ibmcloud target -o matthew.vandergrift@homeaidepi.com -s prod
```

API endpoint:      https://cloud.ibm.com   
Region:            us-south   
User:              matthew.vandergrift@homeaidepi.com   
Account:           Matthew Vandergrift's Account (68f695d632b045dd9f1c7c25f9754c8d) <-> 1970154   
Resource group:    No resource group targeted, use 'ibmcloud target -g RESOURCE_GROUP'   
CF API endpoint:   https://api.ng.bluemix.net (API version: 2.128.0)   
Org:               matthew.vandergrift@homeaidepi.com   
Space:             prod   


### Create Package

```
$ bx wsk package create BlueBuzzPackage
```

### GetChangeLogByVersion action

```
$ bx wsk action create BlueBuzzPackage/GetChangeLogByVersion GetChangeLogByVersion.js --main GetChangeLogByVersion --kind nodejs:10
```

### Retrieve file contents action

```
$ bx wsk action create BlueBuzzPackage/GetLocationByInstanceId GetLocationByInstanceId.js --main GetLocationByInstanceId --kind nodejs:10
```

### Remove files from bucket action

```
$ bx wsk action create BlueBuzzPackage/CheckDistanceByInstanceId CheckDistanceByInstanceId.js --main CheckDistanceByInstanceId --kind nodejs:10
```

### Create new files action

```
$ npm install
$ zip -r upload.zip package.json actions.js node_modules
$ bx wsk action create BlueBuzzPackage/upload-file upload.zip --main upload --kind nodejs:10
```

### Modify object acls action

```
$ bx wsk action create BlueBuzzPackage/make-public actions.js --main make_public --kind nodejs:10
$ bx wsk action create BlueBuzzPackage/make-private actions.js --main make_private --kind nodejs:10
```

### Generate presigned URLs

- **Provision HMAC authentication keys and save credentials to `credentials.json`.**

```
$ cd presign
```
```
$ npm install
```
```
$ zip -r presign.zip package.json presign.js node_modules
```
```
$ bx wsk action create BlueBuzzPackage/presign presign.zip --main presign --kind nodejs:10 -P credentials.json
```