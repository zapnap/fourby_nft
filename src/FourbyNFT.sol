// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "solady/tokens/ERC721.sol";
import "solady/auth/Ownable.sol";
import "solady/utils/Base64.sol";
import "solady/utils/LibString.sol";
// import "forge-std/console.sol";

error MintPriceNotPaid();
error MaxSupply();
error MintEnded();
error WithdrawTransfer();

contract FourbyNFT is ERC721, Ownable {
    using LibString for uint256;

    string public constant VERSION = "010";

    uint256 public currentTokenId;

    uint256 public mintPrice;

    uint256 public editionSize;

    uint256 public mintFirstBlock;

    uint256 public mintLastBlock;

    mapping(uint256 => uint256) public blockMinted;

    uint256[8] public gasPrices = [0, 0, 0, 0, 0, 0, 0, 0];

    constructor(address _owner, uint256 _mintPrice, uint256 _editionSize, uint256 _blocksToMint) {
        currentTokenId = 0;
        mintPrice = _mintPrice; // wei
        editionSize = _editionSize;
        mintFirstBlock = block.number;
        // currently 12s block time == 7200 blocks per day
        mintLastBlock = _blocksToMint == 0 ? 0 : mintFirstBlock + _blocksToMint;
        _initializeOwner(_owner);
    }

    function name() public view virtual override returns (string memory) {
        return "FourbyNFT";
    }

    function symbol() public view virtual override returns (string memory) {
        return "FOURBY";
    }

    function mintTo(address recipient) public payable returns (uint256) {
        if (mintPrice > 0 && msg.value < mintPrice) revert MintPriceNotPaid();
        if (mintEnded()) revert MintEnded();
        if (numberMintable() < 1) revert MaxSupply();
        uint256 newTokenId = ++currentTokenId;
        _safeMint(recipient, newTokenId);
        _updatePrices(tx.gasprice);
        blockMinted[newTokenId] = block.number;
        return newTokenId;
    }

    function numberMintable() public view returns (uint256) {
        if (mintEnded()) {
            return 0;
        } else if (editionSize == 0) {
            return type(uint256).max;
        }
        return editionSize - currentTokenId;
    }

    function mintEnded() public view returns (bool) {
        return mintLastBlock > 0 && block.number > mintLastBlock;
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
                        '", "description": "Fourby is a collection of 4,000 unique NFTs. Each Fourby is randomly generated and stored on-chain.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(_generateSvg(tokenId))),
                        '"}'
                    )
                )
            )
        );
    }

    function _generateSvgRect(uint256 x, uint256 y, uint256 r, string memory color)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '<rect x="',
            LibString.toString(x),
            '" y="',
            LibString.toString(y),
            '" width="',
            LibString.toString(r),
            '" height="',
            LibString.toString(r),
            '" fill="',
            color,
            '"/>'
        );
    }

    function _generateSvgRing(uint256 r, uint256 size, string memory color) internal pure returns (string memory) {
        return string.concat(
            '<circle cx="200" cy="200" r="',
            LibString.toString(r),
            '" stroke="',
            color,
            '" stroke-width="',
            LibString.toString(size),
            '" stroke-opacity="1" fill-opacity="0"/>'
        );
    }

    function _generateSvgLabel(uint256 tokenId) internal view returns (string memory) {
        return string.concat(
            '<text x="10" y="390" class="text" style="fill:#fff">',
            VERSION,
            ".",
            block.chainid.toString(),
            ".",
            blockMinted[tokenId].toString(),
            ".",
            LibString.toHexStringNoPrefix(tokenId, 2),
            '</text><style>.text { font-family: "Courier New"; font-weight: bold; }</style>'
        );
    }

    function _generateSvg(uint256 tokenId) internal view returns (string memory) {
        string[4] memory colors =
            [_svgColor(tokenId, 0), _svgColor(tokenId, 1), _svgColor(tokenId, 2), _svgColor(tokenId, 3)];
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 400 400">',
            _generateSvgRect(0, 0, 200, colors[0]),
            _generateSvgRect(200, 0, 200, colors[1]),
            _generateSvgRect(0, 200, 200, colors[2]),
            _generateSvgRect(200, 200, 200, colors[3])
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
                uint256 width = _scaleBetween(price, 1, 5, min, max) * 4;
                svg = string.concat(svg, _generateSvgRing(rad, width, colors[i % 4]));
            }
        }
        return string.concat(svg, _generateSvgLabel(tokenId), "</svg>");
    }

    function _svgColor(uint256 tokenId, uint256 position) internal view returns (string memory) {
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

        uint256 idx = uint256(keccak256(abi.encodePacked(blockMinted[tokenId], position)));
        return svgColors[idx % svgColors.length];
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
