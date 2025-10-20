---
name: solidity-security
description: 一般的な脆弱性を防ぎ、セキュアなSolidityパターンを実装するためのスマートコントラクトセキュリティのベストプラクティスをマスターします。スマートコントラクトを書く時、既存コントラクトを監査する時、またはブロックチェーンアプリケーションのセキュリティ対策を実装する時に使用してください。
---

> **[English](../../../../plugins/blockchain-web3/skills/solidity-security/SKILL.md)** | **日本語**

# Solidityセキュリティ

スマートコントラクトセキュリティのベストプラクティス、脆弱性防止、セキュアなSolidity開発パターンをマスターします。

## このスキルを使用するタイミング

- セキュアなスマートコントラクトを書く
- 脆弱性のために既存コントラクトを監査する
- セキュアなDeFiプロトコルを実装する
- 再入攻撃、オーバーフロー、アクセス制御の問題を防ぐ
- セキュリティを維持しながらガス使用量を最適化する
- プロフェッショナル監査のためのコントラクトを準備する
- 一般的な攻撃ベクトルを理解する

## 重大な脆弱性

### 1. 再入攻撃(Reentrancy)
攻撃者が状態が更新される前にあなたのコントラクトにコールバックします。

**脆弱なコード:**
```solidity
// 再入攻撃に対して脆弱
contract VulnerableBank {
    mapping(address => uint256) public balances;

    function withdraw() public {
        uint256 amount = balances[msg.sender];

        // 危険: 状態更新前の外部呼び出し
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);

        balances[msg.sender] = 0;  // 遅すぎる!
    }
}
```

**セキュアなパターン(Checks-Effects-Interactions):**
```solidity
contract SecureBank {
    mapping(address => uint256) public balances;

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        // EFFECTS: 外部呼び出し前に状態を更新
        balances[msg.sender] = 0;

        // INTERACTIONS: 外部呼び出しは最後
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

**代替案: ReentrancyGuard**
```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureBank is ReentrancyGuard {
    mapping(address => uint256) public balances;

    function withdraw() public nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "Insufficient balance");

        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

### 2. 整数オーバーフロー/アンダーフロー

**脆弱なコード(Solidity < 0.8.0):**
```solidity
// 脆弱
contract VulnerableToken {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        // オーバーフローチェックなし - ラップアラウンド可能
        balances[msg.sender] -= amount;  // アンダーフロー可能!
        balances[to] += amount;          // オーバーフロー可能!
    }
}
```

**セキュアなパターン(Solidity >= 0.8.0):**
```solidity
// Solidity 0.8以降はオーバーフロー/アンダーフローチェックが組み込み
contract SecureToken {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        // オーバーフロー/アンダーフローで自動的にrevert
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```

**Solidity < 0.8.0の場合、SafeMathを使用:**
```solidity
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SecureToken {
    using SafeMath for uint256;
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
    }
}
```

### 3. アクセス制御

**脆弱なコード:**
```solidity
// 脆弱: 誰でも重要な機能を呼び出せる
contract VulnerableContract {
    address public owner;

    function withdraw(uint256 amount) public {
        // アクセス制御なし!
        payable(msg.sender).transfer(amount);
    }
}
```

**セキュアなパターン:**
```solidity
import "@openzeppelin/contracts/access/Ownable.sol";

contract SecureContract is Ownable {
    function withdraw(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }
}

// またはカスタムロールベースアクセスを実装
contract RoleBasedContract {
    mapping(address => bool) public admins;

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin");
        _;
    }

    function criticalFunction() public onlyAdmin {
        // 保護された機能
    }
}
```

### 4. フロントランニング

**脆弱:**
```solidity
// フロントランニングに対して脆弱
contract VulnerableDEX {
    function swap(uint256 amount, uint256 minOutput) public {
        // 攻撃者がmempoolでこれを見てフロントランニング
        uint256 output = calculateOutput(amount);
        require(output >= minOutput, "Slippage too high");
        // スワップを実行
    }
}
```

**緩和策:**
```solidity
contract SecureDEX {
    mapping(bytes32 => bool) public usedCommitments;

    // ステップ1: トレードにコミット
    function commitTrade(bytes32 commitment) public {
        usedCommitments[commitment] = true;
    }

    // ステップ2: トレードを明らかにする(次のブロック)
    function revealTrade(
        uint256 amount,
        uint256 minOutput,
        bytes32 secret
    ) public {
        bytes32 commitment = keccak256(abi.encodePacked(
            msg.sender, amount, minOutput, secret
        ));
        require(usedCommitments[commitment], "Invalid commitment");
        // スワップを実行
    }
}
```

## セキュリティのベストプラクティス

### Checks-Effects-Interactionsパターン
```solidity
contract SecurePattern {
    mapping(address => uint256) public balances;

    function withdraw(uint256 amount) public {
        // 1. CHECKS: 条件を検証
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(amount > 0, "Amount must be positive");

        // 2. EFFECTS: 状態を更新
        balances[msg.sender] -= amount;

        // 3. INTERACTIONS: 外部呼び出しは最後
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

### Pull Over Pushパターン
```solidity
// これを推奨(pull)
contract SecurePayment {
    mapping(address => uint256) public pendingWithdrawals;

    function recordPayment(address recipient, uint256 amount) internal {
        pendingWithdrawals[recipient] += amount;
    }

    function withdraw() public {
        uint256 amount = pendingWithdrawals[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}

// これよりも(push)
contract RiskyPayment {
    function distributePayments(address[] memory recipients, uint256[] memory amounts) public {
        for (uint i = 0; i < recipients.length; i++) {
            // 転送が失敗するとバッチ全体が失敗
            payable(recipients[i]).transfer(amounts[i]);
        }
    }
}
```

### 入力検証
```solidity
contract SecureContract {
    function transfer(address to, uint256 amount) public {
        // 入力を検証
        require(to != address(0), "Invalid recipient");
        require(to != address(this), "Cannot send to contract");
        require(amount > 0, "Amount must be positive");
        require(amount <= balances[msg.sender], "Insufficient balance");

        // 転送を実行
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
}
```

### 緊急停止(サーキットブレーカー)
```solidity
import "@openzeppelin/contracts/security/Pausable.sol";

contract EmergencyStop is Pausable, Ownable {
    function criticalFunction() public whenNotPaused {
        // 機能のロジック
    }

    function emergencyStop() public onlyOwner {
        _pause();
    }

    function resume() public onlyOwner {
        _unpause();
    }
}
```

## ガス最適化

### より小さな型の代わりに`uint256`を使用
```solidity
// ガス効率が良い
contract GasEfficient {
    uint256 public value;  // 最適

    function set(uint256 _value) public {
        value = _value;
    }
}

// 非効率
contract GasInefficient {
    uint8 public value;  // 依然として256ビットスロットを使用

    function set(uint8 _value) public {
        value = _value;  // 型変換のための追加ガス
    }
}
```

### ストレージ変数をパック
```solidity
// ガス効率的(1スロットに3変数)
contract PackedStorage {
    uint128 public a;  // スロット0
    uint64 public b;   // スロット0
    uint64 public c;   // スロット0
    uint256 public d;  // スロット1
}

// ガス非効率(各変数が別スロット)
contract UnpackedStorage {
    uint256 public a;  // スロット0
    uint256 public b;  // スロット1
    uint256 public c;  // スロット2
    uint256 public d;  // スロット3
}
```

### 関数引数に`memory`の代わりに`calldata`を使用
```solidity
contract GasOptimized {
    // よりガス効率的
    function processData(uint256[] calldata data) public pure returns (uint256) {
        return data[0];
    }

    // 非効率
    function processDataMemory(uint256[] memory data) public pure returns (uint256) {
        return data[0];
    }
}
```

### データストレージにイベントを使用(適切な場合)
```solidity
contract EventStorage {
    // イベント発行はストレージより安価
    event DataStored(address indexed user, uint256 indexed id, bytes data);

    function storeData(uint256 id, bytes calldata data) public {
        emit DataStored(msg.sender, id, data);
        // 必要でない限りコントラクトストレージに保存しない
    }
}
```

## 一般的な脆弱性チェックリスト

```solidity
// セキュリティチェックリストコントラクト
contract SecurityChecklist {
    /**
     * [ ] 再入攻撃防止(ReentrancyGuardまたはCEIパターン)
     * [ ] 整数オーバーフロー/アンダーフロー(Solidity 0.8以降またはSafeMath)
     * [ ] アクセス制御(Ownable、ロール、modifier)
     * [ ] 入力検証(requireステートメント)
     * [ ] フロントランニング緩和(該当する場合はcommit-reveal)
     * [ ] ガス最適化(パックドストレージ、calldata)
     * [ ] 緊急停止メカニズム(Pausable)
     * [ ] 支払いにpull over pushパターン
     * [ ] 信頼されていないコントラクトへのdelegatecallなし
     * [ ] 認証にtx.originを使用しない(msg.senderを使用)
     * [ ] 適切なイベント発行
     * [ ] 関数の最後に外部呼び出し
     * [ ] 外部呼び出しの戻り値をチェック
     * [ ] ハードコードされたアドレスなし
     * [ ] アップグレードメカニズム(プロキシパターンの場合)
     */
}
```

## セキュリティのためのテスト

```javascript
// Hardhatテスト例
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Security Tests", function () {
    it("Should prevent reentrancy attack", async function () {
        const [attacker] = await ethers.getSigners();

        const VictimBank = await ethers.getContractFactory("SecureBank");
        const bank = await VictimBank.deploy();

        const Attacker = await ethers.getContractFactory("ReentrancyAttacker");
        const attackerContract = await Attacker.deploy(bank.address);

        // 資金を預金
        await bank.deposit({value: ethers.utils.parseEther("10")});

        // 再入攻撃を試行
        await expect(
            attackerContract.attack({value: ethers.utils.parseEther("1")})
        ).to.be.revertedWith("ReentrancyGuard: reentrant call");
    });

    it("Should prevent integer overflow", async function () {
        const Token = await ethers.getContractFactory("SecureToken");
        const token = await Token.deploy();

        // オーバーフローを試行
        await expect(
            token.transfer(attacker.address, ethers.constants.MaxUint256)
        ).to.be.reverted;
    });

    it("Should enforce access control", async function () {
        const [owner, attacker] = await ethers.getSigners();

        const Contract = await ethers.getContractFactory("SecureContract");
        const contract = await Contract.deploy();

        // 不正な出金を試行
        await expect(
            contract.connect(attacker).withdraw(100)
        ).to.be.revertedWith("Ownable: caller is not the owner");
    });
});
```

## 監査準備

```solidity
contract WellDocumentedContract {
    /**
     * @title Well Documented Contract
     * @dev 監査のための適切なドキュメントの例
     * @notice このコントラクトはユーザーの預金と出金を処理します
     */

    /// @notice ユーザー残高のマッピング
    mapping(address => uint256) public balances;

    /**
     * @dev コントラクトにETHを預金
     * @notice 誰でも資金を預けられます
     */
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
    }

    /**
     * @dev ユーザーの残高を出金
     * @notice 再入攻撃を防ぐためにCEIパターンに従います
     * @param amount 出金するwei単位の金額
     */
    function withdraw(uint256 amount) public {
        // CHECKS
        require(amount <= balances[msg.sender], "Insufficient balance");

        // EFFECTS
        balances[msg.sender] -= amount;

        // INTERACTIONS
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

## リソース

- **references/reentrancy.md**: 包括的な再入攻撃防止
- **references/access-control.md**: ロールベースアクセスパターン
- **references/overflow-underflow.md**: SafeMathと整数安全性
- **references/gas-optimization.md**: ガス節約テクニック
- **references/vulnerability-patterns.md**: 一般的な脆弱性カタログ
- **assets/solidity-contracts-templates.sol**: セキュアなコントラクトテンプレート
- **assets/security-checklist.md**: 監査前チェックリスト
- **scripts/analyze-contract.sh**: 静的解析ツール

## セキュリティ分析ツール

- **Slither**: 静的解析ツール
- **Mythril**: セキュリティ分析ツール
- **Echidna**: ファズテストツール
- **Manticore**: シンボリック実行
- **Securify**: 自動セキュリティスキャナー

## 一般的な落とし穴

1. **認証に`tx.origin`を使用**: 代わりに`msg.sender`を使用
2. **チェックされていない外部呼び出し**: 常に戻り値をチェック
3. **信頼されていないコントラクトへのDelegatecall**: コントラクトを乗っ取られる可能性
4. **浮動Pragma**: 特定のSolidityバージョンに固定
5. **イベントの欠如**: 状態変更のためにイベントを発行
6. **ループ内の過剰なガス**: ブロックガスリミットに達する可能性
7. **アップグレードパスなし**: 必要であればプロキシパターンを検討
