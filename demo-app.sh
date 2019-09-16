#!/bin/bash
#
# This script installs and configures a tomcat app which simulates various attacks 
# for the Deep Security agent to detect.
#

set -exo pipefail

# Run with root privileges
if [ $(/usr/bin/id -u) -ne 0 ]; then
  echo -e "You are not running as the root user.  Please try again with root privileges."
  exit 1
fi

# Vars
GITHUB_REPO=https://github.com/deep-security/demo-app
TOMCAT_HOME=/opt/tomcat
TOMCAT_DOWNLOAD_URL=https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.45/bin/apache-tomcat-8.5.45.tar.gz
TOMCAT_PACKAGE_NAME=$(echo "$TOMCAT_DOWNLOAD_URL" | awk -F'/' '{print $NF}' | sed 's|.tar.gz$||')
TOMCAT_PORT=80

# Apt get install with retries.
aptGetInstall()
{
set +e

TIME=0
DELAY=30
TIMEOUT=1200
while true; do
    apt-get -qq -y install $*
    [ $? -eq 0 ] && break
    echo "Time: $TIME sec(s)"
    sleep $DELAY
    TIME=$(expr $TIME + $DELAY)
    [ $TIME -ge $TIMEOUT ] && exit 1
    apt-get clean && apt-get update
done

set -e
}

# Install pre-requisites
apt-get clean && apt-get update
aptGetInstall default-jdk default-jre

# Create Tomcat user
if ! id -u tomcat >> /dev/null 2>&1; then
  useradd -r -m -U -d $TOMCAT_HOME -s /bin/false tomcat
fi

# Download and extract Tomcat
wget "$TOMCAT_DOWNLOAD_URL" -P /tmp
tar -C $TOMCAT_HOME -zxf /tmp/${TOMCAT_PACKAGE_NAME}.tar.gz

# Change directory ownership and make scripts executable
chown -R tomcat: $TOMCAT_HOME/$TOMCAT_PACKAGE_NAME
sh -c "chmod +x $TOMCAT_HOME/$TOMCAT_PACKAGE_NAME/bin/*.sh"

# Create link to latest tomcat install
ln -s $TOMCAT_HOME/$TOMCAT_PACKAGE_NAME/ $TOMCAT_HOME/latest

# Install the Demo app.
[ -f demo-app.zip ] || wget $GITHUB_REPO/archive/master.zip -O demo-app.zip
aptGetInstall zip
unzip -o demo-app.zip -d demo-app/
find demo-app/ -name "demo-app.war" -exec cp {} $TOMCAT_HOME/latest/webapps/ \;

# Change tomcat port from default 8080 to 80.
sed -i '/\s.*<Connector port="8080" protocol="HTTP/s|"8080"|"'$TOMCAT_PORT'"|g' $TOMCAT_HOME/latest/conf/server.xml

# Start tomcat
nohup $TOMCAT_HOME/latest/bin/startup.sh &
sleep 2

exit 0
