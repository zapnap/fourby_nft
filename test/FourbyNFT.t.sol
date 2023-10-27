// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/StdJson.sol";
import "forge-std/console.sol";
import "../src/FourbyNFT.sol";

contract FourbyTest is Test {
    using stdStorage for StdStorage;
    using stdJson for string;

    TestableFourbyNFT public nftOpenEd;
    TestableFourbyNFT public nftLimitedEd;
    address public owner;

    function setUp() public {
        owner = address(this);
        nftOpenEd = new TestableFourbyNFT(owner, 0, 0, 7200); // open edition with 1 day of mint time
        nftLimitedEd = new TestableFourbyNFT(owner, 80000000000000000, 10, 0); // limited edition with no date cutoff
    }

    function testRevertMintWithoutValue() public {
        vm.expectRevert(MintPriceNotPaid.selector);
        nftLimitedEd.mintTo(address(1));
    }

    function testRevertMintValueInsufficient() public {
        vm.expectRevert(MintPriceNotPaid.selector);
        nftLimitedEd.mintTo{value: 0.07 ether}(address(1));
    }

    function testMintPriceFreeMint() public {
        nftOpenEd.mintTo(address(1));
        assertEq(address(nftOpenEd).balance, 0);
    }

    function testMintPricePaid() public {
        nftLimitedEd.mintTo{value: 0.08 ether}(address(1));
        assertEq(address(nftLimitedEd).balance, 0.08 ether);
    }

    function testRevertMintMaxSupplyReached() public {
        uint256 slot = stdstore.target(address(nftLimitedEd)).sig("currentTokenId()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(10));
        vm.store(address(nftLimitedEd), loc, mockedCurrentTokenId);
        vm.expectRevert(MaxSupply.selector);
        nftLimitedEd.mintTo{value: 0.08 ether}(address(1));
    }

    function testRevertMintIsEnded() public {
        vm.roll(block.number + 7201);
        vm.expectRevert(MintEnded.selector);
        nftOpenEd.mintTo{value: 0.08 ether}(address(1));
    }

    function testRevertMintToZeroAddress() public {
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        nftOpenEd.mintTo{value: 0.08 ether}(address(0));
    }

    function testNewMintOwnerRegistered() public {
        nftOpenEd.mintTo{value: 0.08 ether}(address(1));
        uint256 slotOfNewOwner = stdstore.target(address(nftOpenEd)).sig(nftOpenEd.ownerOf.selector).with_key(1).find();
        uint160 ownerOfTokenIdOne = uint160(uint256(vm.load(address(nftOpenEd), bytes32(abi.encode(slotOfNewOwner)))));
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public {
        nftOpenEd.mintTo{value: 0.08 ether}(address(1));
        uint256 slotBalance =
            stdstore.target(address(nftOpenEd)).sig(nftOpenEd.balanceOf.selector).with_key(address(1)).find();
        uint256 balanceFirstMint = uint256(vm.load(address(nftOpenEd), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        nftOpenEd.mintTo{value: 0.08 ether}(address(1));
        uint256 balanceSecondMint = uint256(vm.load(address(nftOpenEd), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function testSafeContractReceiver() public {
        TestTokenReceiver receiver = new TestTokenReceiver();
        nftOpenEd.mintTo{value: 0.08 ether}(address(receiver));
        uint256 slotBalance =
            stdstore.target(address(nftOpenEd)).sig(nftOpenEd.balanceOf.selector).with_key(address(receiver)).find();
        uint256 balance = uint256(vm.load(address(nftOpenEd), bytes32(slotBalance)));
        assertEq(balance, 1);
    }

    function testRevertUnSafeContractReceiver() public {
        vm.etch(address(1234), bytes("mock code"));
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        nftOpenEd.mintTo{value: 1.0 ether}(address(1234));
    }

    function testNumberMintableOpenEdition() public {
        uint256 number = nftOpenEd.numberMintable();
        assertEq(number, type(uint256).max);
    }

    function testNumberMintableLimitedEdition() public {
        uint256 number = nftLimitedEd.numberMintable();
        assertEq(number, 10);
        nftLimitedEd.mintTo{value: 0.08 ether}(address(1));
        number = nftLimitedEd.numberMintable();
        assertEq(number, 9);
    }

    function testMintEnded() public {
        assertEq(nftOpenEd.mintEnded(), false);
        vm.roll(block.number + 7201);
        assertEq(nftOpenEd.mintEnded(), true);
    }

    function testMintEndedZero() public {
        assertEq(nftLimitedEd.mintEnded(), false);
    }

    function testWithdrawalWorksAsOwner() public {
        TestTokenReceiver receiver = new TestTokenReceiver();
        address payable payee = payable(address(0x1337));
        uint256 priorOwnerBalance = payee.balance;

        nftOpenEd.mintTo{value: 0.001 ether}(address(receiver));
        assertEq(address(nftOpenEd).balance, 0.001 ether);
        uint256 nftOpenEdBalance = address(nftOpenEd).balance;

        nftOpenEd.withdrawPayments(payee);
        assertEq(payee.balance, priorOwnerBalance + nftOpenEdBalance);
    }

    function testWithdrawalFailsAsNotOwner() public {
        TestTokenReceiver receiver = new TestTokenReceiver();

        nftOpenEd.mintTo{value: 0.001 ether}(address(receiver));
        assertEq(address(nftOpenEd).balance, 0.001 ether);

        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.startPrank(address(0x1337));
        nftOpenEd.withdrawPayments(payable(address(0x1337)));
        vm.stopPrank();
    }

    function testTokenURI() public {
        nftOpenEd.mintTo{value: 0.001 ether}(address(1));
        nftOpenEd.tokenURI(1);
        // assertEq(uri, "ipfs://baseUri/1");
        // console.log(uri);
    }

    function testTokenURINonExistent() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        nftOpenEd.tokenURI(20);
    }

    function testRenderSvg() public {
        nftOpenEd.mintTo{value: 0.001 ether}(address(1));
        nftOpenEd.renderSvg(1);
        // assertEq(svg, "<svg>...</svg>");
        // console.log(svg);
    }

    function testRenderSvgNonExistent() public {
        vm.expectRevert(ERC721.TokenDoesNotExist.selector);
        nftOpenEd.renderSvg(1);
    }

    function testGenerateSvgJson() public {
        nftOpenEd.mintTo{value: 0.001 ether}(address(1));
        string memory uri = nftOpenEd.generateSvgJson(1);
        string memory decoded = string(Base64.decode(uri));
        FourbyMetadata memory parsed = abi.decode(vm.parseJson(decoded), (FourbyMetadata));
        assertEq(parsed.name, "Fourby #1");
    }

    function testGenerateSvgLabel() public {
        string memory label = nftOpenEd.generateSvgLabel(5);
        assertEq(
            label,
            '<text x="10" y="390" class="text" style="fill:#fff">010.31337.1.0005</text><style>.text { font-family: "Courier New"; font-weight: bold; }</style>'
        );
    }

    function testGenerateSvgRect() public {
        string memory rect = nftOpenEd.generateSvgRect(100, 0, 50, "red");
        assertEq(rect, '<rect x="100" y="0" width="50" height="50" fill="red"/>');
    }

    function testGenerateSvgRing() public {
        string memory ring = nftOpenEd.generateSvgRing(100, 10, "red");
        assertEq(
            ring,
            '<circle cx="200" cy="200" r="100" stroke="red" stroke-width="10" stroke-opacity="1" fill-opacity="0"/>'
        );
    }

    function testGenerateRandom(uint256 tokenId, uint256 index) public {
        vm.warp(1641070800);
        uint256 random = nftOpenEd.generateRandom(tokenId, index) % 10;
        assertLe(random, 10);
        assertGe(random, 0);
    }

    function testUpdatePrices(uint256 newPrice) public {
        vm.txGasPrice(250000);
        nftOpenEd.mintTo{value: 0.001 ether}(address(1));
        nftOpenEd.updatePrices(newPrice);
        assertEq(nftOpenEd.gasPrices(0), newPrice);
        assertEq(nftOpenEd.gasPrices(1), 250000);
        assertEq(nftOpenEd.gasPrices(2), 0);
    }

    function testScaleBetween() public {
        uint256 scaled = nftOpenEd.scaleBetween(50, 2, 10, 0, 100);
        assertEq(scaled, 6);
    }
}

contract TestTokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// expose internal functions for testing
contract TestableFourbyNFT is FourbyNFT {
    constructor(address _owner, uint256 _mintPrice, uint256 _editionSize, uint256 _blocksToMint)
        FourbyNFT(_owner, _mintPrice, _editionSize, _blocksToMint)
    {}

    function generateSvgLabel(uint256 tokenId) public view returns (string memory) {
        return _generateSvgLabel(tokenId);
    }

    function generateSvgRect(uint256 x, uint256 y, uint256 r, string memory color)
        public
        pure
        returns (string memory)
    {
        return _generateSvgRect(x, y, r, color);
    }

    function generateSvgRing(uint256 r, uint256 size, string memory color) public pure returns (string memory) {
        return _generateSvgRing(r, size, color);
    }

    function generateSvgJson(uint256 tokenId) public view returns (string memory) {
        return _generateSvgJson(tokenId);
    }

    function generateRandom(uint256 tokenId, uint256 index) public view returns (uint256) {
        return _generateRandom(tokenId, index);
    }

    function updatePrices(uint256 gasPrice) public returns (uint256) {
        return _updatePrices(gasPrice);
    }

    function scaleBetween(uint256 unscaledNum, uint256 minAllowed, uint256 maxAllowed, uint256 min, uint256 max)
        public
        pure
        returns (uint256)
    {
        return _scaleBetween(unscaledNum, minAllowed, maxAllowed, min, max);
    }
}

// NOTE: alphabetical order matters
struct FourbyMetadata {
    string description;
    string image;
    string name;
}
