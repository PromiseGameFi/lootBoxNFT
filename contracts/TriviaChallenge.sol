// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TriviaToken is ERC20, Ownable {
    constructor() ERC20("TriviaToken", "TRIVIA") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract TriviaChallenge is Ownable {
    TriviaToken public triviaToken;
    
    struct Question {
        string question;
        string[] options;
        uint8 correctOptionIndex;
        uint256 rewardAmount;
    }
    
    Question[] public questions;
    mapping(address => uint256) public playerScores;
    mapping(address => uint256) public lastAnsweredTimestamp;
    
    uint256 public timeLimit = 30; // 30 seconds to answer
    
    event QuestionAdded(uint256 questionId);
    event AnswerSubmitted(address player, uint256 questionId, bool correct);
    event RewardClaimed(address player, uint256 amount);
    
    constructor(address _tokenAddress) {
        triviaToken = TriviaToken(_tokenAddress);
    }
    
    function addQuestion(
        string memory _question,
        string[] memory _options,
        uint8 _correctOptionIndex,
        uint256 _rewardAmount
    ) public onlyOwner {
        require(_options.length >= 2, "At least 2 options required");
        require(_correctOptionIndex < _options.length, "Invalid correct option index");
        
        questions.push(Question({
            question: _question,
            options: _options,
            correctOptionIndex: _correctOptionIndex,
            rewardAmount: _rewardAmount
        }));
        
        emit QuestionAdded(questions.length - 1);
    }
    
    function getQuestionCount() public view returns (uint256) {
        return questions.length;
    }
    
    function getQuestion(uint256 _questionId) public view returns (
        string memory question,
        string[] memory options,
        uint256 rewardAmount
    ) {
        require(_questionId < questions.length, "Question does not exist");
        Question storage q = questions[_questionId];
        return (q.question, q.options, q.rewardAmount);
    }
    
    function submitAnswer(uint256 _questionId, uint8 _selectedOptionIndex) public {
        require(_questionId < questions.length, "Question does not exist");
        require(block.timestamp - lastAnsweredTimestamp[msg.sender] >= timeLimit, "Please wait before answering again");
        
        Question storage q = questions[_questionId];
        bool correct = (_selectedOptionIndex == q.correctOptionIndex);
        
        lastAnsweredTimestamp[msg.sender] = block.timestamp;
        
        if (correct) {
            playerScores[msg.sender] += 1;
            triviaToken.transfer(msg.sender, q.rewardAmount);
            emit RewardClaimed(msg.sender, q.rewardAmount);
        }
        
        emit AnswerSubmitted(msg.sender, _questionId, correct);
    }
    
    function getPlayerScore(address _player) public view returns (uint256) {
        return playerScores[_player];
    }
    
    function setTimeLimit(uint256 _newTimeLimit) public onlyOwner {
        timeLimit = _newTimeLimit;
    }
}