// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;


contract GasContract {

    uint8 private constant MAX_ADMINS = 5;
    address private immutable contractOwner;
    uint256 private paymentCounter = 0;

    mapping(address => uint256) private whiteListStruct; 
    mapping(uint256 => address) public administrators;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public balances;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);
    

    modifier onlyAdminOrOwner() {
        internalOnlyAdminOrOwner();
        _;
    }

    function internalOnlyAdminOrOwner() internal {
        //if (!checkForAdmin(msg.sender) && msg.sender != contractOwner) revert();
        require(checkForAdmin(msg.sender) || msg.sender == contractOwner);
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        
        for (uint256 ii = 0; ii < MAX_ADMINS;) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == msg.sender) {
                    balances[msg.sender] = _totalSupply;
                }
                unchecked {
                    ++
                    ii
                    ;
	            }
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        //require(_tier < 255);
        if (_tier >= 255) revert();
        whitelist[_userAddrs] = _tier > 3 ? 3 : _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }


    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public {

        if (balances[msg.sender] < _amount || _amount <= 3) revert();
        unchecked {
            whiteListStruct[msg.sender] = _amount;
            uint256 effectiveAmount = _amount - whitelist[msg.sender];
            balances[msg.sender] -= effectiveAmount;
            balances[_recipient] += effectiveAmount;
        }
        emit WhiteListTransfer(_recipient);
    }


    function checkForAdmin(address _user) public view returns (bool admin) {
        bool admin = false;
        for (uint256 ii = 0; ii < MAX_ADMINS;) {
            if (administrators[ii] == _user) {
                admin = true;
            }
            unchecked {
                ++
                ii
                ;
            }
        }
    }


    function balanceOf(address _user) public view returns (uint256) {
        return balances[_user];
    }


    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public  {
        //require(balances[msg.sender] >= _amount); // Message deleted for gas savings. Add a small message like "Sender has insufficient Balance"
        if (balances[msg.sender] < _amount) revert();
        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }

        bytes8 nameAsBytes8;
        assembly {
            let tempName := mload(0x40)  
            calldatacopy(tempName, add(add(_name.offset, 0x20), 8), 8) 
            nameAsBytes8 := mload(tempName) 
        }
    }


    function getPaymentStatus(address sender) public returns (bool, uint256) {        
        return (true, whiteListStruct[sender]);
    }

}