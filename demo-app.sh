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
TOMCAT_DOWNLOAD_URL=https://www-eu.apache.org/dist/tomcat/tomcat-8/v8.5.43/bin/apache-tomcat-8.5.43.tar.gz
TOMCAT_PACKAGE_NAME=$(echo "$TOMCAT_DOWNLOAD_URL" | awk -F'/' '{print $NF}' | sed 's|.tar.gz$||')
TOMCAT_PORT=80

# Apt get install with retries.
aptGetInstall()
{
set +e

TIME=0
DELAY=30
TIMEOUT=300
while true; do
    apt-get -qq -y install $*
    [ $? -eq 0 ] && break
    echo "Time: $TIME sec(s)"
    sleep $DELAY
    TIME=$(expr $TIME + $DELAY)
    [ $TIME -ge $TIMEOUT ] && exit 1
done

set -e
}

# Install pre-requisites
apt-get update
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

# Create a systemd unit file
cat << EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat 9 servlet
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/default-java"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

# Install the Demo app.
[ -f demo-app.zip ] || wget $GITHUB_REPO/archive/master.zip -O demo-app.zip
aptGetInstall zip
unzip -o demo-app.zip -d demo-app/
find demo-app/ -name "demo-app.war" -exec cp {} $TOMCAT_HOME/latest/webapps/ \;

# Change tomcat port from default 8080 to 80.
sed -i '/\s.*<Connector port="8080" protocol="HTTP/s|"8080"|"'$TOMCAT_PORT'"|g' $TOMCAT_HOME/latest/conf/server.xml

# Notify systemd of the new service.
systemctl daemon-reload

# Start and check if tomcat service is active
systemctl start tomcat
sleep 5 && systemctl is-active tomcat

# Launch Tomcat on boot
systemctl enable tomcat

exit 0