#!/bin/bash

echo "This example uses real Confluent Cloud resources."
echo "To avoid unexpected charges, carefully evaluate the cost of resources before launching the script and ensure all resources are destroyed after you are done running it."
echo "(Use Confluent Cloud promo ``C50INTEG`` to receive $50 free usage)"
read -p "Do you still want to run this script? [y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  exit 1
fi

# Create ccloud-stack
wget -O ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/utils/ccloud_library.sh
source ./ccloud_library.sh
ccloud::create_ccloud_stack

# Create parameters customized for Confluent Cloud instance created above
wget -O ccloud_library.sh https://raw.githubusercontent.com/confluentinc/examples/latest/ccloud/ccloud-generate-cp-configs.sh
./ccloud-generate-cp-configs.sh ./stack-configs/java*.cfg

return 0
