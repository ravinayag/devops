# Install Prereqs
sudo apt update &&  sudo apt install -y nginx golang-go postgresql postgresql-contrib curl unzip \
software-properties-common gnupg2 net-tools

#create Db user and DB
echo "CREATE ROLE sreuser LOGIN ENCRYPTED PASSWORD 'p@ssw0rd';" | sudo -u postgres psql
sudo su postgres -c "createdb sredb --owner sreuser"

#Restart the services
systemctl restart postgresql
systemctl restart nginx

#Consul prereqs - Download
wget https://github.com/mantl/consul-cli/releases/download/v0.3.1/consul-cli_0.3.1_linux_amd64.tar.gz
wget https://releases.hashicorp.com/consul/1.9.5/consul_1.9.5_linux_amd64.zip
unzip consul_1.9.5_linux_amd64.zip -d /usr/local/bin/
tar zxf consul-cli_0.3.1_linux_amd64.tar.gz -C /usr/local/bin/

# Gitrepo for the sourcefiles
git clone https://github.com/ravinayag/sretask.git

#Consul prereqs - warmup
sudo mkdir -p /etc/consul.d 
cp /sretask/consul/*.json /etc/consul.d/

# Build webapi
cd /sretask/api/
sudo mkdir -p bin
sleep 1
echo "Building the Api"
sudo go build src/api/main.go
sleep 10
echo "API Build Completed"
sudo cp main bin/api

echo " pre req tasks completed, Now switching to Consul services start"

