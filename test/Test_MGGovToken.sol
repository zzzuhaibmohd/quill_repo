// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/interface.sol";
import "../src/MGGovToken.sol";

contract ContractTest is DSTest{

    MockGovToken public _govContract;
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    address public _govAddr = 0x94bf1d448072c3f2F804edAe7d744893658a74c8;
    
    function setUp() public {
        cheats.createSelectFork("https://rpc.ankr.com/eth_goerli", 8219544);
        _govContract = MockGovToken(_govAddr);

        //pre-mint tokens by owner
        cheats.startPrank(_govContract.owner());
        _govContract.mint(_govContract.owner(),10000000000000000000);
        _govContract.mint(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,10000000000000000000);
        _govContract.mint(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,10000000000000000000);
        _govContract.mint(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db,10000000000000000000);
        //_govContract.mint(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB,10000000000000000000);
        cheats.stopPrank();
    }

    function test_ownerBurnTokens() public{
        console.log("Total Token Supply: ", _govContract.totalSupply());

        address owner = _govContract.owner();
        address victim = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

        cheats.startPrank(owner);

        console.log("Current Balance of Victim: ", _govContract.balanceOf(victim));
        _govContract.burn(victim, 10000000000000000000);
        console.log("TOKEN BURN COMPLETE!!!");
        
        console.log("Current Balance of Victim - post burn: ", _govContract.balanceOf(victim));

        cheats.stopPrank();

        // console.log("Delegator of User#1: ", _govContract.delegates(victim));
        // console.log("Current Votes of User#1: ", _govContract.getCurrentVotes(victim));
        console.log("Total Token Supply - post burn: ", _govContract.totalSupply());
    }

    function test_delegateToZeroAddress() public{
        console.log("Total Token Supply: ", _govContract.totalSupply());

        address user_one = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        cheats.startPrank(user_one);

        console.log("DELEGATE TOKENS TO ADDRESS(0)!!!");
        _govContract.delegate(address(0)); //delegate to zero address

        console.log("Delegator of user_one: ", _govContract.delegates(user_one));
        console.log("Current Votes of user_one: ", _govContract.getCurrentVotes(user_one));
            
        console.log("Current Votes of address(0): ", _govContract.getCurrentVotes(user_one));
    
        cheats.stopPrank();
    }

    function test_selfDelegation() public{

        address owner = _govContract.owner();
        console.log("Owner of Contract: ", _govContract.owner());

        address victim = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

        cheats.startPrank(owner);

        console.log("Current balance of Owner Tokens : ", _govContract.balanceOf(owner));

        console.log("DELEGATE TOKENS TO SELF i.e OWNER!!!");
        _govContract.delegate(owner);

        console.log("Delegator of owner: ", _govContract.delegates(owner));
        console.log("Current Votes of owner: ", _govContract.getCurrentVotes(owner));

        console.log("TRANSFER TOKENS TO VICTIM!!!");
        _govContract.transfer(victim, 10000000000000000000);

        cheats.stopPrank();

        cheats.startPrank(victim);

        console.log("Current balance of Victim Tokens : ", _govContract.balanceOf(victim));

        console.log("Delegator of victim: ", _govContract.delegates(victim));
        console.log("Current Votes of victim: ", _govContract.getCurrentVotes(victim));

        console.log("DELEGATE TOKENS TO SELF i.e VICTIM!!!");
        _govContract.delegate(victim);

        console.log("Delegator of victim - post self delegation: ", _govContract.delegates(victim));
        console.log("Current Votes of victim - post self delegation: ", _govContract.getCurrentVotes(victim));
        console.log("Current Votes of owner - post self delegation: ", _govContract.getCurrentVotes(owner));

        //console.log("Total Token Supply: ", _govContract.totalSupply());
        cheats.stopPrank();
    }

    function test_multipleCheckPointsinBlock() public{

        //check if votes are accounted properly even if multiple checkpoints happen in same block

        address user_one = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        address user_two = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        address user_three = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        uint blockNum = block.number;

        console.log("Current Votes of user_three: ", _govContract.getCurrentVotes(user_three));

        cheats.startPrank(user_one);

        console.log("DELEGATE TOKENS TO user_three!!!");
        _govContract.delegate(user_three);

        console.log("Delegator of user_one: ", _govContract.delegates(user_one));
        console.log("Current Votes of user_three: ", _govContract.getCurrentVotes(user_three));
                
        cheats.stopPrank();

        cheats.startPrank(user_two);

        console.log("DELEGATE TOKENS TO user_three!!!");
        _govContract.delegate(user_three);

        console.log("Delegator of user_two: ", _govContract.delegates(user_two));
        console.log("Current Votes of user_three: ", _govContract.getCurrentVotes(user_three));
        cheats.stopPrank();

        cheats.roll(blockNum + 2);

        console.log(_govContract.getPriorVotes(user_three, blockNum));
    }

    function test_getPriorVotesinSameBlock() public {
        address user_one = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        address user_three = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
        uint blockNum = block.number;

        console.log("Current Votes of user_three: ", _govContract.getCurrentVotes(user_three));

        cheats.startPrank(user_one);

        console.log("DELEGATE TOKENS TO user_three!!!");
        _govContract.delegate(user_three);

        console.log("Delegator of user_one: ", _govContract.delegates(user_one));
        console.log("Current Votes of user_three: ", _govContract.getCurrentVotes(user_three));
                
        cheats.stopPrank();

        try _govContract.getPriorVotes(user_three, blockNum){
        } catch Error(string memory Exception) {
            console.log("test_getPriorVotesinSameBlock() REVERT : ", Exception);
        }
    }
}