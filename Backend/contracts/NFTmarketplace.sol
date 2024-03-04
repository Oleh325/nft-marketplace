// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NFTmarketplace__PriceMustBeAboveZero();
error NFTmarketplace__NotApprovedForMarketplace();
error NFTmarketplace__ItemAlreadyListed(address nftAddress, uint256 tokenId);
error NFTmarketplace__ItemNotListed(address nftAddress, uint256 tokenId);
error NFTmarketplace__NotOwner();
error NFTmarketplace__PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);

contract NFTmarketplace is ERC721 {
    struct Listing {
        address seller;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;

    event ItemListed(
        address indexed nftAddress,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemBought(
        address indexed nftAddress,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    modifier notListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NFTmarketplace__ItemAlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NFTmarketplace__ItemNotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        if (nft.ownerOf(tokenId) != spender) {
            revert NFTmarketplace__NotOwner();
        }
        _;
    }

    /**
     * @notice Method for listing your NFT on the marketplace
     * @param nftAddress Address of the NFT contract
     * @param tokenId ID of the NFT
     * @param price Price of the NFT
     */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external notListed(nftAddress, tokenId) isOwner(nftAddress, tokenId, spender) {
        if (price <= 0) {
            revert NFTmarketplace__PriceMustBeAboveZero();
        }
        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NFTmarketplace__NotApprovedForMarketplace();
        }
        s_listings[nftAddress][tokenId] = Listing(price, msg.sender);
        emit ItemListed(nftAddress, msg.sender, tokenId, price);
    }

    function buyItem(
        address ntfAddress,
        uint256 tokenId
    ) external payable isListed(nftAddress, tokenId) {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert NFTmarketplace__PriceNotMet(ntfAddress, tokenId, listedItem.price);
        }
        s_proceeds[listedItem.seller] += msg.value;
        delete (s_listings[nftAddress][tokenId]);
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
        emit ItemBought(nftAddress, msg.sender, tokenId, listedItem.price);
    }

    function cancelItem() public {}

    function updateListing() public {}

    function withdrawProceeds() public {}
}
