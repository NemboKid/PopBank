pragma solidity ^0.5.0;


contract PopBank {


    // BITALIA BANK S.r.l.

    ///*Notes:
    // - Fixa identitet via Uportlandia? KYC plus riskbedömning etc. Måste ha ett kreditscore om vi ska kunna ha bankverksamhet.
    // - Erbjuda bolån eller andra typer av collateral loans?
    // - Fixa basic-konto utan ränta.
    // - Jämför räntor mot andra banker.
    // - Vilket problem är det vi löser och varför göra detta på blockkedjan?
    // - Fixa så det funkar även med Bitcoin (RSK dvs)
    // - Stablecoins och hedga genom BTC-terminen som snart släpps enligt Isac
    // - Göra detta utan banktillstånd och låta Ethereum eller liknande stå bakom detta
    // - Betalkort (kolla hur bitrefill gjort etc.). Kanske får börja med prepaid cards, men sen ska vi kunna erbjuda kreditkort
    ///*

    //
    // State variables
    //
    mapping (address => uint) public balances;
    mapping (address => bool) public enrolled;
    mapping(address => BankAccountAddress) public _bankAccountAddresses;
    mapping(address => OwningBankAddress) public _owningBankAccountAddresses;
    mapping(uint => RequestLoan) public requestedLoans;
    mapping(uint => LoanDecision) public loanDecisions;


    /* Let's make sure everyone knows who owns the bank. Use the appropriate keyword for this*/
    address payable public _owner;
    address payable public contractAddress;
    uint public accountId;
    uint public loanNumber;
    uint32 public _totalPublicBankAccounts = 0;
    uint32 public _totalOwningBankAccounts = 0;
    AccountDetails[] public _bankAccountsArray;
    OwningBankAccounts[] public _owningBankArray;



    //
    // Events - publicize actions to external listeners
    //
    event LogPremiumAccountOpened(address indexed accountAddress);
    event LogBasicAccountOpened(address indexed accountAddress);
    event LogDepositMade(address indexed accountAddress, uint amountDeposited);
    event LogWithdrawal(address indexed accountAddress, uint withdrawalAmount, uint newBalance);
    event LogInternalMoneyTransfer(address indexed accountAddressFrom, address indexed accountAddressTo, uint moneySent, uint newBalance);


    //
    // Functions
    //
    //Skulle kunna öppna upp 4-5 ägande konton som alla håller pengar för olika syften. Ett konto för ränta på sparkonto.
    //...ett annat för att sköta utbetalningar/inlåning/utlåning/övrigt etc.
    constructor() public {
        /* Set the owner to the creator of this contract */
        _owner = msg.sender;
        _owningBankArray.push(OwningBankAccounts({
                isBank: true,
                id: 0,
                timeStamp: now,
                balance: 0,
                ownerAddress: _owner
            }
            ));
        _bankAccountAddresses[msg.sender].accountSet = true;
        _bankAccountAddresses[msg.sender].accountNumber = 0;
        _totalOwningBankAccounts++;
        contractAddress = address(this);
    }

    struct OwningBankAccounts {
        bool isBank;
        uint id;
        uint balance;
        uint timeStamp;
        address payable ownerAddress;
    }

    struct AccountDetails {
        bool isPremium;
        bool accountLock;
        uint Id;
        uint interestRate;
        uint balance;
        bool paidFee;
        uint timeStamp;
        address payable owner;
    }

    struct BankAccountAddress {
        bool accountSet;
        uint32 accountNumber; // accountNumber member is used to index the bank accounts array
    }

    struct OwningBankAddress {
        bool accountSet;
        uint32 accountNumber; // accountNumber member is used to index the bank accounts array
    }


    struct RequestLoan {
        uint loanNr;
        uint loanAmount;
        uint loanDuration;
        address payable lendingAddress;
        LoanState state;
    }


    struct LoanDecision {
        uint loanNumber;
        uint loanAmount;
        uint loanExpiration;
        uint lendingInterest;
        uint amountToRepay;
        address payable lendingAddress;
        bool loanDecision;
        bool active;
        bool isCollateral;
        LoanState state;
    }

    enum LoanState { Pending, Negative, Active, Completed }




    ////
    //LOAN FUNCTIONS//
    ////
    function loanRequest(uint _loanAmount, uint _loanDuration) public returns(bool requestSubmitted) {
        loanNumber = loanNumber + 1;
        requestedLoans[loanNumber] = RequestLoan({loanNr: loanNumber, loanAmount: _loanAmount, loanDuration: _loanDuration, lendingAddress: msg.sender, state: LoanState.Pending});
        return true;
    }


    function loanDecision(uint _loanNumber, bool _approved, uint interestRate, bool _isCollateral) public payable returns (bool success) {
        if(_approved = true) {
        loanDecisions[_loanNumber].state = LoanState.Active;
        loanDecisions[_loanNumber].lendingInterest = interestRate;
        loanDecisions[_loanNumber].loanAmount = requestedLoans[_loanNumber].loanAmount;
        loanDecisions[_loanNumber].lendingAddress = requestedLoans[_loanNumber].lendingAddress;
        loanDecisions[_loanNumber].loanDecision = _approved;
        loanDecisions[_loanNumber].active = _approved;
        loanDecisions[_loanNumber].isCollateral = _isCollateral;


        //Var noga med att tiden stämmer
        loanDecisions[_loanNumber].loanExpiration = (requestedLoans[_loanNumber].loanDuration * 1) + now;
        //activateLoan(_loanNumber);
        return true;
        }
            else {
                loanDecisions[_loanNumber].state = LoanState.Negative;
            }
    }


        //Try to make it internal/private
        //Make it eventually automatic with Ethereum Alarm Clock or similar.
        function activateLoan(uint _loanNumber) internal returns(uint) {
            balances[loanDecisions[_loanNumber].lendingAddress] += loanDecisions[_loanNumber].loanAmount;
            loanDecisions[_loanNumber].lendingAddress.transfer(loanDecisions[_loanNumber].loanAmount);
            loanDecisions[_loanNumber].active = true;
            loanDecisions[_loanNumber].amountToRepay = (loanDecisions[_loanNumber].loanAmount * loanDecisions[_loanNumber].lendingInterest /100);
            return balances[loanDecisions[_loanNumber].lendingAddress];
        }


        //Make it eventually automatic with Ethereum Alarm Clock or similar.
        //Calculate the interest rate
        function repayLoan(uint _loanNumber) public {
            require(msg.sender == _owner);
            require(loanDecisions[_loanNumber].active = true);
            require(now >= loanDecisions[_loanNumber].loanExpiration);
            balances[loanDecisions[_loanNumber].lendingAddress] -=
            (loanDecisions[_loanNumber].loanAmount * loanDecisions[_loanNumber].lendingInterest /100);
            balances[address(this)] += loanDecisions[_loanNumber].loanAmount;
        }


        ////
        //ACCOUNT FUNCTIONS//
        ////
        function openBasicAccount() public returns (uint32 newBankAccountNumber) {
            require(_bankAccountAddresses[msg.sender].accountSet == false); //har inte redan ett account
            newBankAccountNumber = _totalPublicBankAccounts;

            _bankAccountsArray.push(AccountDetails({
                    isPremium: false,
                    accountLock: false,
                    Id: newBankAccountNumber,
                    interestRate: 0,
                    paidFee: false,
                    timeStamp: now,
                    balance: 0,
                    owner: msg.sender
                }
                ));

                // Add the new account
            _bankAccountAddresses[msg.sender].accountSet = true;
            _bankAccountAddresses[msg.sender].accountNumber = newBankAccountNumber;

            _totalPublicBankAccounts++;

            emit LogBasicAccountOpened(msg.sender);
            return newBankAccountNumber;
        }


        function openPremiumAccount() public payable returns (uint32 newBankAccountNumber) {
            require(msg.value == 1000000000000000000, "The cost of a premium account is 1 ETH");
            require(_bankAccountAddresses[msg.sender].accountSet == false); //har inte redan ett account

        // Assign the new bank account number
            newBankAccountNumber = _totalPublicBankAccounts;

        // Add new bank account to the array
            _bankAccountsArray.push(AccountDetails({
                    isPremium: true,
                    accountLock: false,
                    Id: newBankAccountNumber,
                    interestRate: 4,
                    paidFee: true,
                    timeStamp: now,
                    balance: 0,
                    owner: msg.sender
                }
                ));

            // Add the new account
            _bankAccountAddresses[msg.sender].accountSet = true;
            _bankAccountAddresses[msg.sender].accountNumber = newBankAccountNumber;

             _owningBankArray[0].balance += msg.value;

            // Move to the next bank account
            _totalPublicBankAccounts++;

            emit LogPremiumAccountOpened(msg.sender);
            return newBankAccountNumber;
        }



    ////
    //PAYMENT FUNCTIONS//
    ////
    function depositAmount() public payable returns (uint accountBalance) {
        require(msg.value > 0);
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
        _bankAccountsArray[accountNumber_].balance += msg.value;
        emit LogDepositMade(msg.sender, msg.value);
        return _bankAccountsArray[accountNumber_].balance;
    }


    function withdrawAmount(uint amountToWithdraw) public payable returns (uint accountBalance) {
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
        require (_bankAccountsArray[accountNumber_].balance >= amountToWithdraw, "you don't have enough funds");
        _bankAccountsArray[accountNumber_].balance -= amountToWithdraw;
        return _bankAccountsArray[accountNumber_].balance;
    }


    //omkalkylera räntan varje år eller dylikt
    //gör det omöjligt att betala ut ränta mer än en gång per år
    //hur räknar man ränta på insatt belopp om beloppet ändras ofta under ett år?
    function payoutInterest(uint bankAccountId) public payable returns (uint amountPaid) {
        uint accountNumber_ = _bankAccountsArray[bankAccountId].Id;
        uint interestAmount = _bankAccountsArray[accountNumber_].interestRate;
        uint accountBalance = _bankAccountsArray[accountNumber_].balance;
        //uint amountToPay = (accountBalance * interestAmount / 100);
        //payoutToAddress.transfer(amountToPay); //push payment direkt till adress
        _bankAccountsArray[accountNumber_].balance += (accountBalance * interestAmount / 100);
         _owningBankArray[0].balance -= (accountBalance * interestAmount / 100);
        //balances[owner] -= (accountBalance * interestAmount / 100);
        return (interestAmount);
    }


        /*Send ethers to another account internally */
    function internalTransfer(uint etherAmount, address toAccount) payable public returns (uint accountBalance) {
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
        uint32 sendTo = _bankAccountAddresses[toAccount].accountNumber;
        require(_bankAccountsArray[accountNumber_].balance >= etherAmount);
        _bankAccountsArray[accountNumber_].balance -= etherAmount;
        _bankAccountsArray[sendTo].balance += etherAmount;
        emit LogInternalMoneyTransfer(msg.sender, toAccount, etherAmount, _bankAccountsArray[accountNumber_].balance);
        return _bankAccountsArray[accountNumber_].balance;
    }



    //make an external push payment
    function externalTransfer(uint etherAmount, address payable toAccount) payable public returns (uint accountBalance) {
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
        require(_bankAccountsArray[accountNumber_].balance >= etherAmount);

        //Vi gör betalningen, sen drar vi pengar från deras konto.
        toAccount.transfer(etherAmount);
        _bankAccountsArray[accountNumber_].balance -= etherAmount;
        return _bankAccountsArray[accountNumber_].balance;
    }



    ////
    //BALANCE FUNCTIONS//
    ////
    function checkContractBalance() public view returns (uint contractBalance) {
        return address(this).balance;
    }


    function checkPersonalAccountBalance() public view returns (uint accountBalance) {
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
        return _bankAccountsArray[accountNumber_].balance;
    }


    function checkSpecificAccountBalance(uint _id) public view returns (uint accountBalance) {
        return _bankAccountsArray[_id].balance;
    }


    function checkOwnerBankAccountBalance() public view returns (uint accountBalance) {
        uint32 accountNumber_ = _owningBankAccountAddresses[_owner].accountNumber;
        return _owningBankArray[accountNumber_].balance;
    }



    //get your money back and delete account from array. GDPR?
    function closeBankAccount(uint Id) public returns (bool success) {
        require( _bankAccountAddresses[msg.sender].accountNumber == Id, "ID doesn't match");
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
        uint balanceLeft = _bankAccountsArray[accountNumber_].balance;
        if (balanceLeft > 0) {
            msg.sender.transfer(balanceLeft);
        }
        delete _bankAccountsArray[Id];
        delete _bankAccountAddresses[msg.sender];
        return true;
    }


    //ADMIN FUNCTIONS//
    function changeAccountInterest(uint Id, address thisAddress, uint newInterest) public returns (uint newAccountInterestRate) {
        require(_bankAccountsArray[Id].owner == thisAddress, "Id and ownerAddress don't match");
        require(_bankAccountsArray[Id].interestRate != newInterest, "interest must be different from current");
        _bankAccountsArray[Id].interestRate = newInterest;
        return(_bankAccountsArray[Id].interestRate);
    }


    function lockAccount(uint Id, address thisAddress) public returns (bool isLocked) {
        require(_bankAccountsArray[Id].owner == thisAddress, "Id and ownerAddress don't match");
        _bankAccountsArray[Id].accountLock = true;
        return _bankAccountsArray[Id].accountLock;
    }


    function killContract() public payable returns(bool dead) {
        require(msg.sender == _owner);
        selfdestruct(_owner);
        return(true);
    }


    // Fallback function - Called if other functions don't match call or
    // sent ether without data
    // Typically, called when invalid data is sent
    // Added so ether sent to this contract is reverted if the contract fails
    // otherwise, the sender's money is transferred to contract
    function()external payable {
        require(msg.data.length == 0);
    }
}
