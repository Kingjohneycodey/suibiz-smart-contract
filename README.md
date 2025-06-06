# SUIBIZ SUI SMART CONTRACT


https://faucet.sui.io/?address=0x035cfedb0f92c792cbf29f560e7e0f333e326102836d4073c843e1af372472ec

local wallet address

0x035cfedb0f92c792cbf29f560e7e0f333e326102836d4073c843e1af372472ec


package id


0x0f109a3e96d6890a9ffdd7f2c99953232374139f4f8cfcdd539d4a0d29752ac8


marketplace

0x2cb40341df91ad80a4f5b5ade5936f87d7a22e8f4e1db7808b8e22589577912b


registry

0xeb0e56de50680e693e7fb4acb59647cb43ef6ab3bfff239283c7ddfefe77a23c




sui client publish --gas-budget 100000000


sui client call --package 0x0f109a3e96d6890a9ffdd7f2c99953232374139f4f8cfcdd539d4a0d29752ac8 --module marketplace --function create_and_init_marketplace --gas-budget 10000000




sui client call \
  --function list_product \
  --module marketplace \
  --package 0x0f109a3e96d6890a9ffdd7f2c99953232374139f4f8cfcdd539d4a0d29752ac8 \
  --args \
    0x2cb40341df91ad80a4f5b5ade5936f87d7a22e8f4e1db7808b8e22589577912b \
    "man shirt" \
    1000 \
    "collectibles" \
    "yam" \
    "ghhh" \
    "https://picsum.photos/seed/101/500/500" \
    34 \
  --gas-budget 10000000





sui client objects --filter Coin

sui client call \
  --package 0x7352fc3f351fa71b6cf0c79e7996034fef8730d286fbd6e6b64b000fc26e9cbc \
  --module marketplace \
  --function purchase_product \
  --args \
    0xdf126abe0e38eeb403683da6628b4406bf2aab4b61a6519896f811ee77bce411 \
    0x7f21d6e39832e959ff626b37ae0ffc4a9371bba181687d7f671112842367bd1e \
    2 \
    0x665c4d2685a318633a2ea0ecdc14c0962702c40aa137be33e596c4e544af7cd5 \
  --gas-budget 100000000







sui client call \
  --function init_registry \
  --module user \
  --package <PACKAGE_ID> \
  --args \
  --gas-budget 10000000




  sui client call \
  --function create_user_profile \
  --module user \
  --package <PACKAGE_ID> \
  --args <REGISTRY_ID> \
  "John Doe" \
  "johndoe" \
  "Blockchain developer" \
  "https://avatar.com/john" \
  "123 Main St" \
  --gas-budget 10000000


  sui client call \
  --function get_profile_id \
  --module user \
  --package <PACKAGE_ID> \
  --args <REGISTRY_ID> <USER_ADDRESS> \
  --gas-budget 10000000


  sui client objects