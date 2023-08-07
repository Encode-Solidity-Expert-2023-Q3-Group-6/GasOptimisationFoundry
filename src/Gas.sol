// Deployment Cost: 900961

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// error Gas_OnlyAdminCanCall();
// error Gas_TierLevelGreaterThan255();
// error Gas_UserNotWhitelistes();
// error Gas_IncorrectUserTier();
// error Gas_InsufficientBalance();
// error Gas_RecipientNameTooLong();
// error Gas_InsufficientAmount();

contract GasContract {
    // Type Decalarations

    struct Payment {
        uint256 paymentID;
        uint256 amount;
        address recipient;
        bytes8 recipientName; // changed to bytes
    } // Changed layout and type

    // State Variables
    uint256 private immutable totalSupply; // Removed Initialization & changed to immutable
    uint256 private paymentCounter = 0;

    bool wasLastOdd = true;
    address private contractOwner;
    address[5] public administrators;

    mapping(address => Payment[]) private payments;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) public balances;
    mapping(address => bool) private isOddWhitelistUser;
    mapping(address => uint256) private whiteListStruct;

    // Events
    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address indexed recipient, uint256 indexed amount);
    event PaymentUpdated(
        address indexed admin,
        uint256 indexed ID,
        uint256 amount,
        bytes indexed recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < 5 /*administrators.length*/; ++ii) {
            // changed length to 5 since administratirs array is fixed
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == msg.sender) {
                    balances[msg.sender] = totalSupply;
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
            revert(); // Gas_OnlyAdminCanCall();
        }

        if (_tier >= 255) {
            revert(); // Gas_TierLevelGreaterThan255();
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
            revert(); // Gas_InsufficientBalance();
        }
        if (bytes(_name).length >= 9) {
            revert(); // Gas_RecipientNameTooLong();
        }

        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
        }
        Payment memory payment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = bytes8(bytes(_name));
        unchecked {
            payment.paymentID = ++paymentCounter;
        }
        payments[msg.sender].push(payment);

        emit Transfer(_recipient, _amount);
        return true;
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        uint256 usersTier = whitelist[msg.sender];
        if (usersTier == 0) {
            revert(); // Gas_UserNotWhitelistes();
        }
        if (usersTier >= 4) {
            revert(); // Gas_IncorrectUserTier();
        }

        if (balances[msg.sender] < _amount) {
            revert(); // Gas_InsufficientBalance();
        }
        if (_amount <= 3) {
            revert(); // Gas_InsufficientAmount();
        }

        whiteListStruct[msg.sender] = _amount;

        unchecked {
            balances[msg.sender] -= _amount;
            balances[_recipient] += _amount;
            balances[msg.sender] += whitelist[msg.sender];
            balances[_recipient] -= whitelist[msg.sender];
        }

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
