## FourbyNFT

**Example generative NFT art project with assets stored 100% on-chain (SVGs)**

Deploy contract:

`forge create FourbyNFT --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --constructor-args "$OWNER_ADDRESS" src/FourbyNFT.sol:FourbyNFT`

Mint a token:

`cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $CONTRACT_ADDRESS "mintTo(address)" "$OWNER_ADDRESS" --value 0.001ether`

Get token URI (Base64-encoded):

`cast call --rpc-url $RPC_URL $CONTRACT_ADDRESS "tokenURI(uint256)(string)" 1`

Decoding the returned value produces some JSON:

```
{"name": "Fourby #1", "description": "Fourby is a collection of 10,000 unique NFTs. Each Fourby is randomly generated and stored on-chain.", "image": "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHByZXNlcnZlQXNwZWN0UmF0aW89InhNaW5ZTWluIG1lZXQiIHZpZXdCb3g9IjAgMCA0MDAgNDAwIj48cmVjdCB3aWR0aD0iNDAwIiBoZWlnaHQ9IjQwMCIgeD0iMCIgeT0iMCIvPjxyZWN0IHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiB4PSIwIiB5PSIwIiBzdHlsZT0iZmlsbDojQ0NBQzkzOyIvPjxyZWN0IHdpZHRoPSIyMDAiIGhlaWdodD0iMjAwIiB4PSIyMDAiIHk9IjAiIHN0eWxlPSJmaWxsOiMxNThGQUQ7Ii8+PHJlY3Qgd2lkdGg9IjIwMCIgaGVpZ2h0PSIyMDAiIHg9IjAiIHk9IjIwMCIgc3R5bGU9ImZpbGw6I0FGQjgzQjsiLz48cmVjdCB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeD0iMjAwIiB5PSIyMDAiIHN0eWxlPSJmaWxsOiNGQUQwMDA7Ii8+PGNpcmNsZSBjeD0iMjAwIiBjeT0iMjAwIiByPSIyMDAiIGZpbGw9ImdyYXkiIGZpbGwtb3BhY2l0eT0iMC40Ii8+"}
```

Decoded SVG example:

```
<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400"><rect width="400" height="400" x="0" y="0"/><rect width="200" height="200" x="0" y="0" style="fill:#CCAC93;"/><rect width="200" height="200" x="200" y="0" style="fill:#158FAD;"/><rect width="200" height="200" x="0" y="200" style="fill:#AFB83B;"/><rect width="200" height="200" x="200" y="200" style="fill:#FAD000;"/><circle cx="200" cy="200" r="200" fill="gray" fill-opacity="0.4"/>
```
