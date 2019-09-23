import React, { Component } from "react";
import ReactDOM from 'react-dom';
import PopBank from "./contracts/PopBank.json";
import getWeb3 from "./utils/getWeb3";
import Header from "./Header.js";
import Footer from "./Footer.js";

import "./App.css";


class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      storageValue: 0,
      web3: null,
      accounts: null,
      contract: null,
      moneySend: '',
      _numberOfAccounts: 0,
      accountBalance: 0,
      _contractBalance: 0,
      _ownerBalance: 0,
      _deposit: '',
      accountNumber: '',
      info1: null,
      info2: null,
      info3: null,
      info4: null,
      info5: null,
      info6: null,
      info7: null,
      info8: null
    };

    this.openPremiumAccount = this.openPremiumAccount.bind(this);
    this.depositMoneyToAccount = this.depositMoneyToAccount.bind(this);
    this.getInfo = this.getInfo.bind(this);
    this.payInterest = this.payInterest.bind(this);
    this.withdrawMoney = this.withdrawMoney.bind(this);

  }

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = PopBank.networks[networkId];
      const instance = new web3.eth.Contract(
        PopBank.abi,
        deployedNetwork && deployedNetwork.address,
      );
      console.log(instance.methods);

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ web3, accounts, contract: instance });
    } catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  async openPremiumAccount(event) {
     const contractCall = await this.state.contract.methods;
     const web3 = this.state.web3;
     const accounts = await this.state.accounts;
     const amount = web3.utils.toWei(
       this.state.moneySend,
       'ether'
     )
     try {
     await contractCall.openPremiumAccount().send({
       from: accounts[0],
       value: amount
     });
   } catch(error) {
     console.log(error)
     console.log(`Something went wrong`);
   };
 }

 async depositMoneyToAccount(event) {
    const contractCall = await this.state.contract.methods;
    const web3 = this.state.web3;
    const accounts = await this.state.accounts;
    const amount = web3.utils.toWei(
      this.state._deposit,
      'ether'
    )
    try {
    await contractCall.depositAmount().send({
      from: accounts[0],
      value: amount
    });
  } catch(error) {
    console.log(error)
    console.log(`Something went wrong, probably with the payment`);
  };
}

async getInfo(e) {
      const contractCall = await this.state.contract.methods;
      const thisBalance = await contractCall.checkPersonalAccountBalance().call();
      const thisOwnerBalance = await contractCall.checkOwnerBankAccountBalance().call();
      const thisContractBalance = await contractCall.checkContractBalance().call();
      const thisNumber = await contractCall._totalPublicBankAccounts().call();
      return this.setState({
        accountBalance: thisBalance,
        _ownerBalance: thisOwnerBalance,
        _contractBalance: thisContractBalance,
        _numberOfAccounts: thisNumber
      });
    }


    async bankAccountInfo(event) {
         const contractCall = await this.state.contract.methods;
         const accounts = await this.state.accounts;
         const accountInfo = await this.state.accountNumber;
         const thisResponse = await contractCall._bankAccountsArray(this.state.accountNumber).send({
           from: accounts[0]
         });
         const test3r = await contractCall._bankAccountsArray(accountInfo).call();
         const _info1 = await JSON.stringify(test3r['isPremium']);
         const _info2 = await JSON.stringify(test3r['accountLock']);
         const _info3 = await JSON.stringify(test3r['Id']);
         const _info4 = await JSON.stringify(test3r['interestRate']);
         const _info5 = await JSON.stringify(test3r['paidFee']);
         const _info6 = await JSON.stringify(test3r['timeStamp']);
         const _info7 = await JSON.stringify(test3r['balance']);
         const _info8 = await JSON.stringify(test3r['owner']);
         this.setState({
         info1: _info1,
         info2: _info2,
         info3: _info3,
         info4: _info4,
         info5: _info5,
         info6: _info6,
         info7: _info7,
         info8: _info8
      });
         return console.log(test3r);
       }

       async payInterest(event) {
            const contractCall = await this.state.contract.methods;
            const accounts = await this.state.accounts;
            const accountInfo = await this.state.accountNumber;
            const thisResponse = await contractCall.payoutInterest(this.state.accountNumber).send({
              from: accounts[0]
            });
            return this.bankAccountInfo(accountInfo);
            return console.log(thisResponse);
          }

        async withdrawMoney(event) {
              const contractCall = await this.state.contract.methods;
              const accounts = await this.state.accounts;
              const thisResponse = await contractCall.withdrawAmount(this.state.moneySend).send({
                from: accounts[0]
              });
              return console.log(thisResponse);
            }


  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <Header />
        <div className="title">
          <img src="http://cdn.onlinewebfonts.com/svg/img_519442.png" alt="Logo"></img>
        <h1>Bankissimo</h1>
        <h3><i>- The only bank that can help you when nobody else's there...</i></h3>
        <hr></hr>
      </div>
      <div className="open-account">
        <h3>Open an amazing account here!</h3>
        <input type="number"
                      placeholder="Ether"
                      value={this.state.moneySend}
                      onChange={(e) => this.setState({moneySend: e.target.value})}
                    />
        <button onClick={this.openPremiumAccount}>Open Account</button>
        <br></br>
        <input type="number" placeholder="Amount" value={this.state._deposit} onChange={(e) => this.setState({_deposit: e.target.value})} />
        <button onClick={this.depositMoneyToAccount}>Deposit Amount</button>
        <br></br>
        <input type="number"
                      placeholder="Ether to withdraw"
                      value={this.state.moneySend}
                      onChange={(e) => this.setState({moneySend: e.target.value})}
                    />
        <button onClick={this.withdrawMoney}>Make withdrawal</button>
      </div>
      <div className="info-div">
        <div className="general-info">
        <h3>General Info</h3>
        <p>Total Contract Balance: { this.state._contractBalance }</p>
        <p>Current Account's Balance: { this.state.accountBalance }</p>
        <p>Bank Owner's Balance: { this.state._ownerBalance }</p>
        <p>Number of Accounts: {this.state._numberOfAccounts}</p>
        <button onClick={this.getInfo}>Generate info</button>
      </div>
        <div className="account-info">
          <h3><u>Account Functions</u></h3>
          <input type="number" placeholder="account id" value={this.state.accountNumber} onChange={(e) => this.setState({accountNumber: e.target.value})} />
          <button onClick={this.payInterest}>Pay interest to account</button>
          <input type="number" placeholder="account id" value={this.state.accountNumber} onChange={(e) => this.setState({accountNumber: e.target.value})} />
          <button onClick={this.bankAccountInfo}>Get account info</button>
          <br></br>
          <br></br>
          <h3><u>Info About Account</u></h3>
                  <p><b>isPremium: {this.state.info1}</b></p>
                  <hr></hr>
                  <p><b> accountLock: {this.state.info2}</b></p>
                  <hr></hr>
                  <p> <b> Id: {this.state.info3}</b></p>
                  <hr></hr>
                  <p> <b>interestRate: {this.state.info4}</b></p>
                  <hr></hr>
                  <p><b>paidFee: {this.state.info5}</b></p>
                  <hr></hr>
                  <p><b>timeStamp: {this.state.info6}</b></p>
                  <hr></hr>
                  <p><b>balance: {this.state.info7}</b></p>
                  <hr></hr>
                  <p><b>owner: {this.state.info8}</b></p>
                </div>
              </div>
        <Footer />
      </div>
    );
  }
}

export default App;
