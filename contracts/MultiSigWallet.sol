// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
    Reference: https://solidity-by-example.org/app/multi-sig-wallet/
               https://www.youtube.com/watch?v=Yx0oifA9j6I  
 */
contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(
        address indexed owner,
        uint indexed txId,
        address indexed to,
        uint value,
        bytes data
    );
    event Confirm(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(address indexed owner, uint indexed txId);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public requiredConfirmations;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    // Mapping => txId -> owner -> bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner {
        require(isOwner[msg.sender], "Only owner can invoke this method");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "Tx does not exist");
        _;
    }

    modifier txConfirmed(uint _txId) {
        require(getConfirmationCount(_txId) == requiredConfirmations, "Tx requires more confirmations");
        _;
    }

    modifier notConfimed(uint _txId) {
        require(!isConfirmed[_txId][msg.sender], "Tx already confirmed");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "Tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint _requiredConfirmations) {
        require(_owners.length > 1, "More owners required");
        require(
            _requiredConfirmations > 0 && 
            _requiredConfirmations <= _owners.length, 
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner already added");
            
            isOwner[owner] = true;
            owners.push(owner);
        }
        requiredConfirmations = _requiredConfirmations;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address _to, uint _value, bytes calldata _data) external onlyOwner {
        require(_to != address(0), "Invalid to address");
        require(_value > 0, "Invalid value");
        
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false
            })
        );

        emit Submit(msg.sender, transactions.length - 1, _to, _value, _data);
    }

    function confirmTransaction(uint _txId) external txExists(_txId) notConfimed(_txId) notExecuted(_txId) onlyOwner {
        isConfirmed[_txId][msg.sender] = true;
        emit Confirm(msg.sender, _txId);
    }

    function executeTransaction(uint _txId) external txExists(_txId) notExecuted(_txId) txConfirmed(_txId) onlyOwner{
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Tx execution failed");
        emit Execute(msg.sender, _txId);
    }

    function revokeTxConfirmation(uint _txId) external txExists(_txId) notExecuted(_txId) onlyOwner {
        require(isConfirmed[_txId][msg.sender], "Tx not confirmed");

        isConfirmed[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    function getConfirmationCount(uint _txId) private view txExists(_txId) onlyOwner returns (uint count){
        for (uint index = 0; index < owners.length; index++) {
           if(isConfirmed[_txId][owners[index]]) {
                count += 1;
           }     
        }
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    } 

    function getTransaction(uint _txId) public view txExists(_txId) returns (Transaction memory){
        return transactions[_txId];
    }
}