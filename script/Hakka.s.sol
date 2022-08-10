// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import "./Constants.sol";

interface IRateModel {
    function stakingRate(uint256 time) external returns (uint256 rate);
}

interface IHakka {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IsHakka {
    function symbol() external returns (string memory symbol);
    function balanceOf(address owner) external view returns (uint256);
    function stake(address to, uint256 amount, uint256 time) external returns (uint256 wAmount);
    function unstake(address to, uint256 index, uint256 wAmount) external returns (uint256 amount);
}

interface IsHakkaStake {
    function balanceOf(address owner) external view returns (uint256);
    function stake(uint256 amount) external;
    function earned(address account) external view returns (uint256);
    function withdraw(uint256 amount) external;
    function getReward() external;
}

interface IVestingVault {
    function balanceOf(address owner) external view returns (uint256); 
    function withdraw() external;
}

contract HakkaScript is Script {

    IHakka private hakka = IHakka(0x0E29e5AbbB5FD88e28b2d355774e73BD47dE3bcd);
    IRateModel private rateModel = IRateModel(0x3474B74139C192D0781812ca70CC410d19cB6A2D);
    IsHakka private sHakka = IsHakka(0xB925863a15eBdEAE1a638BF2B6Fd00D4db897A62);
    IsHakkaStake private sHakkaStake = IsHakkaStake(0x735A80510536a9A18c8824f40DBc92824640c95a);
    IVestingVault private vestingVault = IVestingVault(0x51F12323820b3c0077864990d9E6aD9604238Ed6);

    uint256 period = 31557600; // 一年

    function setUp() public {
        vm.createSelectFork(FORK_URL); 
    }

    function run() public {
        vm.prank(address(0x1D075f1F543bB09Df4530F44ed21CA50303A65B2));
        hakka.transfer(ME, 254800 ether);

        vm.startPrank(ME);
        console.log(unicode"-- 取得 period Voting Power --");
        console.log(rateModel.stakingRate(period));

        console.log("\n");

        console.log(unicode"-- 取得擁有的 Hakka Token --");
        uint256 hakkaBalance = hakka.balanceOf(ME);
        console.log(hakkaBalance);

        console.log("\n");

        console.log(unicode"-- 全部投入 Hakka Staking --");
        sHakka.stake(
            ME,
            hakkaBalance,
            period
        );

        console.log("\n");

        uint256 sHakkaBalance = sHakka.balanceOf(ME);
        console.log(unicode"-- sHakka 擁有數量 --");
        console.log(sHakkaBalance);

        console.log("\n");

        console.log(unicode"-- 全數投入 Farms 中 --");
        sHakkaStake.stake(sHakkaBalance);

        console.log("\n");

        console.log(unicode"-- sHakka LP 擁有數量 --");
        uint256 sHakkaStakeLP = sHakkaStake.balanceOf(ME);
        console.log(sHakkaStakeLP);

        console.log("\n");

        vm.warp(block.timestamp + period);

        console.log(unicode"-- 取得 period 後獎勵 --");
        uint256 earned = sHakkaStake.earned(ME);
        console.log(earned);

        console.log("\n");

        console.log(unicode"-- 領取獎勵 --"); 
        sHakkaStake.getReward();

        console.log("\n");

        console.log(unicode"-- 取回 sHakka LP --"); 
        sHakkaStake.withdraw(sHakkaStakeLP);

        console.log("\n");

        console.log(unicode"-- sHakka 擁有數量 --");
        sHakkaBalance = sHakka.balanceOf(ME);
        console.log(sHakkaBalance);

        console.log("\n");

        console.log(unicode"-- 取回 Vault 回饋 --");
        uint256 selfVaultBalance = vestingVault.balanceOf(ME);
        console.log(selfVaultBalance);
        vestingVault.withdraw();

        console.log("\n");

        console.log(unicode"-- 取回 sHakka 質押 --");
        sHakka.unstake(
            ME,
            0,
            sHakkaBalance
        );

        console.log("\n");

        uint256 afterBalance = hakka.balanceOf(ME);
        console.log(unicode"-- 取得擁有的 Hakka Token --");
        console.log(afterBalance);

        console.log("\n");

        console.log(unicode"-- 結算 period 後最終獲得收益 --");
        console.log(afterBalance - hakkaBalance);

        vm.stopPrank();
    }
}
