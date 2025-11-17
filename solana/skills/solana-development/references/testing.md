# Solana Program Testing Guide

**Comprehensive guide for testing Solana programs using Mollusk, LiteSVM, and Anchor test frameworks**

---

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Mollusk Testing (Works with Both Frameworks)](#mollusk-testing)
3. [Anchor-Specific Testing](#anchor-specific-testing)
4. [Native Rust Testing](#native-rust-testing)
5. [Testing Best Practices](#testing-best-practices)
6. [Common Testing Patterns](#common-testing-patterns)

---

## Testing Overview

### Why Testing Matters for Solana Programs

Solana programs are immutable after deployment and handle real financial assets. Comprehensive testing is critical to:

- **Prevent loss of funds**: Bugs in deployed programs can lead to irreversible financial losses
- **Ensure correctness**: Verify program logic works as intended under all conditions
- **Optimize performance**: Monitor compute unit usage to stay within Solana's limits (1.4M CU cap)
- **Build confidence**: Thorough testing enables safer deployments and upgrades
- **Catch edge cases**: Test boundary conditions, error handling, and attack vectors

### Types of Tests

**Unit Tests**
- Test individual functions and instruction handlers in isolation
- Fast, focused validation of specific logic
- Run frequently during development

**Integration Tests**
- Test complete instruction flows with realistic account setups
- Validate cross-program invocations (CPIs)
- Ensure proper state transitions

**Fuzz Tests**
- Generate random inputs to find edge cases and vulnerabilities
- Discover unexpected failure modes
- Test input validation thoroughly

**Compute Unit Benchmarks**
- Monitor compute unit consumption for each instruction
- Track performance regressions
- Ensure programs stay within CU limits

### Testing Frameworks Available

**Mollusk** (Recommended for both Anchor and Native Rust)
- Lightweight SVM test harness
- Exceptionally fast (no validator overhead)
- Works with both Anchor and native Rust programs
- Direct program execution via BPF loader
- Requires explicit account setup (no AccountsDB)

**LiteSVM** (Alternative for integration tests)
- In-process Solana VM for testing
- Available in Rust, TypeScript, and Python
- Faster than solana-program-test
- Supports RPC-like interactions
- Good for complex integration scenarios

**Anchor Test** (Anchor framework)
- TypeScript-based testing using @coral-xyz/anchor
- Integrates with local validator or LiteSVM
- Natural for testing Anchor programs from client perspective
- Slower but more realistic end-to-end tests

**solana-program-test** (Legacy)
- Full validator simulation
- More realistic but much slower
- Generally replaced by Mollusk and LiteSVM

**Recommendation**: Use Mollusk for fast unit and integration tests. Use LiteSVM or Anchor tests for end-to-end validation when needed.

---

## Mollusk Testing

### What is Mollusk?

Mollusk is a lightweight test harness that provides a minified Solana Virtual Machine (SVM) environment for program testing. It creates a program execution pipeline directly from low-level SVM components without the overhead of a full validator.

**Key characteristics:**
- No validator runtime (no AccountsDB, Bank, or other large components)
- Exceptionally fast test execution
- Direct program ELF execution via BPF Loader
- Requires explicit account lists (can't load from storage)
- Configurable compute budget, feature set, and sysvars

### Setup and Dependencies

Add Mollusk to your `Cargo.toml` dev dependencies:

```toml
[dev-dependencies]
mollusk-svm = "0.9"
solana-sdk = "2.1"
```

For testing with Token program:
```toml
[dev-dependencies]
mollusk-svm-programs-token = "0.9"
spl-token = "6.0"
```

For compute unit benchmarking:
```toml
[dev-dependencies]
mollusk-svm-bencher = "0.9"
```

### Basic Test Structure

```rust
use {
    mollusk_svm::Mollusk,
    solana_sdk::{
        account::Account,
        instruction::{AccountMeta, Instruction},
        pubkey::Pubkey,
    },
};

#[test]
fn test_my_instruction() {
    // 1. Initialize Mollusk with your program
    let program_id = Pubkey::new_unique();
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    // 2. Setup accounts
    let user = Pubkey::new_unique();
    let accounts = vec![
        (user, Account {
            lamports: 1_000_000,
            data: vec![],
            owner: program_id,
            executable: false,
            rent_epoch: 0,
        }),
    ];

    // 3. Create instruction
    let instruction = Instruction::new_with_bytes(
        program_id,
        &[0, 1, 2, 3],  // instruction data
        vec![AccountMeta::new(user, true)],
    );

    // 4. Process instruction
    let result = mollusk.process_instruction(&instruction, &accounts);

    // 5. Assert success
    assert!(result.is_ok());
}
```

### Four Main API Methods

Mollusk provides four core testing methods:

**1. `process_instruction`** - Execute single instruction, return result
```rust
let result = mollusk.process_instruction(&instruction, &accounts);
```

**2. `process_and_validate_instruction`** - Execute and validate with checks
```rust
mollusk.process_and_validate_instruction(
    &instruction,
    &accounts,
    &checks,
);
```

**3. `process_instruction_chain`** - Execute multiple instructions sequentially
```rust
let result = mollusk.process_instruction_chain(
    &[instruction1, instruction2, instruction3],
    &accounts,
);
```

**4. `process_and_validate_instruction_chain`** - Execute chain with per-instruction checks
```rust
mollusk.process_and_validate_instruction_chain(
    &[
        (&instruction1, &[Check::success()]),
        (&instruction2, &[Check::success()]),
    ],
    &accounts,
);
```

### Creating Test Accounts

Test accounts must be created explicitly with all required fields:

```rust
use solana_sdk::account::Account;

// Basic account
let account = Account {
    lamports: 1_000_000,           // Account balance
    data: vec![0; 100],             // Account data
    owner: program_id,              // Owner program
    executable: false,              // Not executable
    rent_epoch: 0,                  // Rent epoch
};

// System account
let system_account = Account {
    lamports: 1_000_000,
    data: vec![],
    owner: system_program::id(),
    executable: false,
    rent_epoch: 0,
};

// Rent-exempt account
let rent = mollusk.sysvars.rent;
let rent_exempt_account = Account {
    lamports: rent.minimum_balance(data_len),
    data: vec![0; data_len],
    owner: program_id,
    executable: false,
    rent_epoch: 0,
};
```

### Processing Instructions

**Simple execution:**
```rust
let result = mollusk.process_instruction(&instruction, &accounts);
assert!(result.is_ok());
```

**With result inspection:**
```rust
let result = mollusk.process_instruction(&instruction, &accounts);
match result {
    Ok(result) => {
        println!("Compute units: {}", result.compute_units_consumed);
        // Access modified accounts from result
    }
    Err(err) => panic!("Instruction failed: {:?}", err),
}
```

### Validation with Check API

The `Check` enum provides common validation patterns:

**Success checks:**
```rust
use mollusk_svm::result::Check;

let checks = vec![
    Check::success(),                          // Instruction succeeded
    Check::compute_units(5000),                // Exact compute units
];
```

**Account state checks:**
```rust
let checks = vec![
    Check::account(&pubkey)
        .lamports(1_000_000)                   // Check lamports
        .data(&[1, 2, 3, 4])                   // Check full data
        .data_slice(8, &[1, 2, 3, 4])          // Check data slice at offset
        .owner(&program_id)                     // Check owner
        .executable(false)                      // Check executable flag
        .space(100)                             // Check data length
        .rent_exempt()                          // Check rent exempt
        .build(),
];
```

**Error checks:**
```rust
use solana_sdk::instruction::InstructionError;

let checks = vec![
    Check::instruction_err(InstructionError::InvalidInstructionData),
];
```

**Complete validation example:**
```rust
use {
    mollusk_svm::{Mollusk, result::Check},
    solana_sdk::{
        account::Account,
        instruction::Instruction,
        pubkey::Pubkey,
        system_instruction,
        system_program,
    },
};

#[test]
fn test_system_transfer() {
    let sender = Pubkey::new_unique();
    let recipient = Pubkey::new_unique();

    let base_lamports = 100_000_000;
    let transfer_amount = 42_000;

    let instruction = system_instruction::transfer(&sender, &recipient, transfer_amount);
    let accounts = [
        (
            sender,
            Account::new(base_lamports, 0, &system_program::id()),
        ),
        (
            recipient,
            Account::new(base_lamports, 0, &system_program::id()),
        ),
    ];

    let checks = vec![
        Check::success(),
        Check::account(&sender)
            .lamports(base_lamports - transfer_amount)
            .build(),
        Check::account(&recipient)
            .lamports(base_lamports + transfer_amount)
            .build(),
    ];

    Mollusk::default().process_and_validate_instruction(
        &instruction,
        &accounts,
        &checks,
    );
}
```

### Compute Unit Benchmarking

Monitor compute unit usage to catch performance regressions:

**Basic benchmark:**
```rust
use mollusk_svm_bencher::MolluskComputeUnitBencher;

fn main() {
    let program_id = Pubkey::new_unique();
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    MolluskComputeUnitBencher::new(mollusk)
        .bench(("my_instruction", &instruction, &accounts))
        .must_pass(true)
        .out_dir("./target/benches")
        .execute();
}
```

**Benchmark multiple instructions:**
```rust
fn main() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");
    let bencher = MolluskComputeUnitBencher::new(mollusk);

    bencher.bench(("initialize", &init_ix, &init_accounts))
        .must_pass(true);

    bencher.bench(("update", &update_ix, &update_accounts))
        .must_pass(true);

    bencher.bench(("close", &close_ix, &close_accounts))
        .must_pass(true)
        .out_dir("./target/benches")
        .execute();
}
```

Run benchmarks with:
```bash
cargo bench
```

Output includes:
- Current compute units consumed
- Previous benchmark value
- Delta (increase/decrease)
- Pass/fail status

### Advanced Patterns

#### Stateful Context Testing

Use `MolluskContext` to persist account state across multiple instructions:

```rust
use std::collections::HashMap;

#[test]
fn test_sequential_transfers() {
    let mollusk = Mollusk::default();

    // Create initial account store
    let mut account_store = HashMap::new();
    let alice = Pubkey::new_unique();
    let bob = Pubkey::new_unique();

    account_store.insert(
        alice,
        Account {
            lamports: 1_000_000,
            data: vec![],
            owner: system_program::id(),
            executable: false,
            rent_epoch: 0,
        },
    );

    account_store.insert(
        bob,
        Account {
            lamports: 0,
            data: vec![],
            owner: system_program::id(),
            executable: false,
            rent_epoch: 0,
        },
    );

    // Create stateful context
    let context = mollusk.with_context(account_store);

    // First transfer - state persists automatically
    let instruction1 = system_instruction::transfer(&alice, &bob, 200_000);
    context.process_instruction(&instruction1);

    // Second transfer - uses updated state from first transfer
    let instruction2 = system_instruction::transfer(&alice, &bob, 100_000);
    context.process_instruction(&instruction2);

    // Access final account state
    let store = context.account_store.borrow();
    assert_eq!(store.get(&alice).unwrap().lamports, 700_000);
    assert_eq!(store.get(&bob).unwrap().lamports, 300_000);
}
```

#### Instruction Chains with Validation

Process multiple instructions and validate state after each:

```rust
#[test]
fn test_instruction_chain_with_checks() {
    let mollusk = Mollusk::default();

    let alice = Pubkey::new_unique();
    let bob = Pubkey::new_unique();
    let carol = Pubkey::new_unique();

    let starting_lamports = 1_000_000;

    mollusk.process_and_validate_instruction_chain(
        &[
            (
                &system_instruction::transfer(&alice, &bob, 300_000),
                &[
                    Check::success(),
                    Check::account(&alice).lamports(700_000).build(),
                    Check::account(&bob).lamports(300_000).build(),
                ],
            ),
            (
                &system_instruction::transfer(&bob, &carol, 100_000),
                &[
                    Check::success(),
                    Check::account(&bob).lamports(200_000).build(),
                    Check::account(&carol).lamports(100_000).build(),
                ],
            ),
        ],
        &[
            (alice, system_account(starting_lamports)),
            (bob, system_account(0)),
            (carol, system_account(0)),
        ],
    );
}
```

**Important:** Instruction chains are NOT equivalent to Solana transactions. Mollusk doesn't impose transaction constraints like loaded account keys or size limits. Chains are primarily for testing program execution flows.

#### Time-Dependent Testing with warp_to_slot

Test logic that depends on clock or slot:

```rust
use solana_sdk::clock::Clock;

#[test]
fn test_time_dependent_logic() {
    let mut mollusk = Mollusk::default();

    // Warp to a specific slot
    mollusk.warp_to_slot(1000);

    // Test logic that depends on clock.slot
    let result1 = mollusk.process_instruction(&time_check_ix, &accounts);
    assert!(result1.is_ok());

    // Warp forward in time
    mollusk.warp_to_slot(2000);

    // Test again with new slot
    let result2 = mollusk.process_instruction(&time_check_ix, &accounts);
    assert!(result2.is_ok());
}
```

#### Custom Sysvar Configuration

Modify sysvars to test specific conditions:

```rust
use solana_sdk::rent::Rent;

#[test]
fn test_with_custom_rent() {
    let mut mollusk = Mollusk::default();

    // Customize rent parameters
    mollusk.sysvars.rent = Rent {
        lamports_per_byte_year: 1,
        exemption_threshold: 1.0,
        burn_percent: 0,
    };

    // Test with custom rent configuration
    let result = mollusk.process_instruction(&instruction, &accounts);
    assert!(result.is_ok());
}
```

#### Testing with Built-in Programs

**Default builtins:**
```rust
// Mollusk::default() includes subset of builtin programs
let mollusk = Mollusk::default();  // Includes System, BPF Loader, etc.
```

**All builtins:**
```toml
[dev-dependencies]
mollusk-svm = { version = "0.9", features = ["all-builtins"] }
```

**Adding specific programs:**
```rust
use mollusk_svm_programs_token::token;

let mut mollusk = Mollusk::default();
token::add_program(&mut mollusk);  // Add Token program
```

---

## Anchor-Specific Testing

### anchor test Command and Workflow

Anchor provides integrated testing via the `anchor test` command:

```bash
# Run all tests
anchor test

# Run tests without rebuilding
anchor test --skip-build

# Run tests without deploying (use existing deployment)
anchor test --skip-deploy

# Run specific test file
anchor test -- --test test_initialize

# Show program logs
anchor test -- --nocapture
```

**Standard workflow:**
1. `anchor build` - Build program
2. `anchor test` - Deploy to local validator and run TypeScript tests
3. Test files run against deployed program
4. Validator shuts down after tests complete

### TypeScript Tests with @coral-xyz/anchor

**Basic test structure:**

```typescript
import * as anchor from "@coral-xyz/anchor";
import { Program } from "@coral-xyz/anchor";
import { MyProgram } from "../target/types/my_program";
import { expect } from "chai";

describe("my-program", () => {
  // Configure the client to use the local cluster
  anchor.setProvider(anchor.AnchorProvider.env());

  const program = anchor.workspace.MyProgram as Program<MyProgram>;

  it("Initializes the program", async () => {
    // Test implementation
  });
});
```

### Setting Up Test Environment

```typescript
describe("my-program", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const program = anchor.workspace.MyProgram as Program<MyProgram>;
  const wallet = provider.wallet as anchor.Wallet;

  // Generate keypairs
  const user = anchor.web3.Keypair.generate();
  const account = anchor.web3.Keypair.generate();

  before(async () => {
    // Airdrop SOL for testing
    const airdropSig = await provider.connection.requestAirdrop(
      user.publicKey,
      2 * anchor.web3.LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropSig);
  });

  it("runs test", async () => {
    // Test code
  });
});
```

### Invoking Instructions

```typescript
it("initializes account", async () => {
  const [pda, bump] = anchor.web3.PublicKey.findProgramAddressSync(
    [Buffer.from("seed"), user.publicKey.toBuffer()],
    program.programId
  );

  const tx = await program.methods
    .initialize(bump)
    .accounts({
      user: user.publicKey,
      account: pda,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .signers([user])
    .rpc();

  console.log("Transaction signature:", tx);
});
```

**With custom transaction options:**
```typescript
const tx = await program.methods
  .initialize(bump)
  .accounts({ /* ... */ })
  .signers([user])
  .rpc({
    skipPreflight: false,
    commitment: "confirmed",
  });
```

### Reading Account State

```typescript
it("reads account data", async () => {
  // Fetch account data
  const accountData = await program.account.myAccount.fetch(accountPubkey);

  // Assert values
  expect(accountData.value).to.equal(42);
  expect(accountData.owner.toString()).to.equal(user.publicKey.toString());
});

// Fetch multiple accounts
const accounts = await program.account.myAccount.all();
console.log("Found accounts:", accounts.length);

// Fetch with filters
const filtered = await program.account.myAccount.all([
  {
    memcmp: {
      offset: 8,  // Skip discriminator
      bytes: user.publicKey.toBase58(),
    },
  },
]);
```

### Event Listeners

```typescript
it("listens for events", async () => {
  let eventReceived = false;

  // Set up event listener
  const listener = program.addEventListener(
    "MyEvent",
    (event, slot) => {
      console.log("Event received in slot:", slot);
      console.log("Event data:", event);
      eventReceived = true;
    }
  );

  // Trigger event
  await program.methods
    .triggerEvent()
    .accounts({ /* ... */ })
    .rpc();

  // Wait for event
  await new Promise((resolve) => setTimeout(resolve, 1000));

  expect(eventReceived).to.be.true;

  // Clean up listener
  await program.removeEventListener(listener);
});
```

### LiteSVM for Fast Anchor Tests

LiteSVM provides a faster alternative to the full validator for Anchor tests:

**Installation:**
```bash
cargo add litesvm --dev
```

**Basic usage:**
```rust
use {
    litesvm::LiteSVM,
    solana_sdk::{
        message::Message,
        pubkey::Pubkey,
        signature::{Keypair, Signer},
        system_instruction::transfer,
        transaction::Transaction,
    },
};

#[test]
fn test_with_litesvm() {
    let from_keypair = Keypair::new();
    let from = from_keypair.pubkey();
    let to = Pubkey::new_unique();

    let mut svm = LiteSVM::new();
    svm.airdrop(&from, 10_000).unwrap();

    let instruction = transfer(&from, &to, 64);
    let tx = Transaction::new(
        &[&from_keypair],
        Message::new(&[instruction], Some(&from)),
        svm.latest_blockhash(),
    );
    let tx_res = svm.send_transaction(tx).unwrap();

    let from_account = svm.get_account(&from);
    let to_account = svm.get_account(&to);
    assert_eq!(from_account.unwrap().lamports, 4936);
    assert_eq!(to_account.unwrap().lamports, 64);
}
```

**Deploying programs:**
```rust
use solana_sdk::pubkey;

#[test]
fn test_program() {
    let program_id = pubkey!("Logging111111111111111111111111111111111111");
    let mut svm = LiteSVM::new();

    // Load program from file
    let bytes = include_bytes!("../target/deploy/my_program.so");
    svm.add_program(program_id, bytes);

    // Test program
    // ...
}
```

**Time travel with LiteSVM:**
```rust
use solana_sdk::clock::Clock;

#[test]
fn test_set_clock() {
    let mut svm = LiteSVM::new();

    // Get current clock
    let mut clock = svm.get_sysvar::<Clock>();

    // Set specific timestamp
    clock.unix_timestamp = 1735689600;  // January 1st 2025
    svm.set_sysvar::<Clock>(&clock);

    // Test time-dependent logic
    // ...

    // Warp to specific slot
    svm.warp_to_slot(1000);
}
```

**Writing arbitrary accounts:**
```rust
use {
    solana_sdk::account::Account,
    spl_token::state::Account as TokenAccount,
};

#[test]
fn test_with_token_account() {
    let mut svm = LiteSVM::new();

    let user = Pubkey::new_unique();
    let usdc_mint = pubkey!("EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v");

    // Create fake USDC balance
    let token_account_data = /* serialize TokenAccount with balance */;

    svm.set_account(
        user,
        Account {
            lamports: 1_000_000,
            data: token_account_data,
            owner: spl_token::id(),
            executable: false,
            rent_epoch: 0,
        },
    );

    // Test with USDC balance
    // ...
}
```

### Anchor.toml Test Configuration

Configure testing behavior in `Anchor.toml`:

```toml
[toolchain]
anchor_version = "0.30.1"

[features]
resolution = true
skip-lint = false

[programs.localnet]
my_program = "Fg6PaFpoGXkYsidMpWTK6W2BeZ7FEfcYkg476zPFsLnS"

[registry]
url = "https://api.apr.dev"

[provider]
cluster = "Localnet"
wallet = "~/.config/solana/id.json"

[scripts]
test = "yarn run ts-mocha -p ./tsconfig.json -t 1000000 tests/**/*.ts"

[test]
startup_wait = 5000  # Wait before running tests (ms)
shutdown_wait = 2000  # Wait before shutting down validator (ms)
upgradeable = false  # Deploy as upgradeable program

[test.validator]
url = "https://api.mainnet-beta.solana.com"  # Clone from mainnet
ledger = ".anchor/test-ledger"
bind_address = "0.0.0.0"

[[test.validator.clone]]
address = "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"  # Clone Metaplex

[[test.validator.clone]]
address = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"  # Clone Token program

[[test.validator.account]]
address = "..."  # Clone specific account
filename = "account.json"
```

### Anchor Testing Best Practices

1. **Use `anchor.workspace`**: Automatically loads program IDL
2. **Airdrop SOL in `before()` hooks**: Set up test accounts before tests
3. **Use proper commitment levels**: `confirmed` or `finalized` for reliability
4. **Test error conditions**: Use `.simulate()` to test expected failures
5. **Clean up between tests**: Reset account state or use fresh keypairs
6. **Use `--skip-build` during iteration**: Speed up test runs
7. **Test with realistic data**: Don't just test happy paths

---

## Native Rust Testing

### Cargo Test Setup

Native Rust programs use standard Rust testing with Mollusk:

**Project structure:**
```
my-program/
├── Cargo.toml
├── src/
│   ├── lib.rs
│   ├── processor.rs
│   └── instruction.rs
└── tests/
    ├── test_initialize.rs
    ├── test_update.rs
    └── test_close.rs
```

**Cargo.toml configuration:**
```toml
[package]
name = "my-program"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "lib"]

[dependencies]
solana-program = "2.1"

[dev-dependencies]
mollusk-svm = "0.9"
mollusk-svm-programs-token = "0.9"
solana-sdk = "2.1"

[[bench]]
name = "compute_units"
harness = false

[profile.release]
overflow-checks = true
lto = "fat"
codegen-units = 1

[profile.release.build-override]
opt-level = 3
incremental = false
codegen-units = 1
```

### Mollusk with Native Programs

**Basic test example:**

```rust
// tests/test_initialize.rs
use {
    mollusk_svm::Mollusk,
    my_program::{instruction::initialize, ID},
    solana_sdk::{
        account::Account,
        instruction::{AccountMeta, Instruction},
        pubkey::Pubkey,
    },
};

#[test]
fn test_initialize() {
    let program_id = ID;
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let user = Pubkey::new_unique();
    let account = Pubkey::new_unique();

    let instruction = Instruction {
        program_id,
        accounts: vec![
            AccountMeta::new(user, true),
            AccountMeta::new(account, false),
            AccountMeta::new_readonly(solana_sdk::system_program::id(), false),
        ],
        data: initialize().data,
    };

    let accounts = vec![
        (user, Account {
            lamports: 10_000_000,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            executable: false,
            rent_epoch: 0,
        }),
        (account, Account {
            lamports: 0,
            data: vec![],
            owner: solana_sdk::system_program::id(),
            executable: false,
            rent_epoch: 0,
        }),
    ];

    let result = mollusk.process_instruction(&instruction, &accounts);
    assert!(result.is_ok());
}
```

### Manual Account Setup

Native Rust tests require explicit account setup:

```rust
use solana_sdk::account::Account;

// Helper: Create system account
fn system_account(lamports: u64) -> Account {
    Account {
        lamports,
        data: vec![],
        owner: solana_sdk::system_program::id(),
        executable: false,
        rent_epoch: 0,
    }
}

// Helper: Create program-owned account
fn program_account(lamports: u64, data: Vec<u8>, owner: Pubkey) -> Account {
    Account {
        lamports,
        data,
        owner,
        executable: false,
        rent_epoch: 0,
    }
}

// Helper: Create rent-exempt account
fn rent_exempt_account(data_len: usize, owner: Pubkey, mollusk: &Mollusk) -> Account {
    let lamports = mollusk.sysvars.rent.minimum_balance(data_len);
    Account {
        lamports,
        data: vec![0; data_len],
        owner,
        executable: false,
        rent_epoch: 0,
    }
}

// Usage
#[test]
fn test_with_helpers() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let user = Pubkey::new_unique();
    let data_account = Pubkey::new_unique();

    let accounts = vec![
        (user, system_account(10_000_000)),
        (data_account, rent_exempt_account(100, program_id, &mollusk)),
    ];

    // Test
    // ...
}
```

### Testing CPIs

Use `mollusk-svm-programs-token` for testing cross-program invocations:

```rust
use {
    mollusk_svm::{result::Check, Mollusk},
    mollusk_svm_programs_token::token,
    solana_sdk::{
        account::Account,
        program_pack::Pack,
        pubkey::Pubkey,
    },
    spl_token::state::{Account as TokenAccount, AccountState, Mint},
};

#[test]
fn test_token_transfer_cpi() {
    // Initialize Mollusk with Token program
    let mut mollusk = Mollusk::default();
    token::add_program(&mut mollusk);

    // Setup mint
    let mint = Pubkey::new_unique();
    let decimals = 6;

    let mut mint_data = vec![0u8; Mint::LEN];
    Mint::pack(
        Mint {
            mint_authority: Some(authority).into(),
            supply: 1_000_000,
            decimals,
            is_initialized: true,
            freeze_authority: None.into(),
        },
        &mut mint_data,
    ).unwrap();

    // Setup source token account
    let source = Pubkey::new_unique();
    let mut source_data = vec![0u8; TokenAccount::LEN];
    TokenAccount::pack(
        TokenAccount {
            mint,
            owner: authority,
            amount: 1_000_000,
            delegate: None.into(),
            state: AccountState::Initialized,
            is_native: None.into(),
            delegated_amount: 0,
            close_authority: None.into(),
        },
        &mut source_data,
    ).unwrap();

    // Setup destination token account
    let destination = Pubkey::new_unique();
    let mut dest_data = vec![0u8; TokenAccount::LEN];
    TokenAccount::pack(
        TokenAccount {
            mint,
            owner: recipient,
            amount: 0,
            delegate: None.into(),
            state: AccountState::Initialized,
            is_native: None.into(),
            delegated_amount: 0,
            close_authority: None.into(),
        },
        &mut dest_data,
    ).unwrap();

    let mint_rent = mollusk.sysvars.rent.minimum_balance(Mint::LEN);
    let account_rent = mollusk.sysvars.rent.minimum_balance(TokenAccount::LEN);

    let accounts = vec![
        (source, Account {
            lamports: account_rent,
            data: source_data,
            owner: token::ID,
            executable: false,
            rent_epoch: 0,
        }),
        (mint, Account {
            lamports: mint_rent,
            data: mint_data,
            owner: token::ID,
            executable: false,
            rent_epoch: 0,
        }),
        (destination, Account {
            lamports: account_rent,
            data: dest_data,
            owner: token::ID,
            executable: false,
            rent_epoch: 0,
        }),
    ];

    // Create transfer instruction
    use spl_token::instruction::transfer_checked;

    let instruction = transfer_checked(
        &token::ID,
        &source,
        &mint,
        &destination,
        &authority,
        &[],
        500_000,
        decimals,
    ).unwrap();

    // Validate transfer
    let checks = vec![
        Check::success(),
        Check::account(&source)
            .data_slice(64, &(500_000u64).to_le_bytes())
            .build(),
        Check::account(&destination)
            .data_slice(64, &(500_000u64).to_le_bytes())
            .build(),
    ];

    mollusk.process_and_validate_instruction(&instruction, &accounts, &checks);
}
```

### Validation Patterns

**Account state validation:**
```rust
use mollusk_svm::result::Check;

let checks = vec![
    Check::success(),
    Check::account(&account_pubkey)
        .lamports(expected_lamports)
        .data(&expected_data)
        .owner(&expected_owner)
        .build(),
];

mollusk.process_and_validate_instruction(&instruction, &accounts, &checks);
```

**Error validation:**
```rust
use solana_sdk::instruction::InstructionError;

let checks = vec![
    Check::instruction_err(InstructionError::InvalidAccountData),
];

mollusk.process_and_validate_instruction(&bad_instruction, &accounts, &checks);
```

**Compute unit validation:**
```rust
let checks = vec![
    Check::success(),
    Check::compute_units(5000),  // Exactly 5000 CU
];
```

**Data slice validation:**
```rust
// Check specific bytes without loading full account data
let checks = vec![
    Check::account(&account)
        .data_slice(8, &[1, 2, 3, 4])  // Check bytes 8-11
        .build(),
];
```

---

## Testing Best Practices

### Test Organization

**Organize by instruction:**
```
tests/
├── test_initialize.rs
├── test_update.rs
├── test_transfer.rs
├── test_close.rs
└── helpers/
    ├── mod.rs
    ├── accounts.rs
    └── instructions.rs
```

**Use helper modules:**
```rust
// tests/helpers/accounts.rs
use solana_sdk::{account::Account, pubkey::Pubkey};

pub fn system_account(lamports: u64) -> Account {
    Account {
        lamports,
        data: vec![],
        owner: solana_sdk::system_program::id(),
        executable: false,
        rent_epoch: 0,
    }
}

pub fn token_account(/* ... */) -> Account {
    // ...
}
```

```rust
// tests/test_initialize.rs
mod helpers;
use helpers::accounts::*;

#[test]
fn test_initialize() {
    let accounts = vec![
        (user, system_account(10_000_000)),
        // ...
    ];
}
```

### Edge Cases to Test

**Account validation:**
- Missing accounts
- Wrong account owner
- Account not writable when required
- Account not signer when required
- Uninitialized accounts
- Already initialized accounts

**Numeric boundaries:**
- Zero values
- Maximum values (u64::MAX)
- Overflow conditions
- Underflow conditions
- Negative results (when using signed integers)

**Authorization:**
- Missing signer
- Wrong signer
- Multiple signers
- PDA signer validation

**State transitions:**
- Invalid state transitions
- Idempotent operations
- Concurrent operations
- State rollback on error

**Resource limits:**
- Rent exemption
- Maximum account size
- Compute unit limits
- Stack depth limits (CPI)

### Error Condition Testing

**Test expected failures:**
```rust
#[test]
fn test_insufficient_funds_fails() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let user = Pubkey::new_unique();
    let accounts = vec![
        (user, system_account(100)),  // Not enough lamports
    ];

    let instruction = /* create transfer instruction for 1000 lamports */;

    let checks = vec![
        Check::instruction_err(InstructionError::InsufficientFunds),
    ];

    mollusk.process_and_validate_instruction(&instruction, &accounts, &checks);
}
```

**Test invalid data:**
```rust
#[test]
fn test_invalid_instruction_data() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let instruction = Instruction {
        program_id,
        accounts: /* ... */,
        data: vec![255, 255, 255],  // Invalid instruction data
    };

    let checks = vec![
        Check::instruction_err(InstructionError::InvalidInstructionData),
    ];

    mollusk.process_and_validate_instruction(&instruction, &accounts, &checks);
}
```

### Compute Unit Monitoring

**Set up continuous monitoring:**
```rust
// benches/compute_units.rs
use mollusk_svm_bencher::MolluskComputeUnitBencher;

fn main() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");
    let bencher = MolluskComputeUnitBencher::new(mollusk);

    // Benchmark each instruction
    bencher.bench(("initialize", &init_ix, &init_accounts));
    bencher.bench(("update", &update_ix, &update_accounts));
    bencher.bench(("close", &close_ix, &close_accounts));

    bencher
        .must_pass(true)
        .out_dir("./target/benches")
        .execute();
}
```

**Add to CI/CD:**
```yaml
# .github/workflows/test.yml
- name: Run compute unit benchmarks
  run: cargo bench

- name: Check for CU regressions
  run: |
    if git diff --exit-code target/benches/; then
      echo "No compute unit changes"
    else
      echo "Compute unit usage changed - review carefully"
      git diff target/benches/
    fi
```

### Running Tests Efficiently

**Build before testing:**
```bash
# Native Rust
cargo build-sbf && cargo test

# Anchor
anchor build && anchor test
```

**Run specific tests:**
```bash
# Native Rust
cargo test test_initialize

# Anchor
anchor test -- --test test_initialize
```

**Show program output:**
```bash
# Native Rust
cargo test -- --nocapture

# Anchor
anchor test -- --nocapture
```

**Run tests in parallel (be careful with shared state):**
```bash
cargo test -- --test-threads=4
```

---

## Common Testing Patterns

### Testing PDAs

**Anchor approach:**
```typescript
it("derives PDA correctly", async () => {
  const [pda, bump] = anchor.web3.PublicKey.findProgramAddressSync(
    [Buffer.from("seed"), user.publicKey.toBuffer()],
    program.programId
  );

  await program.methods
    .initialize(bump)
    .accounts({
      pda: pda,
      user: user.publicKey,
      systemProgram: anchor.web3.SystemProgram.programId,
    })
    .signers([user])
    .rpc();

  const accountData = await program.account.myAccount.fetch(pda);
  expect(accountData.bump).to.equal(bump);
});
```

**Native Rust approach:**
```rust
#[test]
fn test_pda_derivation() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let user = Pubkey::new_unique();
    let seeds = &[b"seed", user.as_ref()];
    let (pda, bump) = Pubkey::find_program_address(seeds, &program_id);

    let instruction = Instruction {
        program_id,
        accounts: vec![
            AccountMeta::new(user, true),
            AccountMeta::new(pda, false),
            AccountMeta::new_readonly(system_program::id(), false),
        ],
        data: vec![0, bump],  // Initialize instruction with bump
    };

    let accounts = vec![
        (user, system_account(10_000_000)),
        (pda, Account::default()),
    ];

    let checks = vec![
        Check::success(),
        Check::account(&pda)
            .owner(&program_id)
            .build(),
    ];

    mollusk.process_and_validate_instruction(&instruction, &accounts, &checks);
}
```

### Testing Token Operations

**Anchor with SPL Token:**
```typescript
import { TOKEN_PROGRAM_ID, createMint, createAccount, mintTo } from "@solana/spl-token";

it("transfers tokens", async () => {
  // Create mint
  const mint = await createMint(
    provider.connection,
    wallet.payer,
    wallet.publicKey,
    null,
    6
  );

  // Create token accounts
  const sourceAccount = await createAccount(
    provider.connection,
    wallet.payer,
    mint,
    user.publicKey
  );

  const destAccount = await createAccount(
    provider.connection,
    wallet.payer,
    mint,
    recipient.publicKey
  );

  // Mint tokens
  await mintTo(
    provider.connection,
    wallet.payer,
    mint,
    sourceAccount,
    wallet.publicKey,
    1_000_000
  );

  // Transfer via program
  await program.methods
    .transferTokens(new anchor.BN(500_000))
    .accounts({
      source: sourceAccount,
      destination: destAccount,
      authority: user.publicKey,
      tokenProgram: TOKEN_PROGRAM_ID,
    })
    .signers([user])
    .rpc();

  // Verify balances
  const sourceData = await getAccount(provider.connection, sourceAccount);
  const destData = await getAccount(provider.connection, destAccount);

  expect(sourceData.amount).to.equal(500_000n);
  expect(destData.amount).to.equal(500_000n);
});
```

**Native Rust with Mollusk:**
See the [Testing CPIs](#testing-cpis) section for a complete token transfer example.

### Testing Associated Token Accounts

**Create ATA:**
```typescript
import { getAssociatedTokenAddress } from "@solana/spl-token";

it("creates associated token account", async () => {
  const ata = await getAssociatedTokenAddress(
    mint,
    user.publicKey
  );

  await program.methods
    .createAta()
    .accounts({
      ata: ata,
      mint: mint,
      owner: user.publicKey,
      payer: wallet.publicKey,
      tokenProgram: TOKEN_PROGRAM_ID,
      associatedTokenProgram: ASSOCIATED_TOKEN_PROGRAM_ID,
      systemProgram: SystemProgram.programId,
    })
    .rpc();

  const account = await getAccount(provider.connection, ata);
  expect(account.owner.toString()).to.equal(user.publicKey.toString());
  expect(account.mint.toString()).to.equal(mint.toString());
});
```

### Testing Account Validation

**Validate account owner:**
```rust
#[test]
fn test_wrong_owner_fails() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let account = Pubkey::new_unique();
    let wrong_owner = Pubkey::new_unique();

    let accounts = vec![
        (account, Account {
            lamports: 1_000_000,
            data: vec![0; 100],
            owner: wrong_owner,  // Wrong owner!
            executable: false,
            rent_epoch: 0,
        }),
    ];

    let instruction = /* create instruction */;

    let checks = vec![
        Check::instruction_err(InstructionError::InvalidAccountOwner),
    ];

    mollusk.process_and_validate_instruction(&instruction, &accounts, &checks);
}
```

**Validate signer:**
```rust
#[test]
fn test_missing_signer_fails() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let user = Pubkey::new_unique();

    let instruction = Instruction {
        program_id,
        accounts: vec![
            AccountMeta::new(user, false),  // Should be signer!
        ],
        data: vec![],
    };

    let accounts = vec![
        (user, system_account(1_000_000)),
    ];

    let checks = vec![
        Check::instruction_err(InstructionError::MissingRequiredSignature),
    ];

    mollusk.process_and_validate_instruction(&instruction, &accounts, &checks);
}
```

### Testing Rent Exemption

```rust
#[test]
fn test_account_is_rent_exempt() {
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let account = Pubkey::new_unique();
    let data_len = 100;
    let rent = mollusk.sysvars.rent;
    let rent_exempt_lamports = rent.minimum_balance(data_len);

    let accounts = vec![
        (account, Account {
            lamports: rent_exempt_lamports,
            data: vec![0; data_len],
            owner: program_id,
            executable: false,
            rent_epoch: 0,
        }),
    ];

    let instruction = /* create instruction */;

    let checks = vec![
        Check::success(),
        Check::account(&account)
            .rent_exempt()
            .build(),
    ];

    mollusk.process_and_validate_instruction(&instruction, &accounts, &checks);
}
```

---

## Additional Resources

### Documentation

- **Mollusk GitHub**: https://github.com/anza-xyz/mollusk
- **Mollusk Examples**: https://github.com/anza-xyz/mollusk/tree/main/harness/tests
- **Mollusk API Docs**: https://docs.rs/mollusk-svm/latest/mollusk_svm/
- **Anchor Testing Guide**: https://www.anchor-lang.com/docs/testing
- **LiteSVM**: https://github.com/amilz/litesvm
- **Solana Testing Docs**: https://solana.com/docs/programs/testing

### Key Takeaways

1. **Use Mollusk for fast, focused tests** - It's the recommended approach for both Anchor and native Rust programs
2. **Test early and often** - Catching bugs before deployment saves time and money
3. **Test error conditions** - Don't just test happy paths
4. **Monitor compute units** - Use benchmarking to catch performance regressions
5. **Organize tests logically** - Group by instruction, use helper modules
6. **Build before testing** - Always run `cargo build-sbf` or `anchor build` before tests
7. **Use validation checks** - Leverage the `Check` API for comprehensive validation
8. **Test with realistic data** - Use proper rent-exempt balances and realistic account states

### Quick Reference Commands

```bash
# Native Rust
cargo build-sbf                    # Build program
cargo test                         # Run tests
cargo test -- --nocapture         # Run tests with output
cargo test test_name              # Run specific test
cargo bench                       # Run compute unit benchmarks

# Anchor
anchor build                      # Build program
anchor test                       # Build, deploy, and test
anchor test --skip-build          # Test without rebuilding
anchor test -- --nocapture        # Test with logs
anchor test -- --test test_name   # Run specific test
```

---
