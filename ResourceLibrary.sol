// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract VanaResourceLibrary is AccessControl {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.bytes32Set;

    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    Counters.Counter private _resourceCounter;
    EnumerableSet.bytes32Set private _categories;
    mapping(bytes32 => EnumerableSet.bytes32Set) private _categoryTags;

    struct ResourceMetadata {
        uint256 id;
        string title;
        string description;
        bytes32[] categories;
        bytes32[] tags;
        uint256 version;
        uint256 uploadTimestamp;
        address uploader;
    }

    mapping(uint256 => ResourceMetadata) public resources;
    mapping(address => EnumerableSet.AddressSet) private _curatorsPerResource;

    event ResourceAdded(uint256 indexed id, string title, address indexed uploader);
    event ResourceUpdated(uint256 indexed id, string title, uint256 indexed version, address indexed uploader);
    event CategoryAdded(bytes32 indexed category);
    event TagAdded(bytes32 indexed category, bytes32 indexed tag);
    event CuratorAdded(uint256 indexed resourceId, address indexed curator);
    event CuratorRemoved(uint256 indexed resourceId, address indexed curator);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function addResource(
        string memory title,
        string memory description,
        bytes32[] memory categories,
        bytes32[] memory tags
    ) public {
        _resourceCounter.increment();
        uint256 resourceId = _resourceCounter.current();
        resources[resourceId] = ResourceMetadata(
            resourceId,
            title,
            description,
            categories,
            tags,
            1,
            block.timestamp,
            msg.sender
        );

        for (uint256 i = 0; i < categories.length; i++) {
            _categories.add(categories[i]);
            for (uint256 j = 0; j < tags.length; j++) {
                _categoryTags[categories[i]].add(tags[j]);
            }
        }

        emit ResourceAdded(resourceId, title, msg.sender);
    }

    function updateResource(
        uint256 resourceId,
        string memory title,
        string memory description,
        bytes32[] memory categories,
        bytes32[] memory tags
    ) public {
        require(hasRole(CURATOR_ROLE, msg.sender) || resources[resourceId].uploader == msg.sender, "Only curators or the uploader can update the resource");
        resources[resourceId].title = title;
        resources[resourceId].description = description;
        resources[resourceId].categories = categories;
        resources[resourceId].tags = tags;
        resources[resourceId].version++;
        resources[resourceId].uploadTimestamp = block.timestamp;

        for (uint256 i = 0; i < categories.length; i++) {
            _categories.add(categories[i]);
            for (uint256 j = 0; j < tags.length; j++) {
                _categoryTags[categories[i]].add(tags[j]);
            }
        }

        emit ResourceUpdated(resourceId, title, resources[resourceId].version, msg.sender);
    }

    function addCurator(uint256 resourceId, address curator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _curatorsPerResource[resourceId].add(curator);
        grantRole(CURATOR_ROLE, curator);
        emit CuratorAdded(resourceId, curator);
    }

    function removeCurator(uint256 resourceId, address curator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _curatorsPerResource[resourceId].remove(curator);
        revokeRole(CURATOR_ROLE, curator);
        emit CuratorRemoved(resourceId, curator);
    }

    function getCurators(uint256 resourceId) public view returns (address[] memory) {
        return _curatorsPerResource[resourceId].values();
    }

    function getResource(uint256 resourceId) public view returns (ResourceMetadata memory) {
        return resources[resourceId];
    }

    function getCategories() public view returns (bytes32[] memory) {
        return _categories.values();
    }

    function getTags(bytes32 category) public view returns (bytes32[] memory) {
        return _categoryTags[category].values();
    }
}
