# SUIBIZ SUI SMART CONTRACT





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