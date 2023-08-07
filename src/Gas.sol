// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;


contract GasContract {

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    
    /*
    struct Payment {
        bytes8 recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 paymentID;
        uint256 amount;
        PaymentType paymentType;
    }*/

    uint8 private constant MAX_ADMINS = 5;
    address private immutable contractOwner;
    //uint256 private immutable totalSupply; // cannot be updated
    uint256 private paymentCounter = 0;

    //mapping(uint256 => Payment) private payments;  // paymentCounter -> Payment 
    mapping(address => uint256) private whiteListStruct; 
    mapping(uint256 => address) public administrators;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public balances;

    event AddedToWhitelist(address userAddress, uint256 tier);
    //event supplyChanged(address indexed, uint256 indexed);
    //event Transfer(address recipient, uint256 amount);
    //event PaymentUpdated(address admin, uint256 ID, uint256 amount, bytes8 recipient);
    event WhiteListTransfer(address indexed);
    

    modifier onlyAdminOrOwner() {
        internalOnlyAdminOrOwner();
        _;
    }

    modifier checkIfWhiteListed(address sender) {
        //require(whitelist[msg.sender] != 0);
        if (whitelist[msg.sender] == 0) revert();
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
                    //emit supplyChanged(_admins[ii], _totalSupply);
                }
                unchecked {
	                ++ii;
	            }
        }
    }

    /*
    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) external onlyAdminOrOwner {
        if (_amount <= 0) revert(); // Message deleted for gas savings. Add a small message like "Amount should be > 0" 
        //assert(_amount > 0);

        //Payment storage paymentToUpdate = payments[_ID];
        //paymentToUpdate.admin = _user;
        //paymentToUpdate.paymentType = _type;
        //paymentToUpdate.amount = _amount;
        //emit PaymentUpdated(msg.sender, _ID, _amount, paymentToUpdate.recipientName);
    }
    */

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        //require(_tier < 255); // Message deleted for gas savings. Add a small message like "tier should be < 255"
        if (_tier >= 255) revert(); // Message deleted for gas savings. Add a small message like "tier should be < 255"
        //assert(_tier < 255);

        whitelist[_userAddrs] = _tier > 3 ? 3 : _tier;

        emit AddedToWhitelist(_userAddrs, _tier);
    }


    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        
        //require(balances[msg.sender] >= _amount); // Message deleted for gas savings. Add a small message like "insufficient Balanc"
        //if (balances[msg.sender] < _amount) revert(); // Message deleted for gas savings. Add a small message like "insufficient Balanc"

        //require(_amount > 3); // Message deleted for gas savings. Add a small message like "amount should be > 3"
        //if (_amount <= 3) revert(); // Message deleted for gas savings. Add a small message like "amount should be > 3"

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
                ++ii;
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
        //emit Transfer(_recipient, _amount);

        bytes8 nameAsBytes8;
        assembly {
            let tempName := mload(0x40)  
            calldatacopy(tempName, add(add(_name.offset, 0x20), 8), 8) 
            nameAsBytes8 := mload(tempName) 
        }

        //payments[paymentCounter].paymentType = PaymentType.BasicPayment;
        //payments[paymentCounter].recipient = _recipient;
        //payments[paymentCounter].amount = _amount;
        //payments[paymentCounter].recipientName = nameAsBytes8;  // __name is max 8 bytes
        //payments[paymentCounter].paymentID = paymentCounter++;
    }


    function getPaymentStatus(address sender) public returns (bool, uint256) {        
        return (true, whiteListStruct[sender]);
    }

}