// SPDX-License-Identifier: MIT

// NAVYSEAL AIRDROP CLAIM


pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract NavySeal is ERC721, Ownable {
    
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;
    


    string baseURI;
    bool public saleIsActive = false;
    bool public publicsaleIsActive = false;   
    bytes32[3] public merkleRoot = [bytes32(0x7241d8c8a5b5b12b0db4ac436356fa0af6d8000dac08809b0c61adec30d4ba34), bytes32(0x447c73654c3338f006a1824eaded0b179238f769bf4764dfa678e0b856339fba), bytes32(0x06b6b1329873934583b9c936d744d343720863287fddaef410ef868be52ced68)];
   

    // The tier struct will keep all the information about the tier
    struct Tier {
        uint16 totalSupply;
        uint16 maxSupply;
        uint16 startingIndex;
        uint8 mintsPerAddress;
    }

    // Mapping used to limit the mints per tier
    mapping(uint256 => mapping(address => uint256)) addressCountsPerTier;
    
    // Mapping used to limit the mints per tier
    mapping(address => uint256) addressCountsPublic;

    // Mapping where Tier structs are saved
    mapping(uint256 => Tier) tiers;

    mapping(address => bool) hasMinted;
    // BaseURI
    mapping(uint256 => string) private _tokenURIs;

    modifier isApprovedOrOwner(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender,
            "ERC 721: Transfer caller not owner or approved"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        setBaseURI(_initBaseURI);
        tiers[0] = Tier({
            totalSupply: 0,
            maxSupply: 10,
            startingIndex: 1,
            mintsPerAddress: 1
        });
        tiers[1] = Tier({
            totalSupply: 0,
            maxSupply: 200,
            startingIndex: 11,
            mintsPerAddress: 1
        });
        tiers[2] = Tier({
            totalSupply: 0,
            maxSupply: 357,
            startingIndex: 211,
            mintsPerAddress: 1
        });
        tiers[3] = Tier({
            totalSupply: 0,
            maxSupply: 200,
            startingIndex: 568,
            mintsPerAddress: 1
        });
        tiers[4] = Tier({
            totalSupply: 0,
            maxSupply: 10,
            startingIndex: 768,
            mintsPerAddress: 10
        });

    }

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    // @param tokenId The tokenId of token whose URI we are changing
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        external
        onlyOwner
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURII = _baseURI();
        return
            bytes(baseURII).length > 0
                ? string(abi.encodePacked(baseURII, toString(tokenId), ".json"))
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function isValid(
        bytes32[] memory proof,
        bytes32 leaf,
        uint256 tier
    ) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot[tier], leaf);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    function flipPublicSaleState() public onlyOwner {
        publicsaleIsActive = !publicsaleIsActive;
    }

    function setMerkleRoot(bytes32[3] memory _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function ownerMint() public payable onlyOwner {
        uint tier = 4;
        require(
            tiers[tier].totalSupply + 1 <= tiers[tier].maxSupply,
            "Exceeded max limit of allowed token mints"
        );
        handlemint(tier,msg.sender);}

    // @param tier The tier of the NFT to be minted
    function mintTier0(bytes32[] memory proof) public payable {
        require(saleIsActive, "Sale is not active");
        uint256 tier = 0;
        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender)), tier),
            "Not a part of Tier 0"
        );
        require(
            tiers[tier].totalSupply + 1 <= tiers[tier].maxSupply,
            "Exceeded max limit of allowed token mints"
        );
        require(
            addressCountsPerTier[tier][msg.sender] + 1 <=
                tiers[tier].mintsPerAddress,
            "Max number of mints per address reached"
        );
               handlemint(tier,msg.sender);

    }

    // @param tier The tier of the NFT to be minted
    function mintTier1(bytes32[] memory proof) public {
        require(saleIsActive, "Sale is not active");
        uint256 tier = 1;
        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender)), tier),
            "Not a part of Tier 1"
        );
        require(
            tiers[tier].totalSupply + 1 <= tiers[tier].maxSupply,
            "Exceeded max limit of allowed token mints"
        );
        require(
            addressCountsPerTier[tier][msg.sender] + 1 <=
                tiers[tier].mintsPerAddress,
            "Max number of mints per address reached"
        );

        handlemint(tier,msg.sender);

    }

    function handlemint(uint256 tier, address _address) private{
  addressCountsPerTier[tier][_address] =
            addressCountsPerTier[tier][_address] +
            1;
        uint16 tierTotalSuppy = tiers[tier].totalSupply;
        tiers[tier].totalSupply = tierTotalSuppy + 1;
        uint16 tierIndex = tiers[tier].startingIndex;
        hasMinted[msg.sender] = true;
        _safeMint(_address, tierTotalSuppy+tierIndex);
        }

    // @param tier The tier of the NFT to be minted
    function mintTier2(bytes32[] memory proof) public {
        require(saleIsActive, "Sale is not active");
        uint256 tier = 2;
        require(
            isValid(proof, keccak256(abi.encodePacked(msg.sender)), tier),
            "Not a part of Tier 3"
        );
        require(
            tiers[tier].totalSupply + 1 <= tiers[tier].maxSupply,
            "Exceeded max limit of allowed token mints"
        );
        require(
            addressCountsPerTier[tier][msg.sender] + 1 <=
                tiers[tier].mintsPerAddress,
            "Max number of mints per address reached"
        );

       handlemint(tier,msg.sender);
    }

    function mintPublic() public {
        require(publicsaleIsActive, "Sale is not active");
        uint256 tier = getRandomNumber(msg.sender);
        if (tiers[tier].totalSupply + 1 > tiers[tier].maxSupply) {
            tier = getRandomNumber(msg.sender);
        }
        require(
            tiers[tier].totalSupply+1 <= tiers[tier].maxSupply,
            "Exceeded max limit of allowed token mints"
        );
        require(
            addressCountsPublic[msg.sender]<1,
            "Max number of mints per address reached"
        );

        addressCountsPublic[msg.sender] =
            addressCountsPublic[msg.sender] +
            1;
        uint16 tierTotalSuppy = tiers[tier].totalSupply;
        tiers[tier].totalSupply = tierTotalSuppy + 1;
        hasMinted[msg.sender] = true;
        _safeMint(msg.sender, tierTotalSuppy +tiers[tier].startingIndex+ 1);
    }

    /* ========== VIEW METHODS ========== */

    // @param tier The tier of which the total supply should be returned
    // @return The total supply of the specified tier
    function tierTotalSupply(uint256 tier) external view returns (uint256) {
        return tiers[tier].totalSupply;
    }

    // @param tier The tier of which the max supply rice should be returned
    // @return The max supply of the specified tier
    function tierMaxSupply(uint256 tier) external view returns (uint256) {
        return tiers[tier].maxSupply;
    }
    //@return if user minted yet
    function hasUserMinted(address user)external view returns(bool){
         return hasMinted[user];
    }
    // @param tier The tier of which the max supply rice should be returned
    // @return The max supply of the specified tier
    function tierStartingIndex(uint256 tier) external view returns (uint256) {
        return tiers[tier].startingIndex;
    }

    function totalSupply() public view returns (uint256) {
        return
            tiers[0].totalSupply + tiers[1].totalSupply + tiers[2].totalSupply + tiers[3].totalSupply + tiers[4].totalSupply;
    }

    function getRandomNumber(address _addy) private view returns (uint) {
        uint blockValue = uint(blockhash(block.number - 1));
        uint random = uint(keccak256(abi.encodePacked(block.timestamp, blockValue, _addy))) % 3;
        return random;
    }

    // @return The max supply of all tiers summed up
    function totalMaxSupply() external view returns (uint256) {
        return tiers[0].maxSupply + tiers[1].maxSupply + tiers[2].maxSupply+tiers[3].maxSupply + tiers[4].maxSupply;
    }

   
}
