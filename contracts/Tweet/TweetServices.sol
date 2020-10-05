pragma solidity ^0.6.0;
import "../Identity/IdentityRegistry.sol";
import "../Identity/ClaimHolder.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract TweetServices is Ownable, ERC20 {

    struct Comment {
        address commenter; 
        bytes text; 
    }

    struct Tweet {
        uint256 tweetId;
        uint256 time;
        uint256 commentID;
        address tweeter;
        mapping(uint256 => Comment) comment;
        bytes content;
    }
    

    IdentityRegistry internal identityRegistry;

    mapping (address => mapping(uint256 => Tweet)) public tweets;
    mapping (address => uint256) internal tweetPostedNo;
    
    event NewTweet(address indexed tweetOwner, uint256 indexed tweetId, uint256 indexed tweetTime);
    event ReTweet(address indexed reTweeter, address indexed tweetOwner, uint256 indexed tweetId);
    event CommentTweet(address indexed commenter, address indexed tweetOwner, uint256 indexed tweetId);
   
    modifier validUser(ClaimHolder _userIdentity) {
        require(identityRegistry.isValidUser(_userIdentity));
        _;
    }
    
    modifier validTweet(address tweetOwner, uint256 tweetId) {
        require(tweets[tweetOwner][tweetId].tweetId > 0, " Tweet with tweetId does not exist");
        _;
    }
    
    
    constructor(address _identityRegistry) ERC20("TwitterToken", "TWT") public {
        identityRegistry = IdentityRegistry(_identityRegistry);
    }
   
    function tweetNewPost(bytes memory content) validUser(ClaimHolder(msg.sender)) public returns(bool) {
        Tweet memory newTweet;
        newTweet.tweetId = tweetPostedNo[msg.sender] + 1;
        newTweet.tweeter = msg.sender;
        newTweet.time = now;
        newTweet.content = content;
        tweets[msg.sender][newTweet.tweetId] = newTweet;
        tweetPostedNo[msg.sender]++;
        emit NewTweet(msg.sender, newTweet.tweetId, now);
        return true;
    }

   
    function reTweet(address tweetOwner, uint256 tweetId) 
            validUser(ClaimHolder(msg.sender)) 
            validTweet(tweetOwner, tweetId)
            public returns(bool) 
    {
        Tweet memory newTweet;
        newTweet = tweets[tweetOwner][tweetId];
        newTweet.tweetId = tweetPostedNo[msg.sender] + 1;
        tweets[msg.sender][newTweet.tweetId] = newTweet;
        tweetPostedNo[msg.sender]++;
        if(msg.sender != tweetOwner) {
            _mint(tweetOwner, 1);
        }
        emit ReTweet(msg.sender, tweetOwner, tweetId);
        emit NewTweet(msg.sender, newTweet.tweetId, now);
        return true;
    }


    function commentOnTweet(address tweetOwner, uint256 tweetId, bytes memory text) 
            validUser(ClaimHolder(msg.sender)) 
            validTweet(tweetOwner, tweetId)
            public returns(bool) 
    {
        Comment memory newComment;
        newComment.text = text;
        newComment.commenter = msg.sender;
        tweets[tweetOwner][tweetId].comment[tweets[tweetOwner][tweetId].commentID] = newComment;
        tweets[tweetOwner][tweetId].commentID++;
        emit CommentTweet(msg.sender, tweetOwner, tweetId);
        return true;
    }
}