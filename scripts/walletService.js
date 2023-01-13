import { ethers } from 'ethers';
const hre = require("hardhat");
const abi = require("./ParkingControl.json");


class ConnectWallet {
    constructor() {
        const contractAddress="0xf56a35b6A7d3479BD682e35763901e1fEcEc0504";
        const contractABI = abi.abi;
        
        this.init_wallet()

        this._provider = new ethers.providers.Web3Provider(window.ethereum);
        this._signer = this._provider.getSigner();

        // Get the node connection and wallet connection.
        //const provider = new hre.ethers.providers.AlchemyProvider("goerli", process.env.GOERLI_API_KEY);

        // Instantiate connected contract.
        this.contract = new hre.ethers.Contract(contractAddress, contractABI, this._signer);

        console.log(this.contract)
    }

    
    async init_wallet() {
        // For initial startup
        try {
            const { etherium } = window;

            const accounts = await etherium.request({method: 'eth_accounts'})

            if (accounts.length > 0) {
                const account = accounts[0];
                console.log('Connected Wallet: ', account)
            } else {console.log('Please connect MetaMask account')}
        } catch (error) {
            console.log('Error while connecting wallet: ', error)
        }
    }

    async connectWallet() {
        // For the button 'connect Wallet'
        try {
            const {ethereum} = window;
      
            if (!ethereum) {
              console.log("please install MetaMask");
            }
      
            const accounts = await ethereum.request({
              method: 'eth_requestAccounts'
            });
      
            this.account = accounts[0];
          } catch (error) {
            console.log(error);
          }
    }
}

export default ConnectWallet;


export async function claimParkingPass(numbersplate, place){
    const req = await this.contract.claimParkingPass(numbersplate, place);
}

export async function claimVisitorPass(numbersplate){
    const req = await this.contract.claimVisitorPass(numbersplate, Date.now());
}

export async function renewParkingPass(){
    const req = await this.contract.claimParkingPass();
}

export async function confirmParkingPass(numbersplate){
    const req = await this.contract.claimParkingPass(numbersplate, Date.now());
}

export async function verifyParkingPass(numbersplate){
    const req = await this.contract.verifyParkingPass(numbersplate);
}


