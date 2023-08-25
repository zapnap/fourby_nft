## FourbyNFT

A simple generative NFT art project with a nice color palette and dynamic graphics that illustrate changes in network state over the course of the mint. Assets built via SVG and stored 100% on-chain.

Deploy contract:

`forge create FourbyNFT --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args "$OWNER_ADDRESS" src/FourbyNFT.sol:FourbyNFT`

Mint a token:

`cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "mintTo(address)" "$OWNER_ADDRESS" --value 0.001ether`

Get token URI (Base64-encoded):

`cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 1`

Decoding the returned value produces some JSON, that includes an encoded SVG image.

Alternatively, you can ask for the SVG directly:

`cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "renderSvg(uint256)(string)" 1`
