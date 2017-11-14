pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token { 
  function transfer(address receiver, uint256 amount) public returns (bool);
  function balanceOf(address who) public constant returns (uint256);
}

contract QROTokenCrowdsale is Ownable {
  using SafeMath for uint256;
  Token public token;
  uint256 public startTime;
  uint256 public endTime;
  address public wallet;
  uint256 public rate;
  uint256 public cap;
  uint256 public weiRaised;
  uint256 public tokensSold;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function QROTokenCrowdsale(uint256 _startTime, 
                                         uint256 _endTime, 
                                         address _wallet, 
                                         address _tokenAddress) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != address(0));
    
    token = Token(_tokenAddress);
    startTime = _startTime;
    endTime = _endTime;
    rate = 14000;
    cap = 210000000 * (10**18);
    wallet = _wallet;
  }

  function () payable {
    buyTokens(msg.sender);
  }

  function setRate(uint256 _rate) public onlyOwner {
    rate = _rate;
  }

  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());
    uint256 weiAmount = msg.value;
    uint256 tokenAmount = weiAmount.mul(rate);
    require(tokensSold.add(tokenAmount) <= cap);

    tokensSold = tokensSold.add(tokenAmount);
    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokenAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
    wallet.transfer(weiAmount);
  }

  
  function withdrawAll(address _to) public onlyOwner {
    require(_to != address(0));
    require(hasEnded());
    var balance = token.balanceOf(this);
    require(balance > 0);
    token.transfer(_to, balance);
  }

  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0 && msg.value >= 1 ether;
    return withinPeriod && nonZeroPurchase;
  }

  function hasEnded() public constant returns (bool) {
    bool timeReached = now > endTime;
    bool capReached = tokensSold >= cap;
    return timeReached || capReached;
  }

}

