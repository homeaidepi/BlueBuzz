# NodeJS Actions

# sign in ibm cli using sso
ibmcloud login --sso

ibmcloud resource group

ibmcloud target -g Default

ibmcloud plugin install cloud-functions

ibmcloud target -o matthew.vandergrift@homeaidepi.com -s dev

# API endpoint:      https://cloud.ibm.com   
# Region:            us-south   
# User:              matthew.vandergrift@homeaidepi.com   
# Account:           Matthew Vandergrift's Account (68f695d632b045dd9f1c7c25f9754c8d) <-> 1970154   
# CF API endpoint:   https://api.ng.bluemix.net (API version: 2.128.0)   
# Org:               matthew.vandergrift@homeaidepi.com   
# Space:             dev   

# Create Package
bx wsk package create BlueBuzzPackage

# GetChangeLogByVersion action
bx wsk action create BlueBuzzPackage/GetChangeLogByVersion GetChangeLogByVersion.js --main GetChangeLogByVersion --kind nodejs:10

# GetLocationByInstanceId action
bx wsk action create BlueBuzzPackage/GetLocationByInstanceId GetLocationByInstanceId.js --main GetLocationByInstanceId --kind nodejs:10

# CheckDistanceByInstanceId action
bx wsk action create BlueBuzzPackage/CheckDistanceByInstanceId CheckDistanceByInstanceId.js --main CheckDistanceByInstanceId --kind nodejs:10

# PostLocation action
bx wsk action create BlueBuzzPackage/PostLocationByInstanceId PostLocationByInstanceId.js --main PostLocationByInstanceId --kind nodejs:10

# PostComment action
bx wsk action create BlueBuzzPackage/PostComment PostComment.js --main PostComment --kind nodejs:10
