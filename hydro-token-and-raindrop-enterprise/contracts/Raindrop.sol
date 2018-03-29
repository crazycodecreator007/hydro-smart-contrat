pragma solidity ^0.4.18;

import "./Ownable.sol";

contract Raindrop is Ownable {

  // Event for when an address is authenticated
  event AuthenticateEvent(uint partnerId, address indexed from, uint value);
  // Event for when an address is whitelisted to authenticate
  event WhitelistEvent(uint partnerId, address target, bool whitelist);

  address hydroContract = 0x0;

  mapping (uint => mapping (address => bool)) public whitelist;
  mapping (uint => mapping (address => partnerValues)) public partnerMap;
  mapping (uint => mapping (address => hydroValues)) public hydroPartnerMap;

  struct partnerValues {
      uint value;
      uint challenge;
  }

  struct hydroValues {
      uint value;
      uint timestamp;
  }

  function setHydroContractAddress(address _addr) public onlyOwner {
      hydroContract = _addr;
  }

  /* Function to whitelist partner address. Can only be called by owner */
  function whitelistAddress(address _target, bool _whitelistBool, uint _partnerId) public onlyOwner {
      whitelist[_partnerId][_target] = _whitelistBool;
      WhitelistEvent(_partnerId, _target, _whitelistBool);
  }

  /* Function to authenticate user
     Restricted to whitelisted partners */
  function authenticate(address _sender, uint _value, uint _challenge, uint _partnerId) public {
      require(msg.sender == hydroContract);
      require(whitelist[_partnerId][_sender]);         // Make sure the sender is whitelisted
      require(hydroPartnerMap[_partnerId][_sender].value == _value);
      updatePartnerMap(_sender, _value, _challenge, _partnerId);
      AuthenticateEvent(_partnerId, _sender, _value);
  }

  function checkForValidChallenge(address _sender, uint _partnerId) public view returns (uint value){
      if (hydroPartnerMap[_partnerId][_sender].timestamp > block.timestamp){
          return hydroPartnerMap[_partnerId][_sender].value;
      }
      return 1;
  }

  /* Function to update the hydroValuesMap. Called exclusively from the Hydro API */
  function updateHydroMap(address _sender, uint _value, uint _partnerId) public onlyOwner {
      hydroPartnerMap[_partnerId][_sender].value = _value;
      hydroPartnerMap[_partnerId][_sender].timestamp = block.timestamp + 1 days;
  }

  /* Function called by Hydro API to check if the partner has validated
   * The partners value and data must match and it must be less than a day since the last authentication
   */
  function validateAuthentication(address _sender, uint _challenge, uint _partnerId) public constant returns (bool _isValid) {
      if (partnerMap[_partnerId][_sender].value == hydroPartnerMap[_partnerId][_sender].value
      && block.timestamp < hydroPartnerMap[_partnerId][_sender].timestamp
      && partnerMap[_partnerId][_sender].challenge == _challenge) {
          return true;
      }
      return false;
  }

  /* Function to update the partnerValuesMap with their amount and challenge string */
  function updatePartnerMap(address _sender, uint _value, uint _challenge, uint _partnerId) internal {
      partnerMap[_partnerId][_sender].value = _value;
      partnerMap[_partnerId][_sender].challenge = _challenge;
  }

}
