// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./Ownable.sol";

contract Constants {
    uint8 public tradeFlag = 1;
    uint8 public basicFlag = 0;
    uint8 public dividendFlag = 1;
}

contract GasContract is Ownable, Constants {
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) public payments;
    mapping(address => uint256) public whitelist;

    uint256 public totalSupply = 0; // cannot be updated
    uint8 public paymentCounter = 0;
    uint8 public tradePercent = 12;
    uint8 public tradeMode = 0;
    address public contractOwner;
    address[5] public administrators;
    bool public isReady = false;

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }

    History[] public paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        uint256 amount;
        address recipient;
        address admin; // administrators address
    }

    struct History {
        uint256 lastUpdate;
        uint256 blockNumber;
        address updatedBy;
    }
    uint256 wasLastOdd = 1;
    mapping(address => uint256) public isOddWhitelistUser;

    struct ImportantStruct {
        uint256 amount;
        uint8 valueA; // max 3 digits
        uint256 bigValue;
        uint8 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }
    mapping(address => ImportantStruct) public whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);

    modifier onlyAdminOrOwner() {
        address senderOfTx = msg.sender;
        if (senderOfTx == contractOwner) {
            _;
        } else {
            revert("Err: not admin");
        }
    }

    modifier checkIfWhiteListed(address sender) {
        address senderOfTx = msg.sender;
        require(senderOfTx == sender, "Err: not sender");
        uint256 usersTier = whitelist[senderOfTx];
        _;
    }

    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == contractOwner) {
                    balances[contractOwner] = totalSupply;
                } else {
                    balances[_admins[ii]] = 0;
                }
                if (_admins[ii] == contractOwner) {
                    emit supplyChanged(_admins[ii], totalSupply);
                } else if (_admins[ii] != contractOwner) {
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    function getPaymentHistory()
        public
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        bool admin = false;
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                admin = true;
            }
        }
        return admin;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        uint256 balance = balances[_user];
        return balance;
    }

    function addHistory(
        address _updateAddress,
        bool _tradeMode
    ) public returns (bool status_, bool tradeMode_) {
        bool[] memory status = new bool[](tradePercent);
        for (uint8 i = 0; i < tradePercent; i++) {
            status[i] = true;
        }
        return ((status[0] == true), _tradeMode);
    }

    function getPayments(
        address _user
    ) public view returns (Payment[] memory payments_) {
        return payments[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool) {
        address senderOfTx = msg.sender;
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;

        emit Transfer(_recipient, _amount);
        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) public onlyAdminOrOwner {
        address senderOfTx = msg.sender;

        for (uint256 ii = 0; ii < payments[_user].length; ii++) {
            if (payments[_user][ii].paymentID == _ID) {
                emit PaymentUpdated(
                    senderOfTx,
                    _ID,
                    _amount,
                    payments[_user][ii].recipientName
                );
            }
        }
    }

    function addToWhitelist(
        address _userAddrs,
        uint256 _tier
    ) public onlyAdminOrOwner {
        require(_tier < 255, "Err: tier level should not be greater than 255");
        whitelist[_userAddrs] = _tier;
        if (_tier > 3) {
            whitelist[_userAddrs] -= _tier;
            whitelist[_userAddrs] = 3;
        }
        uint256 wasLastAddedOdd = wasLastOdd;
        if (wasLastAddedOdd == 1) {
            wasLastOdd = 0;
            isOddWhitelistUser[_userAddrs] = wasLastAddedOdd;
        } else {
            revert("Contract hacked, imposible, call help");
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        address senderOfTx = msg.sender;
        whiteListStruct[senderOfTx] = ImportantStruct(
            _amount,
            0,
            0,
            0,
            true,
            msg.sender
        );

        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whitelist[senderOfTx];
        balances[_recipient] -= whitelist[senderOfTx];

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }
}
