// Deployment Cost: 900961

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

error Gas_OnlyAdminCanCall();
error Gas_TierLevelGreaterThan255();
error Gas_UserNotWhitelistes();
error Gas_IncorrectUserTier();
error Gas_InsufficientBalance();
error Gas_RecipientNameTooLong();
error Gas_InsufficientAmount();

contract GasContract {
    // Type Decalarations
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    struct Payment {
        uint256 paymentID;
        uint256 amount;
        bool adminUpdated;
        PaymentType paymentType;
        address recipient;
        address admin;
        bytes recipientName; // changed to bytes
    } // Changed layout and type

    // State Variables
    uint256 public constant TRADE_PERCENT = 12; // Changed to constant
    uint256 public immutable totalSupply; // Removed Initialization & changed to immutable
    uint256 public paymentCounter = 0;

    bool wasLastOdd = true;
    address public contractOwner;
    address[5] public administrators;

    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public balances;
    mapping(address => bool) public isOddWhitelistUser;
    mapping(address => uint256) public whiteListStruct;

    // Events
    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        bytes recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < 5 /*administrators.length*/; ++ii) {
            // changed length to 5 since administratirs array is fixed
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                    emit supplyChanged(_admins[ii], totalSupply);
                } else {
                    balances[_admins[ii]] = 0;
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    // Functions
    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        if (!(msg.sender == contractOwner) || !checkForAdmin(msg.sender)) {
            revert Gas_OnlyAdminCanCall();
        }

        if (_tier >= 255) {
            revert Gas_TierLevelGreaterThan255();
        }

        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        bool wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd) {
            wasLastOdd = false;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else {
            wasLastOdd = true;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool) {
        if (balances[msg.sender] < _amount) {
            revert Gas_InsufficientBalance();
        }
        if (bytes(_name).length >= 9) {
            revert Gas_RecipientNameTooLong();
        }

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);

        Payment memory payment;
        payment.admin = address(0);
        payment.adminUpdated = false;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = bytes(_name);
        payment.paymentID = ++paymentCounter;
        payments[msg.sender].push(payment);

        return true;
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        address senderOfTx = msg.sender;
        uint256 usersTier = whitelist[senderOfTx];
        if (usersTier == 0) {
            revert Gas_UserNotWhitelistes();
        }
        if (usersTier >= 4) {
            revert Gas_IncorrectUserTier();
        }

        if (balances[msg.sender] < _amount) {
            revert Gas_InsufficientBalance();
        }
        if (_amount <= 3) {
            revert Gas_InsufficientAmount();
        }

        whiteListStruct[msg.sender] = _amount;

        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        balances[msg.sender] += whitelist[msg.sender];
        balances[_recipient] -= whitelist[msg.sender];

        emit WhiteListTransfer(_recipient);
    }

    // Helper functions
    function balanceOf(address _user) public view returns (uint256 balance) {
        balance = balances[_user];
    }

    function checkForAdmin(address _user) public view returns (bool admin) {
        admin = false;
        address[5] memory _administrators = administrators;
        for (uint256 ii = 0; ii < 5; ++ii) {
            if (_administrators[ii] == _user) {
                admin = true;
            }
        }
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool, uint256) {
        return (true, whiteListStruct[sender]);
    }
}
