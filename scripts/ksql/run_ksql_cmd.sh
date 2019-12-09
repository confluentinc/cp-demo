#!/bin/bash

echo -e "$1\nexit" | ksql http://ksql-server:8088
