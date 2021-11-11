
#!/bin/bash


# Define Tomcat's variables
APACHE_HOME=/opt/tomcat
APACHE_BIN=$APACHE_HOME/bin
APACHE_WEBAPPS=$APACHE_HOME/webapps

# Define product's variables
PRODUCT_SNAPSHOT_NAME=calculator.war
RESOURCE_NAME=calculator.war


# Shutdown Tomcat
sh $APACHE_BIN/shutdown.sh


# Deploy generated SNAPSHOT into the dev-env  
sudo cp /vagrant_target/$PRODUCT_SNAPSHOT_NAME $APACHE_WEBAPPS
cd $APACHE_WEBAPPS

#mkdir $RESOURCE_NAME
#cp $PRODUCT_SNAPSHOT_NAME $RESOURCE_NAME
sudo mv $PRODUCT_SNAPSHOT_NAME $RESOURCE_NAME
sudo chown tomcat:tomcat $RESOURCE_NAME
#rm $PRODUCT_SNAPSHOT_NAME
#cd $RESOURCE_NAME
#sudo jar -xvf $PRODUCT_SNAPSHOT_NAME.war

# Start up Tomcat
sh $APACHE_BIN/startup.sh
