// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Listing {
        address seller;
        uint256 price;
        bool isSold;
    }

    // tokenId => Listing
    mapping(uint256 => Listing) private listings;
    // vendedor => fondos acumulados
    mapping(address => uint256) private proceeds;

    event ItemListed(
        uint256 indexed tokenId,
        address indexed seller,
        uint256 price
    );
    event ItemSold(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );

    constructor() ERC721("MyNFT", "MNFT") {}

    /**
     * @dev Mint y lista el NFT en el marketplace
     * @param _uri URI de metadata
     * @param _price Precio en wei (>0)
     */
    function mintAndList(string memory _uri, uint256 _price) external {
        require(_price > 0, "Price must be > 0");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _uri);

        listings[newTokenId] = Listing({
            seller: msg.sender,
            price: _price,
            isSold: false
        });

        emit ItemListed(newTokenId, msg.sender, _price);
    }

    /**
     * @dev Compra un NFT listado
     * @param _tokenId ID del token a comprar
     */
    function buy(uint256 _tokenId) external payable {
        Listing storage item = listings[_tokenId];

        require(!item.isSold, "Already sold");
        require(msg.value == item.price, "Incorrect price");

        item.isSold = true;
        // acumular fondos para el vendedor
        proceeds[item.seller] += msg.value;

        // transferir NFT al comprador
        _transfer(item.seller, msg.sender, _tokenId);

        emit ItemSold(_tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Devuelve la info de un listing
     */
    function getListing(uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint256 price,
            bool isSold
        )
    {
        Listing storage item = listings[_tokenId];
        return (item.seller, item.price, item.isSold);
    }

    /**
     * @dev Permite al vendedor retirar sus fondos acumulados
     */
    function withdraw() external {
        uint256 amount = proceeds[msg.sender];
        require(amount > 0, "No funds to withdraw");

        proceeds[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
