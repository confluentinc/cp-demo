#!/bin/bash

fullpath ()
{
  fullPath=$(cd $1 && pwd -P)
  echo $fullPath
  cd $OLDPWD	
}

