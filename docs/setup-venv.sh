#!/usr/bin/env bash

# Ensure we are building using the correct Sphinx versions as other versions might not work
if [ -z "$VIRTUAL_ENV" ]; then
  VENV_DIR=/tmp/docs-ansible-venv

  if [ ! -d $VENV_DIR ]; then
    python3 -m venv $VENV_DIR
  fi

  source $VENV_DIR/bin/activate
fi

pip install -U pip setuptools
pip install -r requirements.txt
