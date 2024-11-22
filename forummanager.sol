// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VanaForumManager is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _forumTopicCounter;
    Counters.Counter private _eventCounter;

    struct ForumTopic {
        uint256 id;
        string title;
        string description;
        address[] participants;
        mapping(address => uint256) participantComments;
    }

    struct Event {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        address[] speakers;
        mapping(address => bool) registeredAttendees;
    }

    mapping(uint256 => ForumTopic) public forumTopics;
    mapping(uint256 => Event) public events;

    event ForumTopicCreated(uint256 indexed id, string title, string description);
    event ForumCommentAdded(uint256 indexed topicId, address indexed user, uint256 commentCount);
    event EventCreated(uint256 indexed id, string title, string description, uint256 startTime, uint256 endTime);
    event EventAttendeeRegistered(uint256 indexed eventId, address indexed attendee);

    function createForumTopic(string memory title, string memory description) public onlyOwner {
        _forumTopicCounter.increment();
        uint256 topicId = _forumTopicCounter.current();
        forumTopics[topicId] = ForumTopic(topicId, title, description, new address[](0));
        emit ForumTopicCreated(topicId, title, description);
    }

    function addForumComment(uint256 topicId) public {
        require(topicId <= _forumTopicCounter.current(), "Invalid forum topic ID");
        forumTopics[topicId].participants.push(msg.sender);
        forumTopics[topicId].participantComments[msg.sender]++;
        emit ForumCommentAdded(topicId, msg.sender, forumTopics[topicId].participantComments[msg.sender]);
    }

    function createEvent(
        string memory title,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        address[] memory speakers
    ) public onlyOwner {
        _eventCounter.increment();
        uint256 eventId = _eventCounter.current();
        events[eventId] = Event(eventId, title, description, startTime, endTime, speakers);
        emit EventCreated(eventId, title, description, startTime, endTime);
    }

    function registerForEvent(uint256 eventId) public {
        require(eventId <= _eventCounter.current(), "Invalid event ID");
        events[eventId].registeredAttendees[msg.sender] = true;
        emit EventAttendeeRegistered(eventId, msg.sender);
    }
}
