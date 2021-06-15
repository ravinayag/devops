#Get the interface and start the service 
BIND=`ifconfig ens4 | grep "mask" | awk '{ print $2 }'`
/usr/local/bin/consul agent -dev  -enable-script-checks -config-dir="/etc/consul.d" -client=$BIND  >> /var/log/consul.log 2>&1 &

#start webAPI services
/sretask/api/bin/api --config-file /sretask/api/config.sample.json >> /var/log/webapi.log 2>&1 &

lsof -nPi | grep LISTEN  
echo "Consul Services started"

# Get the service account
echo ${SVC_ACCOUNT_KEY} | base64 -d > /etc/sretask-4461.json

# Authentication
export GOOGLE_APPLICATION_CREDENTIALS=/etc/sretask-4461.json
gcloud auth activate-service-account --key-file=/etc/sretask-4461.json

echo "Copying the Domain static files"
# Copy the static files into google cloud bucket named "dom_bucket"
#gsutil cp /sretask/public/* gs://${dom_bucket}/
gsutil -m rsync -r /sretask/public gs://${dom_bucket}/

#Making all objects in a bucket publicly readable
#gsutil iam ch allUsers:objectViewer gs://${dom_bucket}

# Scrpt for posgres db backup 
# Backup with Retention period
#gsutil retention set 15d gs://${dom_bucket}

sudo  mkdir -p /backup
sudo touch /backup/pgsql.log

cat <<EOF | sudo tee /pgdbbackup.sh
#!/bin/bash


dateinfo="`date '+%Y-%m-%d %H:%M:%S'`"
timeslot="`date '+%Y%m%d%H%M'`"
echo "Starting backup of databases  - $dateinfo" >> /backup/pgsql.log
sudo -u postgres /usr/bin/pg_dumpall -U postgres > /backup/postgres-db-backup-{dateinfo}.sql
echo "Done backup of databases - $dateinfo " >> /backup/pgsql.log
sleep 3
sudo export GOOGLE_APPLICATION_CREDENTIALS=/etc/sretask-4461.json
sudo gcloud auth activate-service-account --key-file=/etc/sretask-4461.json
sudo gsutil -m rsync -r /backup/ gs://{stor_bucket}
EOF
chmod 755 /pgdbbackup.sh
sleep 2
sed -i -e "s/{stor_bucket}/${dom_bucket}/g" /pgdbbackup.sh
sleep 3
cat <<EOF | sudo tee /cronjob.txt
0 03 * * * /pgdbbackup.sh > /backup/pgsql.log 2>&1
EOF
sleep 3
crontab /cronjob.txt
crontab -l 

#rm /consul-cli*.tar.gz /consul*.zip /cronjob.txt


###  end  of the script ### 