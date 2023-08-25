// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "solady/tokens/ERC721.sol";
import "solady/auth/Ownable.sol";
import "solady/utils/Base64.sol";
import "solady/utils/LibString.sol";
// import "forge-std/console.sol";

error MintPriceNotPaid();
error MaxSupply();
error WithdrawTransfer();

contract FourbyNFT is ERC721, Ownable {
    using LibString for uint256;

    uint256 public currentTokenId;
    string public baseUri;

    uint256 public constant TOTAL_SUPPLY = 10_000;
    uint256 public constant MINT_PRICE = 0.001 ether;

    uint256[8] public gasPrices = [0, 0, 0, 0, 0, 0, 0, 0];

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
        _updatePrices(tx.gasprice);
        return newTokenId;
    }

    function withdrawPayments(address payable payee) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool transferTx,) = payee.call{value: balance}("");
        if (!transferTx) revert WithdrawTransfer();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721.TokenDoesNotExist();
        return string(abi.encodePacked("data:application/json;base64", _generateSvgJson(tokenId)));
    }

    function renderSvg(uint256 tokenId) public view returns (string memory) {
        if (!_exists(tokenId)) revert ERC721.TokenDoesNotExist();
        return _generateSvg(tokenId);
    }

    function _generateSvgJson(uint256 tokenId) internal view returns (string memory) {
        return Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Fourby #',
                        LibString.toString(tokenId),
                        '", "description": "Fourby is a collection of 10,000 unique NFTs. Each Fourby is randomly generated and stored on-chain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(_generateSvg(tokenId))),
                        '"}'
                    )
                )
            )
        );
    }

    function _generateSvg(uint256 tokenId) internal view returns (string memory) {
        string[4] memory colors =
            [_svgColor(tokenId, 0), _svgColor(tokenId, 1), _svgColor(tokenId, 2), _svgColor(tokenId, 3)];
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400">',
            '<rect width="400" height="400" x="0" y="0"/>',
            '<rect width="200" height="200" x="0" y="0" style="fill:',
            colors[0],
            ';"/>',
            '<rect width="200" height="200" x="200" y="0" style="fill:',
            colors[1],
            ';"/>',
            '<rect width="200" height="200" x="0" y="200" style="fill:',
            colors[2],
            ';"/>',
            '<rect width="200" height="200" x="200" y="200" style="fill:',
            colors[3],
            ';"/>'
        );
        uint256 limit = tokenId > 8 ? 8 : tokenId;
        uint256 sum = 0;
        uint256 min = 0;
        uint256 max = 0;
        for (uint256 i = 0; i < gasPrices.length; i++) {
            if (gasPrices[i] < min) min = gasPrices[i];
            if (gasPrices[i] > max) max = gasPrices[i];
            sum += gasPrices[i];
        }
        for (uint256 i = 0; i < limit; i++) {
            uint256 price = gasPrices[i];
            if (price > 0) {
                uint256 rad = (i + 1) * 20;
                uint256 width = _scaleBetween(price, 1, 20, min, max);
                svg = string.concat(
                    svg,
                    '<circle cx="200" cy="200" r="',
                    rad.toString(),
                    '" stroke="',
                    colors[i % 4],
                    '" stroke-width="',
                    width.toString(),
                    '" stroke-opacity="1" fill-opacity="0"/>'
                );
            }
        }
        return string.concat(
            svg,
            '<text x="10" y="390" class="text" style="fill:#fff">0',
            LibString.toString(tokenId + 10000),
            ".",
            block.chainid.toString(),
            ".",
            block.number.toString(),
            '</text><style>.text { font-family: "Courier New"; font-weight: bold; }</style>',
            "</svg>"
        );
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

    function _updatePrices(uint256 newPrice) internal returns (uint256) {
        for (uint256 i = 0; i < gasPrices.length; i++) {
            uint256 idx = gasPrices.length - 1 - i;
            if (idx > 0) {
                gasPrices[idx] = gasPrices[idx - 1];
            } else {
                gasPrices[idx] = newPrice;
            }
        }
        return newPrice;
    }

    function _scaleBetween(uint256 unscaledNum, uint256 minAllowed, uint256 maxAllowed, uint256 min, uint256 max)
        internal
        pure
        returns (uint256)
    {
        if (unscaledNum == 0) {
            return 0;
        } else {
            return (maxAllowed - minAllowed) * (unscaledNum - min) / (max - min) + minAllowed;
        }
    }
}
