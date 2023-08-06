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

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bytes8 recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    uint256 private immutable totalSupply; // cannot be updated
    address private immutable contractOwner;
    uint256 private paymentCounter = 0;

    mapping(uint256 => Payment) private payments;  // paymentCounter -> Payment 
    mapping(address => uint256) private whiteListStruct; 
    mapping(uint256 => address) public administrators;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public balances;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(address admin, uint256 ID, uint256 amount, bytes8 recipient);
    event WhiteListTransfer(address indexed);
    

    modifier onlyAdminOrOwner() {
        require(checkForAdmin(msg.sender) || msg.sender == contractOwner);
        _;
    }

    modifier checkIfWhiteListed(address sender) {
        require(whitelist[msg.sender] != 0);
        _;
    }


    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < 5; ++ii) {
                administrators[ii] = _admins[ii];

                if (_admins[ii] == msg.sender) {
                    balances[msg.sender] = _totalSupply;
                    emit supplyChanged(_admins[ii], _totalSupply);
                } else {
                    balances[_admins[ii]] = 0;
                    emit supplyChanged(_admins[ii], 0);
                }
        }
    }


    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        require(_ID > 0); // Message deleted for gas savings. Add a small message like "ID must be > 0"
        require(_amount > 0); // Message deleted for gas savings. Add a small message like "Amount should be > 0"

        payments[_ID].admin = _user;
        payments[_ID].paymentType = _type;
        payments[_ID].amount = _amount;
        emit PaymentUpdated(msg.sender, _ID, _amount, payments[_ID].recipientName);
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require(_tier < 255); // Message deleted for gas savings. Add a small message like "tier should be < 255"
        whitelist[_userAddrs] = _tier > 3 ? 3 : _tier;

        emit AddedToWhitelist(_userAddrs, _tier);
    }


    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        whiteListStruct[msg.sender] = _amount;
        
        require(balances[msg.sender] >= _amount); // Message deleted for gas savings. Add a small message like "insufficient Balanc"
        require(_amount > 3); // Message deleted for gas savings. Add a small message like "amount should be > 3"
        
        balances[msg.sender] -= _amount - whitelist[msg.sender];
        balances[_recipient] += _amount - whitelist[msg.sender];
        
        emit WhiteListTransfer(_recipient);
    }


    function checkForAdmin(address _user) public view returns (bool admin) {
        bool admin = false;
        for (uint256 ii = 0; ii < 5; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
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
        //address senderOfTx = msg.sender;
        require(balances[msg.sender] >= _amount); // Message deleted for gas savings. Add a small message like "Sender has insufficient Balance"

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;

        emit Transfer(_recipient, _amount);

        bytes8 nameAsBytes8;
        assembly {
            let tempName := mload(0x40)  
            calldatacopy(tempName, add(add(_name.offset, 0x20), 8), 8) 
            nameAsBytes8 := mload(tempName) 
        }
        Payment memory payment;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = nameAsBytes8;  // __name is max 8 bytes
        payment.paymentID = ++paymentCounter;
        payments[paymentCounter] = payment;
    }


    function getPaymentStatus(address sender) public returns (bool, uint256) {        
        return (true, whiteListStruct[sender]);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }


    fallback() external payable {
         payable(msg.sender).transfer(msg.value);
    }
}