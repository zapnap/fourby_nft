// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/StdJson.sol";
import "../src/FourbyNFT.sol";

contract FourbyTest is Test {
    using stdStorage for StdStorage;
    using stdJson for string;

    TestableFourbyNFT public nft;
    address public owner;

    function setUp() public {
        owner = address(this);
        nft = new TestableFourbyNFT(owner);
    }

    function testRevertMintWithoutValue() public {
        vm.expectRevert(MintPriceNotPaid.selector);
        nft.mintTo(address(1));
    }

    function testMintPricePaid() public {
        nft.mintTo{value: 0.08 ether}(address(1));
    }

    function testRevertMintMaxSupplyReached() public {
        uint256 slot = stdstore.target(address(nft)).sig("currentTokenId()").find();
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(10000));
        vm.store(address(nft), loc, mockedCurrentTokenId);
        vm.expectRevert(MaxSupply.selector);
        nft.mintTo{value: 0.08 ether}(address(1));
    }

    function testRevertMintToZeroAddress() public {
        vm.expectRevert(ERC721.TransferToZeroAddress.selector);
        nft.mintTo{value: 0.08 ether}(address(0));
    }

    function testNewMintOwnerRegistered() public {
        nft.mintTo{value: 0.08 ether}(address(1));
        uint256 slotOfNewOwner = stdstore.target(address(nft)).sig(nft.ownerOf.selector).with_key(1).find();
        uint160 ownerOfTokenIdOne = uint160(uint256(vm.load(address(nft), bytes32(abi.encode(slotOfNewOwner)))));
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public {
        nft.mintTo{value: 0.08 ether}(address(1));
        uint256 slotBalance = stdstore.target(address(nft)).sig(nft.balanceOf.selector).with_key(address(1)).find();
        uint256 balanceFirstMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceFirstMint, 1);

        nft.mintTo{value: 0.08 ether}(address(1));
        uint256 balanceSecondMint = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balanceSecondMint, 2);
    }

    function testSafeContractReceiver() public {
        TestTokenReceiver receiver = new TestTokenReceiver();
        nft.mintTo{value: 0.08 ether}(address(receiver));
        uint256 slotBalance =
            stdstore.target(address(nft)).sig(nft.balanceOf.selector).with_key(address(receiver)).find();
        uint256 balance = uint256(vm.load(address(nft), bytes32(slotBalance)));
        assertEq(balance, 1);
    }

    function testRevertUnSafeContractReceiver() public {
        vm.etch(address(1234), bytes("mock code"));
        vm.expectRevert(ERC721.TransferToNonERC721ReceiverImplementer.selector);
        nft.mintTo{value: 1.0 ether}(address(1234));
    }

    function testWithdrawalWorksAsOwner() public {
        TestTokenReceiver receiver = new TestTokenReceiver();
        address payable payee = payable(address(0x1337));
        uint256 priorOwnerBalance = payee.balance;

        nft.mintTo{value: nft.MINT_PRICE()}(address(receiver));
        assertEq(address(nft).balance, nft.MINT_PRICE());
        uint256 nftBalance = address(nft).balance;

        nft.withdrawPayments(payee);
        assertEq(payee.balance, priorOwnerBalance + nftBalance);
    }

    function testWithdrawalFailsAsNotOwner() public {
        TestTokenReceiver receiver = new TestTokenReceiver();

        nft.mintTo{value: nft.MINT_PRICE()}(address(receiver));
        assertEq(address(nft).balance, nft.MINT_PRICE());

        vm.expectRevert(Ownable.Unauthorized.selector);
        vm.startPrank(address(0x1337));
        nft.withdrawPayments(payable(address(0x1337)));
        vm.stopPrank();
    }

    function testTokenURI() public {
        nft.mintTo{value: 0.001 ether}(address(1));
        nft.tokenURI(1);
        // assertEq(uri, "ipfs://baseUri/1");
        // console.log(uri);
    }

    function testGenerateSvgJson() public {
        nft.mintTo{value: 0.001 ether}(address(1));
        string memory uri = nft.generateSvgJson(1);
        string memory decoded = string(Base64.decode(uri));
        FourbyMetadata memory parsed = abi.decode(vm.parseJson(decoded), (FourbyMetadata));
        assertEq(parsed.name, "Fourby #1");
    }

    function testGenerateRandom(uint256 tokenId, uint256 index) public {
        vm.warp(1641070800);
        uint256 random = nft.generateRandom(tokenId, index) % 10;
        assertLe(random, 10);
        assertGe(random, 0);
    }
}

contract TestTokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// expose internal functions for testing
contract TestableFourbyNFT is FourbyNFT {
    constructor(address _owner) FourbyNFT(_owner) {}

    function generateSvgJson(uint256 tokenId) public view returns (string memory) {
        return _generateSvgJson(tokenId);
    }

    function generateRandom(uint256 tokenId, uint256 index) public view returns (uint256) {
        return _generateRandom(tokenId, index);
    }
}

// NOTE: alphabetical order matters
struct FourbyMetadata {
    string description;
    string image;
    string name;
}
