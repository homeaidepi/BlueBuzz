#!/bin/bash

##########
# Deploy Script
# for deploying to servers that don't have git or ssh access
# RUN THIS FROM A VAGRANT SSH IF YOU AREN'T ON LINUX ALREADY.
##########

# prevents the certificate verification error.
# sudo echo "set ssl:verify-certificate no" > ~/.lftp/rc
# sudo echo "set ftp:ssl-allow no" >> ~/.lftp/rc

REMOTEPATH='/site/wwwroot/'
LOCALPATH='./'

FTPUSER='fijihome\$fijihome'
FTPPASS='JphwrrdHQKvCJ8kt8cS7bbaHBGEnmPicEyKmG2pXgyhzT9gtAbS9bHjuNm0S'
FTPHOST='waws-prod-blu-011.ftp.azurewebsites.windows.net'

#add as many as you want, this will prevent matching files from being removed from / overwritten / copied to the other side.
EXCLUDES='--exclude-glob .git .DS_Store --exclude-glob _sess/*  --exclude-glob uploads/* --exclude-glob deploy.sh'

#careful with this, it will delete all the cpanel stuff if you point it to the root folder on the remote ftp without excluding them all.
DELETE='' #don't delete anything, just overwrite or add.
#DELETE=' --delete' #deletes ANYTHING on the remote that isn't in the local, other than the EXCLUDES.

#Do the thing.
lftp -c "set ftp:list-options -a; open ftp://$FTPUSER:$FTPPASS@$FTPHOST; lcd $LOCALPATH; cd $REMOTEPATH; mirror --reverse $DELETE --use-cache --verbose --no-umask --parallel=3 $EXCLUDES"