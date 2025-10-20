---
name: web3-testing
description: ユニットテスト、統合テスト、メインネットフォークを使用してHardhatとFoundryでスマートコントラクトを包括的にテストします。Solidityコントラクトをテストする時、ブロックチェーンテストスイートをセットアップする時、またはDeFiプロトコルを検証する時に使用してください。
---

> **[English](../../../../plugins/blockchain-web3/skills/web3-testing/SKILL.md)** | **日本語**

# Web3スマートコントラクトテスト

Hardhat、Foundry、高度なテストパターンを使用したスマートコントラクトの包括的なテスト戦略をマスターします。

## このスキルを使用するタイミング

- スマートコントラクトのユニットテストを書く
- 統合テストスイートをセットアップする
- ガス最適化テストを実行する
- エッジケースのファズテスト
- 現実的なテストのためにメインネットをフォーク
- テストカバレッジレポートを自動化する
- Etherscanでコントラクトを検証する

## Hardhatテストセットアップ

```javascript
// hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("solidity-coverage");

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      forking: {
        url: process.env.MAINNET_RPC_URL,
        blockNumber: 15000000
      }
    },
    goerli: {
      url: process.env.GOERLI_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  gasReporter: {
    enabled: true,
    currency: 'USD',
    coinmarketcap: process.env.COINMARKETCAP_API_KEY
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};
```

## ユニットテストパターン

```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture, time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Token Contract", function () {
  // テストセットアップ用のフィクスチャ
  async function deployTokenFixture() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("Token");
    const token = await Token.deploy();

    return { token, owner, addr1, addr2 };
  }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { token, owner } = await loadFixture(deployTokenFixture);
      expect(await token.owner()).to.equal(owner.address);
    });

    it("Should assign total supply to owner", async function () {
      const { token, owner } = await loadFixture(deployTokenFixture);
      const ownerBalance = await token.balanceOf(owner.address);
      expect(await token.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      const { token, owner, addr1 } = await loadFixture(deployTokenFixture);

      await expect(token.transfer(addr1.address, 50))
        .to.changeTokenBalances(token, [owner, addr1], [-50, 50]);
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const { token, addr1 } = await loadFixture(deployTokenFixture);
      const initialBalance = await token.balanceOf(addr1.address);

      await expect(
        token.connect(addr1).transfer(owner.address, 1)
      ).to.be.revertedWith("Insufficient balance");
    });

    it("Should emit Transfer event", async function () {
      const { token, owner, addr1 } = await loadFixture(deployTokenFixture);

      await expect(token.transfer(addr1.address, 50))
        .to.emit(token, "Transfer")
        .withArgs(owner.address, addr1.address, 50);
    });
  });

  describe("Time-based tests", function () {
    it("Should handle time-locked operations", async function () {
      const { token } = await loadFixture(deployTokenFixture);

      // 時間を1日増加
      await time.increase(86400);

      // 時間依存機能をテスト
    });
  });

  describe("Gas optimization", function () {
    it("Should use gas efficiently", async function () {
      const { token } = await loadFixture(deployTokenFixture);

      const tx = await token.transfer(addr1.address, 100);
      const receipt = await tx.wait();

      expect(receipt.gasUsed).to.be.lessThan(50000);
    });
  });
});
```

## Foundryテスト(Forge)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    Token token;
    address owner = address(1);
    address user1 = address(2);
    address user2 = address(3);

    function setUp() public {
        vm.prank(owner);
        token = new Token();
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1000000 * 10**18);
    }

    function testTransfer() public {
        vm.prank(owner);
        token.transfer(user1, 100);

        assertEq(token.balanceOf(user1), 100);
        assertEq(token.balanceOf(owner), token.totalSupply() - 100);
    }

    function testFailTransferInsufficientBalance() public {
        vm.prank(user1);
        token.transfer(user2, 100); // 失敗するべき
    }

    function testCannotTransferToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid recipient");
        token.transfer(address(0), 100);
    }

    // ファズテスト
    function testFuzzTransfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= token.totalSupply());

        vm.prank(owner);
        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
    }

    // チートコードを使ったテスト
    function testDealAndPrank() public {
        // アドレスにETHを与える
        vm.deal(user1, 10 ether);

        // アドレスをなりすます
        vm.prank(user1);

        // 機能をテスト
        assertEq(user1.balance, 10 ether);
    }

    // メインネットフォークテスト
    function testForkMainnet() public {
        vm.createSelectFork("https://eth-mainnet.alchemyapi.io/v2/...");

        // メインネットコントラクトとやり取り
        address dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        assertEq(IERC20(dai).symbol(), "DAI");
    }
}
```

## 高度なテストパターン

### スナップショットとリバート
```javascript
describe("Complex State Changes", function () {
  let snapshotId;

  beforeEach(async function () {
    snapshotId = await network.provider.send("evm_snapshot");
  });

  afterEach(async function () {
    await network.provider.send("evm_revert", [snapshotId]);
  });

  it("Test 1", async function () {
    // 状態変更を行う
  });

  it("Test 2", async function () {
    // 状態がリバートされ、クリーンな状態
  });
});
```

### メインネットフォーク
```javascript
describe("Mainnet Fork Tests", function () {
  let uniswapRouter, dai, usdc;

  before(async function () {
    await network.provider.request({
      method: "hardhat_reset",
      params: [{
        forking: {
          jsonRpcUrl: process.env.MAINNET_RPC_URL,
          blockNumber: 15000000
        }
      }]
    });

    // 既存のメインネットコントラクトに接続
    uniswapRouter = await ethers.getContractAt(
      "IUniswapV2Router",
      "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
    );

    dai = await ethers.getContractAt(
      "IERC20",
      "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    );
  });

  it("Should swap on Uniswap", async function () {
    // 実際のUniswapコントラクトでテスト
  });
});
```

### アカウントのなりすまし
```javascript
it("Should impersonate whale account", async function () {
  const whaleAddress = "0x...";

  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [whaleAddress]
  });

  const whale = await ethers.getSigner(whaleAddress);

  // クジラのトークンを使用
  await dai.connect(whale).transfer(addr1.address, ethers.utils.parseEther("1000"));
});
```

## ガス最適化テスト

```javascript
const { expect } = require("chai");

describe("Gas Optimization", function () {
  it("Compare gas usage between implementations", async function () {
    const Implementation1 = await ethers.getContractFactory("OptimizedContract");
    const Implementation2 = await ethers.getContractFactory("UnoptimizedContract");

    const contract1 = await Implementation1.deploy();
    const contract2 = await Implementation2.deploy();

    const tx1 = await contract1.doSomething();
    const receipt1 = await tx1.wait();

    const tx2 = await contract2.doSomething();
    const receipt2 = await tx2.wait();

    console.log("Optimized gas:", receipt1.gasUsed.toString());
    console.log("Unoptimized gas:", receipt2.gasUsed.toString());

    expect(receipt1.gasUsed).to.be.lessThan(receipt2.gasUsed);
  });
});
```

## カバレッジレポート

```bash
# カバレッジレポートを生成
npx hardhat coverage

# 出力例:
# File                | % Stmts | % Branch | % Funcs | % Lines |
# -------------------|---------|----------|---------|---------|
# contracts/Token.sol |   100   |   90     |   100   |   95    |
```

## コントラクト検証

```javascript
// Etherscanで検証
await hre.run("verify:verify", {
  address: contractAddress,
  constructorArguments: [arg1, arg2]
});
```

```bash
# またはCLI経由
npx hardhat verify --network mainnet CONTRACT_ADDRESS "Constructor arg1" "arg2"
```

## CI/CD統合

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '16'

      - run: npm install
      - run: npx hardhat compile
      - run: npx hardhat test
      - run: npx hardhat coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v2
```

## リソース

- **references/hardhat-setup.md**: Hardhat設定ガイド
- **references/foundry-setup.md**: Foundryテストフレームワーク
- **references/test-patterns.md**: テストのベストプラクティス
- **references/mainnet-forking.md**: フォークテスト戦略
- **references/contract-verification.md**: Etherscan検証
- **assets/hardhat-config.js**: 完全なHardhat設定
- **assets/test-suite.js**: 包括的なテスト例
- **assets/foundry.toml**: Foundry設定
- **scripts/test-contract.sh**: 自動テストスクリプト

## ベストプラクティス

1. **テストカバレッジ**: 90%以上のカバレッジを目指す
2. **エッジケース**: 境界条件をテスト
3. **ガスリミット**: 関数がブロックガスリミットに達しないことを検証
4. **再入攻撃**: 再入攻撃の脆弱性をテスト
5. **アクセス制御**: 不正アクセス試行をテスト
6. **イベント**: イベント発行を検証
7. **フィクスチャ**: コード重複を避けるためにフィクスチャを使用
8. **メインネットフォーク**: 実際のコントラクトでテスト
9. **ファズテスト**: プロパティベーステストを使用
10. **CI/CD**: コミットごとにテストを自動化
