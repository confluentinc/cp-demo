#!/bin/bash

# Script to build the kafka-connect-irc connector and move them to the plugin path directory
export PLUGINPATH:="connect-plugins"
# fix for ubuntu sid sometimes linking /bin/sh to /bin/dash
SHELL:=/bin/bash

all: install irc transform gencerts

install:
	if [[ ! -d $(PLUGINPATH) ]]; then mkdir $(PLUGINPATH); fi

irc:
	make install
	mvn clean package -f kafka-connect-irc/pom.xml
	cp -R kafka-connect-irc/target/kafka-connect-irc-4.0.0-package/share/java/kafka-connect-irc $(PLUGINPATH)

transform:
	make install
	mvn clean package -f kafka-connect-transform-wikiedit/pom.xml
	cp -R kafka-connect-transform-wikiedit/target/WikiEditTransformation-3.3.0.jar $(PLUGINPATH)

gencerts:
	cd security && ./create-certs.sh

clean:
	rm -fr $(PLUGINPATH)/kafka-connect-irc
	rm -fr $(PLUGINPATH)/WikiEditTransformation-3.3.0.jar
	rm -fr security/*.crt security/*.csr security/*_creds security/*.jks security/*.srl security/*.key security/*.req

