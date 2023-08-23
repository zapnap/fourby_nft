// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "solady/tokens/ERC721.sol";
import "solady/auth/Ownable.sol";
import "solady/utils/Base64.sol";
import "solady/utils/LibString.sol";
// import "forge-std/console.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

contract FourbyNFT is ERC721, Ownable {
    using LibString for uint256;

    uint256 public currentTokenId;
    string public baseUri;

    uint256 public constant TOTAL_SUPPLY = 10_000;
    uint256 public constant MINT_PRICE = 0.001 ether;

    constructor(address _owner) {
        currentTokenId = 0;
        _initializeOwner(_owner);
        baseUri = "ipfs://baseUri/";
    }

    function name() public view virtual override returns (string memory) {
        return "FourbyNFT";
    }

    function symbol() public view virtual override returns (string memory) {
        return "FOURBY";
    }

    function mintTo(address recipient) public payable returns (uint256) {
        if (msg.value < MINT_PRICE) revert MintPriceNotPaid();
        uint256 newTokenId = ++currentTokenId;
        if (newTokenId > TOTAL_SUPPLY) revert MaxSupply();

        _safeMint(recipient, newTokenId);
        return newTokenId;
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");
        if (!transferTx) revert WithdrawTransfer();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (ownerOf(tokenId) == address(0)) revert NonExistentTokenURI();

        return string(abi.encodePacked("data:application/json;base64", _generateSvgJson(tokenId)));
    }

    function _generateSvgJson(uint256 tokenId) internal view returns (string memory) {
        string[8] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400">';
        parts[2] = '<rect width="400" height="400" x="0" y="0" style="stroke-width:1;stroke:rgb(0,0,0)"/>';
        parts[3] = string.concat(
            '<rect width="199" height="199" x="1" y="1" style="fill:',
            _svgColor(tokenId, 0),
            ';stroke-width:2;stroke:rgb(0,0,0)" />'
        );
        parts[4] = string.concat(
            '<rect width="199" height="199" x="200" y="1" style="fill:',
            _svgColor(tokenId, 1),
            ';stroke-width:2;stroke:rgb(0,0,0)" />'
        );
        parts[5] = string.concat(
            '<rect width="199" height="199" x="1" y="200" style="fill:',
            _svgColor(tokenId, 2),
            ';stroke-width:2;stroke:rgb(0,0,0)" />'
        );
        parts[6] = string.concat(
            '<rect width="199" height="199" x="200" y="200" style="fill:',
            _svgColor(tokenId, 3),
            ';stroke-width:2;stroke:rgb(0,0,0)" />'
        );
        parts[7] = "</svg>";
        string memory output =
            string(abi.encodePacked(parts[0], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Fourby #',
                        LibString.toString(tokenId),
                        '", "description": "Fourby is a collection of 10,000 unique NFTs. Each Fourby is randomly generated and stored on-chain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        return json;
    }

    function _svgColor(uint256 tokenId, uint256 index) internal view returns (string memory) {
        string[20] memory svgColors = [
            "#B8255F", // berry red
            "#DB4035", // red
            "#FF9933", // orange
            "#FAD000", // yellow
            "#AFB83B", // olive green
            "#7ECC49", // lime green
            "#299438", // green
            "#6ACCBC", // mint green
            "#158FAD", // teal
            "#14AAF5", // sky blue
            "#96C3EB", // light blue
            "#4073FF", // blue
            "#884DFF", // grape
            "#AF38EB", // violet
            "#EB96EB", // lavender
            "#E05194", // magenta
            "#FF8D85", // salmon
            "#808080", // charcoal
            "#B8B8B8", // grey
            "#CCAC93" // taupe
        ];

        return svgColors[_generateRandom(tokenId, index) % svgColors.length];
    }

    function _generateRandom(uint256 seed1, uint256 seed2) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, seed1, seed2)));
    }
}
