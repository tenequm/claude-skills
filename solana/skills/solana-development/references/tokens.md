# SPL Token Program - Comprehensive Reference

This reference provides complete coverage of SPL Token Program integration in Solana programs, showing both **Anchor** and **Native Rust** approaches side-by-side for all key operations.

## Table of Contents

1. [Token Program Overview](#token-program-overview)
2. [Token Account Structures](#token-account-structures)
3. [Associated Token Accounts](#associated-token-accounts)
4. [Creating Tokens](#creating-tokens)
5. [Minting Tokens](#minting-tokens)
6. [Transferring Tokens](#transferring-tokens)
7. [Burning Tokens](#burning-tokens)
8. [Closing Token Accounts](#closing-token-accounts)
9. [Token Account Validation](#token-account-validation)
10. [Token-2022 Extensions](#token-2022-extensions)
11. [Common Token Patterns](#common-token-patterns)
12. [Security Considerations](#security-considerations)

---

## Token Program Overview

### SPL Token vs Token-2022

**SPL Token (Original):**
- Program ID: `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`
- Production-ready, stable, widely adopted
- No new features planned
- Use for standard fungible tokens

**Token-2022 (Token Extensions Program):**
- Program ID: `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`
- Backwards-compatible with SPL Token
- Supports extensions (transfer fees, confidential transfers, metadata pointers, etc.)
- Use for advanced token features

### Key Concepts

```
┌─────────────────────────────────────────┐
│ Mint Account                             │
├─────────────────────────────────────────┤
│ - Defines a token type                  │
│ - Controls supply                       │
│ - Has mint authority (can create tokens)│
│ - Has freeze authority (can freeze accts)│
└─────────────────────────────────────────┘
           │
           │ Creates
           ▼
┌─────────────────────────────────────────┐
│ Token Account                            │
├─────────────────────────────────────────┤
│ - Holds token balance                   │
│ - Owned by a wallet or program          │
│ - Associated with specific Mint         │
│ - Can be frozen/delegated               │
└─────────────────────────────────────────┘
```

### Required Dependencies

**For Anchor:**
```toml
[dependencies]
anchor-lang = "0.32.1"
anchor-spl = "0.32.1"

[features]
idl-build = [
    "anchor-lang/idl-build",
    "anchor-spl/idl-build",
]
```

**For Native Rust:**
```toml
[dependencies]
spl-token = "6.0"
spl-associated-token-account = "6.0"
solana-program = "2.1"
```

---

## Token Account Structures

### Mint Account

**Size:** 82 bytes

```rust
pub struct Mint {
    /// Optional authority to mint new tokens (Pubkey or None)
    pub mint_authority: COption<Pubkey>,       // 36 bytes

    /// Total supply of tokens
    pub supply: u64,                           // 8 bytes

    /// Number of decimals (0 for NFTs, typically 6-9 for fungible)
    pub decimals: u8,                          // 1 byte

    /// Is initialized?
    pub is_initialized: bool,                  // 1 byte

    /// Optional authority to freeze token accounts
    pub freeze_authority: COption<Pubkey>,     // 36 bytes
}
```

**COption Format:**
```rust
pub enum COption<T> {
    None,      // Represented as [0, 0, 0, 0, ...]
    Some(T),   // Represented as [1, followed by T bytes]
}
```

### Token Account

**Size:** 165 bytes

```rust
pub struct Account {
    /// The mint associated with this account
    pub mint: Pubkey,                    // 32 bytes

    /// The owner of this account
    pub owner: Pubkey,                   // 32 bytes

    /// The amount of tokens this account holds
    pub amount: u64,                     // 8 bytes

    /// If `delegate` is `Some` then `delegated_amount` represents
    /// the amount authorized by the delegate
    pub delegate: COption<Pubkey>,       // 36 bytes

    /// The account's state
    pub state: AccountState,             // 1 byte

    /// If is_native.is_some, this is a native token, and the value logs the
    /// rent-exempt reserve
    pub is_native: COption<u64>,         // 12 bytes

    /// The amount delegated
    pub delegated_amount: u64,           // 8 bytes

    /// Optional authority to close the account
    pub close_authority: COption<Pubkey>, // 36 bytes
}

pub enum AccountState {
    Uninitialized,
    Initialized,
    Frozen,
}
```

---

## Associated Token Accounts

### What are ATAs?

**Associated Token Accounts (ATAs)** are PDAs that map a wallet address to a token account for a specific mint.

**Derivation:**
```rust
ATA = PDA(
    seeds: [wallet_address, TOKEN_PROGRAM_ID, mint_address],
    program: ASSOCIATED_TOKEN_PROGRAM_ID
)
```

**Benefits:**
- **Deterministic**: Same wallet + mint always produces same ATA
- **Discoverable**: Easy to find a user's token accounts
- **Standard**: All wallets use this convention

**Constants:**
```rust
// Token Program ID
pub const TOKEN_PROGRAM_ID: Pubkey = pubkey!("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA");

// Associated Token Program ID
pub const ASSOCIATED_TOKEN_PROGRAM_ID: Pubkey = pubkey!("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL");
```

### Finding ATA Address

#### Using Anchor

```rust
use anchor_spl::associated_token::get_associated_token_address;

// In client code or tests
let ata_address = get_associated_token_address(
    &wallet_address,
    &mint_address,
);
```

#### Using Native Rust

```rust
use spl_associated_token_account::get_associated_token_address;

// Derive ATA address
let ata_address = get_associated_token_address(
    &wallet_address,
    &mint_address,
);
```

### Creating Associated Token Accounts

#### Using Anchor

```rust
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token_interface::{Mint, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct CreateTokenAccount<'info> {
    #[account(
        init,
        payer = payer,
        associated_token::mint = mint,
        associated_token::authority = owner,
        associated_token::token_program = token_program,
    )]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    pub mint: InterfaceAccount<'info, Mint>,

    /// CHECK: Can be any account
    pub owner: UncheckedAccount<'info>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn create_ata(ctx: Context<CreateTokenAccount>) -> Result<()> {
    // ATA is automatically created by Anchor constraints
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_associated_token_account::instruction::create_associated_token_account;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke,
};

pub fn create_ata(
    payer: &AccountInfo,
    wallet: &AccountInfo,
    mint: &AccountInfo,
    ata: &AccountInfo,
    system_program: &AccountInfo,
    token_program: &AccountInfo,
    associated_token_program: &AccountInfo,
) -> ProgramResult {
    invoke(
        &create_associated_token_account(
            payer.key,
            wallet.key,
            mint.key,
            token_program.key,
        ),
        &[
            payer.clone(),
            ata.clone(),
            wallet.clone(),
            mint.clone(),
            system_program.clone(),
            token_program.clone(),
            associated_token_program.clone(),
        ],
    )?;

    Ok(())
}
```

---

## Creating Tokens

### Initialize a New Mint

#### Using Anchor

```rust
use anchor_spl::token_interface::{Mint, TokenInterface};

#[derive(Accounts)]
pub struct CreateMint<'info> {
    #[account(
        init,
        payer = payer,
        mint::decimals = 9,
        mint::authority = mint_authority,
        mint::freeze_authority = freeze_authority,
        mint::token_program = token_program,
    )]
    pub mint: InterfaceAccount<'info, Mint>,

    /// CHECK: Can be any account
    pub mint_authority: UncheckedAccount<'info>,

    /// CHECK: Can be any account (optional)
    pub freeze_authority: UncheckedAccount<'info>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
    pub system_program: Program<'info, System>,
}

pub fn create_mint(ctx: Context<CreateMint>) -> Result<()> {
    // Mint is automatically created and initialized by Anchor constraints
    msg!("Mint created: {}", ctx.accounts.mint.key());
    Ok(())
}
```

**Key Anchor Constraints:**
- `init` - Creates and initializes the account
- `mint::decimals` - Number of decimal places
- `mint::authority` - Who can mint tokens
- `mint::freeze_authority` - Who can freeze token accounts (optional)
- `mint::token_program` - Which token program to use

#### Using Native Rust

```rust
use spl_token::instruction::initialize_mint;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke,
    rent::Rent,
    system_instruction,
    sysvar::Sysvar,
};

pub fn create_mint(
    payer: &AccountInfo,
    mint_account: &AccountInfo,
    mint_authority: &Pubkey,
    freeze_authority: Option<&Pubkey>,
    decimals: u8,
    system_program: &AccountInfo,
    token_program: &AccountInfo,
    rent_sysvar: &AccountInfo,
) -> ProgramResult {
    // Mint account size
    let mint_size = 82;

    // Calculate rent
    let rent = Rent::get()?;
    let rent_lamports = rent.minimum_balance(mint_size);

    // Create mint account via System Program
    invoke(
        &system_instruction::create_account(
            payer.key,
            mint_account.key,
            rent_lamports,
            mint_size as u64,
            &spl_token::ID,
        ),
        &[payer.clone(), mint_account.clone(), system_program.clone()],
    )?;

    // Initialize mint
    invoke(
        &initialize_mint(
            token_program.key,
            mint_account.key,
            mint_authority,
            freeze_authority,
            decimals,
        )?,
        &[
            mint_account.clone(),
            rent_sysvar.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}
```

### Initialize a Token Account (Non-ATA)

#### Using Anchor

```rust
use anchor_spl::token_interface::{Mint, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct CreateTokenAccount<'info> {
    #[account(
        init,
        payer = payer,
        token::mint = mint,
        token::authority = owner,
        token::token_program = token_program,
    )]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    pub mint: InterfaceAccount<'info, Mint>,

    /// CHECK: Can be any account
    pub owner: UncheckedAccount<'info>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
    pub system_program: Program<'info, System>,
}

pub fn create_token_account(ctx: Context<CreateTokenAccount>) -> Result<()> {
    // Token account is automatically created and initialized
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::initialize_account3;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke,
    rent::Rent,
    system_instruction,
    sysvar::Sysvar,
};

pub fn create_token_account(
    payer: &AccountInfo,
    token_account: &AccountInfo,
    mint: &AccountInfo,
    owner: &Pubkey,
    system_program: &AccountInfo,
    token_program: &AccountInfo,
) -> ProgramResult {
    // Token account size
    let token_account_size = 165;

    // Calculate rent
    let rent = Rent::get()?;
    let rent_lamports = rent.minimum_balance(token_account_size);

    // Create token account
    invoke(
        &system_instruction::create_account(
            payer.key,
            token_account.key,
            rent_lamports,
            token_account_size as u64,
            &spl_token::ID,
        ),
        &[payer.clone(), token_account.clone(), system_program.clone()],
    )?;

    // Initialize token account
    invoke(
        &initialize_account3(
            token_program.key,
            token_account.key,
            mint.key,
            owner,
        )?,
        &[token_account.clone(), mint.clone(), token_program.clone()],
    )?;

    Ok(())
}
```

---

## Minting Tokens

### Basic Minting (User Authority)

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, Mint, MintTo, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct MintTokens<'info> {
    #[account(mut)]
    pub mint: InterfaceAccount<'info, Mint>,

    #[account(mut)]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    pub mint_authority: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn mint_tokens(ctx: Context<MintTokens>, amount: u64) -> Result<()> {
    let cpi_accounts = MintTo {
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.token_account.to_account_info(),
        authority: ctx.accounts.mint_authority.to_account_info(),
    };

    let cpi_program = ctx.accounts.token_program.to_account_info();
    let cpi_context = CpiContext::new(cpi_program, cpi_accounts);

    token_interface::mint_to(cpi_context, amount)?;
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::mint_to;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke,
    program_error::ProgramError,
};

pub fn mint_tokens(
    mint: &AccountInfo,
    destination: &AccountInfo,
    mint_authority: &AccountInfo,
    amount: u64,
    token_program: &AccountInfo,
) -> ProgramResult {
    // Mint authority must be a signer
    if !mint_authority.is_signer {
        return Err(ProgramError::MissingRequiredSignature);
    }

    invoke(
        &mint_to(
            token_program.key,
            mint.key,
            destination.key,
            mint_authority.key,
            &[],  // No multisig signers
            amount,
        )?,
        &[
            mint.clone(),
            destination.clone(),
            mint_authority.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}
```

### Minting with PDA Authority

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, Mint, MintTo, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct MintWithPDA<'info> {
    #[account(
        mut,
        mint::authority = mint_authority,
    )]
    pub mint: InterfaceAccount<'info, Mint>,

    #[account(mut)]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(
        seeds = [b"mint-authority"],
        bump,
    )]
    /// CHECK: PDA signer
    pub mint_authority: UncheckedAccount<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn mint_with_pda(ctx: Context<MintWithPDA>, amount: u64) -> Result<()> {
    let seeds = &[
        b"mint-authority",
        &[ctx.bumps.mint_authority],
    ];
    let signer_seeds = &[&seeds[..]];

    let cpi_accounts = MintTo {
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.token_account.to_account_info(),
        authority: ctx.accounts.mint_authority.to_account_info(),
    };

    let cpi_context = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts
    ).with_signer(signer_seeds);

    token_interface::mint_to(cpi_context, amount)?;
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::mint_to;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke_signed,
    program_error::ProgramError,
    pubkey::Pubkey,
};

pub fn mint_tokens_from_pda(
    program_id: &Pubkey,
    mint: &AccountInfo,
    destination: &AccountInfo,
    mint_authority_pda: &AccountInfo,
    token_program: &AccountInfo,
    amount: u64,
    pda_seeds: &[&[u8]],
    bump: u8,
) -> ProgramResult {
    // Validate PDA
    let (expected_pda, _) = Pubkey::find_program_address(pda_seeds, program_id);
    if expected_pda != *mint_authority_pda.key {
        return Err(ProgramError::InvalidSeeds);
    }

    // Prepare signer seeds
    let mut full_seeds = pda_seeds.to_vec();
    full_seeds.push(&[bump]);
    let signer_seeds: &[&[&[u8]]] = &[&full_seeds];

    invoke_signed(
        &mint_to(
            token_program.key,
            mint.key,
            destination.key,
            mint_authority_pda.key,
            &[],
            amount,
        )?,
        &[
            mint.clone(),
            destination.clone(),
            mint_authority_pda.clone(),
            token_program.clone(),
        ],
        signer_seeds,
    )?;

    Ok(())
}
```

---

## Transferring Tokens

### Basic Transfer

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, TokenAccount, TokenInterface, Transfer};

#[derive(Accounts)]
pub struct TransferTokens<'info> {
    #[account(mut)]
    pub from: InterfaceAccount<'info, TokenAccount>,

    #[account(mut)]
    pub to: InterfaceAccount<'info, TokenAccount>,

    pub authority: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn transfer_tokens(ctx: Context<TransferTokens>, amount: u64) -> Result<()> {
    let cpi_accounts = Transfer {
        from: ctx.accounts.from.to_account_info(),
        to: ctx.accounts.to.to_account_info(),
        authority: ctx.accounts.authority.to_account_info(),
    };

    let cpi_context = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts
    );

    token_interface::transfer(cpi_context, amount)?;
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::transfer;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke,
    program_error::ProgramError,
};

pub fn transfer_tokens(
    source: &AccountInfo,
    destination: &AccountInfo,
    authority: &AccountInfo,
    amount: u64,
    token_program: &AccountInfo,
) -> ProgramResult {
    // Authority must be a signer
    if !authority.is_signer {
        return Err(ProgramError::MissingRequiredSignature);
    }

    invoke(
        &transfer(
            token_program.key,
            source.key,
            destination.key,
            authority.key,
            &[],  // No multisig signers
            amount,
        )?,
        &[
            source.clone(),
            destination.clone(),
            authority.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}
```

### Transfer with Checks (Recommended)

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, Mint, TokenAccount, TokenInterface, TransferChecked};

#[derive(Accounts)]
pub struct TransferTokensChecked<'info> {
    #[account(mut)]
    pub from: InterfaceAccount<'info, TokenAccount>,

    #[account(mut)]
    pub to: InterfaceAccount<'info, TokenAccount>,

    pub mint: InterfaceAccount<'info, Mint>,

    pub authority: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn transfer_tokens_checked(
    ctx: Context<TransferTokensChecked>,
    amount: u64
) -> Result<()> {
    token_interface::transfer_checked(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            TransferChecked {
                from: ctx.accounts.from.to_account_info(),
                mint: ctx.accounts.mint.to_account_info(),
                to: ctx.accounts.to.to_account_info(),
                authority: ctx.accounts.authority.to_account_info(),
            },
        ),
        amount,
        ctx.accounts.mint.decimals,
    )?;
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::transfer_checked;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke,
    program_error::ProgramError,
};

pub fn transfer_tokens_checked(
    source: &AccountInfo,
    mint: &AccountInfo,
    destination: &AccountInfo,
    authority: &AccountInfo,
    amount: u64,
    decimals: u8,
    token_program: &AccountInfo,
) -> ProgramResult {
    if !authority.is_signer {
        return Err(ProgramError::MissingRequiredSignature);
    }

    invoke(
        &transfer_checked(
            token_program.key,
            source.key,
            mint.key,
            destination.key,
            authority.key,
            &[],
            amount,
            decimals,
        )?,
        &[
            source.clone(),
            mint.clone(),
            destination.clone(),
            authority.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}
```

### Transfer with PDA Signer

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, TokenAccount, TokenInterface, Transfer};

#[derive(Accounts)]
pub struct TransferWithPDA<'info> {
    #[account(
        mut,
        token::authority = authority,
    )]
    pub from: InterfaceAccount<'info, TokenAccount>,

    #[account(mut)]
    pub to: InterfaceAccount<'info, TokenAccount>,

    #[account(
        seeds = [b"authority"],
        bump,
    )]
    /// CHECK: PDA signer
    pub authority: UncheckedAccount<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn transfer_with_pda(ctx: Context<TransferWithPDA>, amount: u64) -> Result<()> {
    let seeds = &[
        b"authority",
        &[ctx.bumps.authority],
    ];
    let signer_seeds = &[&seeds[..]];

    let cpi_accounts = Transfer {
        from: ctx.accounts.from.to_account_info(),
        to: ctx.accounts.to.to_account_info(),
        authority: ctx.accounts.authority.to_account_info(),
    };

    let cpi_context = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts
    ).with_signer(signer_seeds);

    token_interface::transfer(cpi_context, amount)?;
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::transfer;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke_signed,
    program_error::ProgramError,
    pubkey::Pubkey,
};

pub fn transfer_tokens_from_pda(
    program_id: &Pubkey,
    source: &AccountInfo,
    destination: &AccountInfo,
    authority_pda: &AccountInfo,
    token_program: &AccountInfo,
    amount: u64,
    pda_seeds: &[&[u8]],
    bump: u8,
) -> ProgramResult {
    let (expected_pda, _) = Pubkey::find_program_address(pda_seeds, program_id);
    if expected_pda != *authority_pda.key {
        return Err(ProgramError::InvalidSeeds);
    }

    let mut full_seeds = pda_seeds.to_vec();
    full_seeds.push(&[bump]);
    let signer_seeds: &[&[&[u8]]] = &[&full_seeds];

    invoke_signed(
        &transfer(
            token_program.key,
            source.key,
            destination.key,
            authority_pda.key,
            &[],
            amount,
        )?,
        &[
            source.clone(),
            destination.clone(),
            authority_pda.clone(),
            token_program.clone(),
        ],
        signer_seeds,
    )?;

    Ok(())
}
```

---

## Burning Tokens

### Basic Burn

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, Burn, Mint, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct BurnTokens<'info> {
    #[account(mut)]
    pub mint: InterfaceAccount<'info, Mint>,

    #[account(mut)]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    pub authority: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn burn_tokens(ctx: Context<BurnTokens>, amount: u64) -> Result<()> {
    let cpi_accounts = Burn {
        mint: ctx.accounts.mint.to_account_info(),
        from: ctx.accounts.token_account.to_account_info(),
        authority: ctx.accounts.authority.to_account_info(),
    };

    let cpi_context = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts
    );

    token_interface::burn(cpi_context, amount)?;
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::burn;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke,
    program_error::ProgramError,
};

pub fn burn_tokens(
    token_account: &AccountInfo,
    mint: &AccountInfo,
    authority: &AccountInfo,
    amount: u64,
    token_program: &AccountInfo,
) -> ProgramResult {
    if !authority.is_signer {
        return Err(ProgramError::MissingRequiredSignature);
    }

    invoke(
        &burn(
            token_program.key,
            token_account.key,
            mint.key,
            authority.key,
            &[],
            amount,
        )?,
        &[
            token_account.clone(),
            mint.clone(),
            authority.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}
```

### Burn with PDA Authority

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, Burn, Mint, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct BurnWithPDA<'info> {
    #[account(mut)]
    pub mint: InterfaceAccount<'info, Mint>,

    #[account(
        mut,
        token::authority = authority,
    )]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(
        seeds = [b"burn-authority"],
        bump,
    )]
    /// CHECK: PDA signer
    pub authority: UncheckedAccount<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn burn_with_pda(ctx: Context<BurnWithPDA>, amount: u64) -> Result<()> {
    let seeds = &[
        b"burn-authority",
        &[ctx.bumps.authority],
    ];
    let signer_seeds = &[&seeds[..]];

    let cpi_accounts = Burn {
        mint: ctx.accounts.mint.to_account_info(),
        from: ctx.accounts.token_account.to_account_info(),
        authority: ctx.accounts.authority.to_account_info(),
    };

    let cpi_context = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts
    ).with_signer(signer_seeds);

    token_interface::burn(cpi_context, amount)?;
    Ok(())
}
```

#### Using Native Rust

```rust
pub fn burn_tokens_from_pda(
    program_id: &Pubkey,
    token_account: &AccountInfo,
    mint: &AccountInfo,
    authority_pda: &AccountInfo,
    token_program: &AccountInfo,
    amount: u64,
    pda_seeds: &[&[u8]],
    bump: u8,
) -> ProgramResult {
    let (expected_pda, _) = Pubkey::find_program_address(pda_seeds, program_id);
    if expected_pda != *authority_pda.key {
        return Err(ProgramError::InvalidSeeds);
    }

    let mut full_seeds = pda_seeds.to_vec();
    full_seeds.push(&[bump]);
    let signer_seeds: &[&[&[u8]]] = &[&full_seeds];

    invoke_signed(
        &burn(
            token_program.key,
            token_account.key,
            mint.key,
            authority_pda.key,
            &[],
            amount,
        )?,
        &[
            token_account.clone(),
            mint.clone(),
            authority_pda.clone(),
            token_program.clone(),
        ],
        signer_seeds,
    )?;

    Ok(())
}
```

---

## Closing Token Accounts

### Close Token Account

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, CloseAccount, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct CloseTokenAccount<'info> {
    #[account(mut)]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(mut)]
    pub destination: SystemAccount<'info>,

    pub authority: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn close_token_account(ctx: Context<CloseTokenAccount>) -> Result<()> {
    let cpi_accounts = CloseAccount {
        account: ctx.accounts.token_account.to_account_info(),
        destination: ctx.accounts.destination.to_account_info(),
        authority: ctx.accounts.authority.to_account_info(),
    };

    let cpi_context = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        cpi_accounts
    );

    token_interface::close_account(cpi_context)?;
    Ok(())
}
```

**Using Anchor Constraints (Simplified):**

```rust
#[derive(Accounts)]
pub struct CloseTokenAccount<'info> {
    #[account(
        mut,
        close = destination,
        token::authority = authority,
    )]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(mut)]
    pub destination: SystemAccount<'info>,

    pub authority: Signer<'info>,
}

pub fn close_token_account(ctx: Context<CloseTokenAccount>) -> Result<()> {
    // Account is automatically closed by Anchor constraints
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::close_account;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    program::invoke,
    program_error::ProgramError,
};

pub fn close_token_account(
    token_account: &AccountInfo,
    destination: &AccountInfo,
    authority: &AccountInfo,
    token_program: &AccountInfo,
) -> ProgramResult {
    if !authority.is_signer {
        return Err(ProgramError::MissingRequiredSignature);
    }

    invoke(
        &close_account(
            token_program.key,
            token_account.key,
            destination.key,
            authority.key,
            &[],
        )?,
        &[
            token_account.clone(),
            destination.clone(),
            authority.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}
```

---

## Token Account Validation

### Validate Token Account Ownership and Mint

#### Using Anchor

```rust
use anchor_spl::token_interface::{TokenAccount, Mint};

#[derive(Accounts)]
pub struct ValidateTokenAccount<'info> {
    #[account(
        constraint = token_account.owner == owner.key() @ ErrorCode::InvalidOwner,
        constraint = token_account.mint == mint.key() @ ErrorCode::InvalidMint,
    )]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    pub mint: InterfaceAccount<'info, Mint>,

    /// CHECK: Any account
    pub owner: UncheckedAccount<'info>,
}

pub fn validate_token_account(ctx: Context<ValidateTokenAccount>) -> Result<()> {
    // Validation is automatic via constraints

    // Additional checks if needed
    require!(
        ctx.accounts.token_account.amount >= 100,
        ErrorCode::InsufficientBalance
    );

    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::state::Account as TokenAccount;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    program_pack::Pack,
    pubkey::Pubkey,
};

pub fn validate_token_account(
    token_account_info: &AccountInfo,
    expected_owner: &Pubkey,
    expected_mint: &Pubkey,
) -> ProgramResult {
    // 1. Verify owned by Token Program
    if token_account_info.owner != &spl_token::ID {
        msg!("Account not owned by Token Program");
        return Err(ProgramError::IllegalOwner);
    }

    // 2. Deserialize token account
    let token_account = TokenAccount::unpack(&token_account_info.data.borrow())?;

    // 3. Verify owner
    if token_account.owner != *expected_owner {
        msg!("Token account owner mismatch");
        return Err(ProgramError::IllegalOwner);
    }

    // 4. Verify mint
    if token_account.mint != *expected_mint {
        msg!("Token account mint mismatch");
        return Err(ProgramError::InvalidAccountData);
    }

    // 5. Verify not frozen
    if token_account.state != spl_token::state::AccountState::Initialized {
        msg!("Token account is frozen or uninitialized");
        return Err(ProgramError::InvalidAccountData);
    }

    Ok(())
}
```

### Validate ATA Address

#### Using Anchor

```rust
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token_interface::{Mint, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct ValidateATA<'info> {
    #[account(
        associated_token::mint = mint,
        associated_token::authority = owner,
        associated_token::token_program = token_program,
    )]
    pub ata: InterfaceAccount<'info, TokenAccount>,

    pub mint: InterfaceAccount<'info, Mint>,

    /// CHECK: Any account
    pub owner: UncheckedAccount<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn validate_ata(ctx: Context<ValidateATA>) -> Result<()> {
    // ATA address is automatically validated by Anchor constraints
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_associated_token_account::get_associated_token_address;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    pubkey::Pubkey,
};

pub fn validate_ata(
    ata_info: &AccountInfo,
    wallet: &Pubkey,
    mint: &Pubkey,
) -> ProgramResult {
    // Derive expected ATA address
    let expected_ata = get_associated_token_address(wallet, mint);

    // Validate match
    if expected_ata != *ata_info.key {
        msg!("Invalid ATA address");
        return Err(ProgramError::InvalidAccountData);
    }

    Ok(())
}
```

### Check Token Balance

#### Using Anchor

```rust
use anchor_spl::token_interface::TokenAccount;

pub fn check_balance(
    ctx: Context<SomeContext>,
    minimum_amount: u64
) -> Result<()> {
    let token_account = &ctx.accounts.token_account;

    require!(
        token_account.amount >= minimum_amount,
        ErrorCode::InsufficientBalance
    );

    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::state::Account as TokenAccount;
use solana_program::{
    account_info::AccountInfo,
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    program_pack::Pack,
};

pub fn check_token_balance(
    token_account_info: &AccountInfo,
    minimum_amount: u64,
) -> ProgramResult {
    let token_account = TokenAccount::unpack(&token_account_info.data.borrow())?;

    if token_account.amount < minimum_amount {
        msg!("Insufficient token balance: {} < {}", token_account.amount, minimum_amount);
        return Err(ProgramError::InsufficientFunds);
    }

    Ok(())
}
```

---

## Token-2022 Extensions

### What are Token Extensions?

The Token Extensions Program (Token-2022) provides additional features through extensions. Extensions are optional functionality that can be added to a token mint or token account.

**Key Points:**
- Extensions must be enabled during account creation
- Cannot add extensions after creation
- Some extensions are incompatible with each other
- Extensions add state to the `tlv_data` field

### Available Extensions

```rust
pub enum ExtensionType {
    TransferFeeConfig,           // Transfer fees
    TransferFeeAmount,           // Withheld fees
    MintCloseAuthority,          // Close mint accounts
    ConfidentialTransferMint,    // Confidential transfers
    DefaultAccountState,         // Default state for new accounts
    ImmutableOwner,              // Cannot change owner
    MemoTransfer,                // Require memos
    NonTransferable,             // Cannot transfer tokens
    InterestBearingConfig,       // Tokens accrue interest
    PermanentDelegate,           // Permanent delegate authority
    TransferHook,                // Custom transfer logic
    MetadataPointer,             // Point to metadata
    TokenMetadata,               // On-chain metadata
    GroupPointer,                // Token groups
    TokenGroup,                  // Group config
    GroupMemberPointer,          // Group membership
    TokenGroupMember,            // Member config
    // ... and more
}
```

### Using Token-2022 in Anchor

```rust
use anchor_spl::token_2022::{self, Token2022};
use anchor_spl::token_interface::{Mint, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct CreateToken2022Mint<'info> {
    #[account(
        init,
        payer = payer,
        mint::decimals = 9,
        mint::authority = mint_authority,
        mint::token_program = token_program,
    )]
    pub mint: InterfaceAccount<'info, Mint>,

    /// CHECK: Mint authority
    pub mint_authority: UncheckedAccount<'info>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub token_program: Program<'info, Token2022>,
    pub system_program: Program<'info, System>,
}
```

**Note:** The `anchor-spl` crate includes the `token_2022_extensions` module for working with extensions, but not all extension instructions are fully implemented yet. You may need to manually implement CPI calls for some extensions.

### Using Token-2022 in Native Rust

```rust
use spl_token_2022::{
    extension::ExtensionType,
    instruction::initialize_mint2,
};

pub fn create_token_2022_mint(
    payer: &AccountInfo,
    mint: &AccountInfo,
    mint_authority: &Pubkey,
    decimals: u8,
    extensions: &[ExtensionType],
) -> ProgramResult {
    // Calculate space needed for extensions
    let mut space = 82; // Base mint size
    for extension in extensions {
        space += extension.get_account_len();
    }

    // Create account with proper size
    // ... (similar to regular mint creation)

    // Initialize extensions
    // Each extension has its own initialization instruction

    // Finally initialize mint
    invoke(
        &initialize_mint2(
            &spl_token_2022::ID,
            mint.key,
            mint_authority,
            None,
            decimals,
        )?,
        &[mint.clone()],
    )?;

    Ok(())
}
```

### Transfer Hook Extension Example (Anchor)

```rust
use anchor_lang::prelude::*;
use anchor_spl::token_interface::{TokenAccount, TokenInterface};

#[program]
pub mod transfer_hook {
    use super::*;

    #[interface(spl_transfer_hook_interface::execute)]
    pub fn execute_transfer_hook(
        ctx: Context<TransferHook>,
        amount: u64,
    ) -> Result<()> {
        msg!("Transfer hook called! Amount: {}", amount);
        // Custom transfer logic here
        Ok(())
    }
}

#[derive(Accounts)]
pub struct TransferHook<'info> {
    pub source: InterfaceAccount<'info, TokenAccount>,
    pub destination: InterfaceAccount<'info, TokenAccount>,
    /// CHECK: authority
    pub authority: UncheckedAccount<'info>,
}
```

---

## Common Token Patterns

### Pattern 1: Token Escrow

Program holds tokens temporarily on behalf of users.

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, TokenAccount, TokenInterface, Transfer};

#[derive(Accounts)]
pub struct InitializeEscrow<'info> {
    #[account(
        init,
        payer = user,
        space = 8 + 32 + 8 + 1,
        seeds = [b"escrow", user.key().as_ref()],
        bump,
    )]
    pub escrow_state: Account<'info, EscrowState>,

    #[account(
        init,
        payer = user,
        token::mint = mint,
        token::authority = escrow_state,
        token::token_program = token_program,
    )]
    pub escrow_token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(mut)]
    pub user_token_account: InterfaceAccount<'info, TokenAccount>,

    pub mint: InterfaceAccount<'info, Mint>,

    #[account(mut)]
    pub user: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
    pub system_program: Program<'info, System>,
}

#[account]
pub struct EscrowState {
    pub user: Pubkey,
    pub amount: u64,
    pub bump: u8,
}

pub fn initialize_escrow(ctx: Context<InitializeEscrow>, amount: u64) -> Result<()> {
    // Transfer tokens to escrow
    token_interface::transfer(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.user_token_account.to_account_info(),
                to: ctx.accounts.escrow_token_account.to_account_info(),
                authority: ctx.accounts.user.to_account_info(),
            },
        ),
        amount,
    )?;

    // Save state
    ctx.accounts.escrow_state.user = ctx.accounts.user.key();
    ctx.accounts.escrow_state.amount = amount;
    ctx.accounts.escrow_state.bump = ctx.bumps.escrow_state;

    Ok(())
}

#[derive(Accounts)]
pub struct ReleaseEscrow<'info> {
    #[account(
        mut,
        seeds = [b"escrow", escrow_state.user.as_ref()],
        bump = escrow_state.bump,
        has_one = user,
        close = user,
    )]
    pub escrow_state: Account<'info, EscrowState>,

    #[account(mut)]
    pub escrow_token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(mut)]
    pub recipient_token_account: InterfaceAccount<'info, TokenAccount>,

    pub user: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn release_escrow(ctx: Context<ReleaseEscrow>) -> Result<()> {
    let seeds = &[
        b"escrow",
        ctx.accounts.user.key().as_ref(),
        &[ctx.accounts.escrow_state.bump],
    ];
    let signer_seeds = &[&seeds[..]];

    token_interface::transfer(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.escrow_token_account.to_account_info(),
                to: ctx.accounts.recipient_token_account.to_account_info(),
                authority: ctx.accounts.escrow_state.to_account_info(),
            },
        ).with_signer(signer_seeds),
        ctx.accounts.escrow_state.amount,
    )?;

    Ok(())
}
```

#### Using Native Rust

```rust
use borsh::{BorshDeserialize, BorshSerialize};
use spl_token::instruction::transfer;

#[derive(BorshSerialize, BorshDeserialize)]
pub struct EscrowState {
    pub user: Pubkey,
    pub amount: u64,
    pub bump: u8,
}

pub fn initialize_escrow(
    program_id: &Pubkey,
    user: &AccountInfo,
    user_token_account: &AccountInfo,
    escrow_token_account: &AccountInfo,
    escrow_state: &AccountInfo,
    amount: u64,
    token_program: &AccountInfo,
) -> ProgramResult {
    // Transfer tokens to escrow
    invoke(
        &transfer(
            &spl_token::ID,
            user_token_account.key,
            escrow_token_account.key,
            user.key,
            &[],
            amount,
        )?,
        &[user_token_account.clone(), escrow_token_account.clone(), user.clone()],
    )?;

    // Save escrow state
    let (pda, bump) = Pubkey::find_program_address(&[b"escrow", user.key.as_ref()], program_id);
    let escrow = EscrowState {
        user: *user.key,
        amount,
        bump,
    };
    escrow.serialize(&mut &mut escrow_state.data.borrow_mut()[..])?;

    Ok(())
}

pub fn release_escrow(
    program_id: &Pubkey,
    escrow_state: &AccountInfo,
    escrow_token_account: &AccountInfo,
    recipient_token_account: &AccountInfo,
    escrow_pda: &AccountInfo,
    amount: u64,
    bump: u8,
    user: &Pubkey,
) -> ProgramResult {
    let signer_seeds: &[&[&[u8]]] = &[&[b"escrow", user.as_ref(), &[bump]]];

    invoke_signed(
        &transfer(
            &spl_token::ID,
            escrow_token_account.key,
            recipient_token_account.key,
            escrow_pda.key,
            &[],
            amount,
        )?,
        &[escrow_token_account.clone(), recipient_token_account.clone(), escrow_pda.clone()],
        signer_seeds,
    )?;

    Ok(())
}
```

### Pattern 2: Token Staking

Users lock tokens to earn rewards.

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, Mint, TokenAccount, TokenInterface, Transfer};

#[derive(Accounts)]
pub struct StakeTokens<'info> {
    #[account(
        init_if_needed,
        payer = user,
        space = 8 + 32 + 8 + 8 + 1,
        seeds = [b"stake", user.key().as_ref()],
        bump,
    )]
    pub stake_account: Account<'info, StakeAccount>,

    #[account(mut)]
    pub user_token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(
        mut,
        seeds = [b"vault"],
        bump,
    )]
    pub vault_token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(mut)]
    pub user: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
    pub system_program: Program<'info, System>,
}

#[account]
pub struct StakeAccount {
    pub user: Pubkey,
    pub amount_staked: u64,
    pub stake_timestamp: i64,
    pub bump: u8,
}

pub fn stake_tokens(ctx: Context<StakeTokens>, amount: u64) -> Result<()> {
    // Transfer tokens to vault
    token_interface::transfer(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.user_token_account.to_account_info(),
                to: ctx.accounts.vault_token_account.to_account_info(),
                authority: ctx.accounts.user.to_account_info(),
            },
        ),
        amount,
    )?;

    // Update stake account
    let clock = Clock::get()?;
    ctx.accounts.stake_account.user = ctx.accounts.user.key();
    ctx.accounts.stake_account.amount_staked += amount;
    ctx.accounts.stake_account.stake_timestamp = clock.unix_timestamp;
    ctx.accounts.stake_account.bump = ctx.bumps.stake_account;

    Ok(())
}

#[derive(Accounts)]
pub struct UnstakeTokens<'info> {
    #[account(
        mut,
        seeds = [b"stake", user.key().as_ref()],
        bump = stake_account.bump,
        has_one = user,
    )]
    pub stake_account: Account<'info, StakeAccount>,

    #[account(mut)]
    pub user_token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(
        mut,
        seeds = [b"vault"],
        bump,
    )]
    pub vault_token_account: InterfaceAccount<'info, TokenAccount>,

    /// CHECK: Vault authority PDA
    #[account(
        seeds = [b"vault-authority"],
        bump,
    )]
    pub vault_authority: UncheckedAccount<'info>,

    pub user: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn unstake_tokens(ctx: Context<UnstakeTokens>, amount: u64) -> Result<()> {
    require!(
        ctx.accounts.stake_account.amount_staked >= amount,
        ErrorCode::InsufficientStake
    );

    let seeds = &[
        b"vault-authority",
        &[ctx.bumps.vault_authority],
    ];
    let signer_seeds = &[&seeds[..]];

    // Transfer tokens back to user
    token_interface::transfer(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            Transfer {
                from: ctx.accounts.vault_token_account.to_account_info(),
                to: ctx.accounts.user_token_account.to_account_info(),
                authority: ctx.accounts.vault_authority.to_account_info(),
            },
        ).with_signer(signer_seeds),
        amount,
    )?;

    // Update stake account
    ctx.accounts.stake_account.amount_staked -= amount;

    Ok(())
}
```

### Pattern 3: NFT Creation

Minting a non-fungible token (supply = 1, decimals = 0).

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, Mint, MintTo, SetAuthority, TokenAccount, TokenInterface};
use anchor_spl::token_interface::spl_token_2022::instruction::AuthorityType;

#[derive(Accounts)]
pub struct CreateNFT<'info> {
    #[account(
        init,
        payer = payer,
        mint::decimals = 0,
        mint::authority = mint_authority,
        mint::token_program = token_program,
    )]
    pub mint: InterfaceAccount<'info, Mint>,

    #[account(
        init,
        payer = payer,
        associated_token::mint = mint,
        associated_token::authority = owner,
        associated_token::token_program = token_program,
    )]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    /// CHECK: Owner of the NFT
    pub owner: UncheckedAccount<'info>,

    pub mint_authority: Signer<'info>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn create_nft(ctx: Context<CreateNFT>) -> Result<()> {
    // Mint exactly 1 token
    token_interface::mint_to(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            MintTo {
                mint: ctx.accounts.mint.to_account_info(),
                to: ctx.accounts.token_account.to_account_info(),
                authority: ctx.accounts.mint_authority.to_account_info(),
            },
        ),
        1,
    )?;

    // Remove mint authority to freeze supply
    token_interface::set_authority(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            SetAuthority {
                account_or_mint: ctx.accounts.mint.to_account_info(),
                current_authority: ctx.accounts.mint_authority.to_account_info(),
            },
        ),
        AuthorityType::MintTokens,
        None,
    )?;

    msg!("NFT created: {}", ctx.accounts.mint.key());
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::{mint_to, set_authority, AuthorityType};

pub fn create_nft(
    mint: &AccountInfo,
    token_account: &AccountInfo,
    mint_authority: &AccountInfo,
    token_program: &AccountInfo,
) -> ProgramResult {
    // 1. Mint exactly 1 token
    invoke(
        &mint_to(
            &spl_token::ID,
            mint.key,
            token_account.key,
            mint_authority.key,
            &[],
            1,  // Exactly 1 token
        )?,
        &[mint.clone(), token_account.clone(), mint_authority.clone()],
    )?;

    // 2. Remove mint authority (make supply fixed)
    invoke(
        &set_authority(
            &spl_token::ID,
            mint.key,
            None,  // Set to None
            AuthorityType::MintTokens,
            mint_authority.key,
            &[],
        )?,
        &[mint.clone(), mint_authority.clone()],
    )?;

    Ok(())
}
```

### Pattern 4: Freezing and Thawing Accounts

#### Using Anchor

```rust
use anchor_spl::token_interface::{self, FreezeAccount, Mint, ThawAccount, TokenAccount, TokenInterface};

#[derive(Accounts)]
pub struct FreezeTokenAccount<'info> {
    #[account(
        mint::freeze_authority = freeze_authority,
    )]
    pub mint: InterfaceAccount<'info, Mint>,

    #[account(mut)]
    pub token_account: InterfaceAccount<'info, TokenAccount>,

    pub freeze_authority: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}

pub fn freeze_account(ctx: Context<FreezeTokenAccount>) -> Result<()> {
    token_interface::freeze_account(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            FreezeAccount {
                account: ctx.accounts.token_account.to_account_info(),
                mint: ctx.accounts.mint.to_account_info(),
                authority: ctx.accounts.freeze_authority.to_account_info(),
            },
        ),
    )?;
    Ok(())
}

pub fn thaw_account(ctx: Context<FreezeTokenAccount>) -> Result<()> {
    token_interface::thaw_account(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),
            ThawAccount {
                account: ctx.accounts.token_account.to_account_info(),
                mint: ctx.accounts.mint.to_account_info(),
                authority: ctx.accounts.freeze_authority.to_account_info(),
            },
        ),
    )?;
    Ok(())
}
```

#### Using Native Rust

```rust
use spl_token::instruction::{freeze_account, thaw_account};

pub fn freeze_token_account(
    token_account: &AccountInfo,
    mint: &AccountInfo,
    freeze_authority: &AccountInfo,
    token_program: &AccountInfo,
) -> ProgramResult {
    invoke(
        &freeze_account(
            token_program.key,
            token_account.key,
            mint.key,
            freeze_authority.key,
            &[],
        )?,
        &[
            token_account.clone(),
            mint.clone(),
            freeze_authority.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}

pub fn thaw_token_account(
    token_account: &AccountInfo,
    mint: &AccountInfo,
    freeze_authority: &AccountInfo,
    token_program: &AccountInfo,
) -> ProgramResult {
    invoke(
        &thaw_account(
            token_program.key,
            token_account.key,
            mint.key,
            freeze_authority.key,
            &[],
        )?,
        &[
            token_account.clone(),
            mint.clone(),
            freeze_authority.clone(),
            token_program.clone(),
        ],
    )?;

    Ok(())
}
```

---

## Security Considerations

### 1. Always Validate Token Accounts

#### Anchor Approach

```rust
#[derive(Accounts)]
pub struct SafeTransfer<'info> {
    #[account(
        mut,
        constraint = source.mint == mint.key() @ ErrorCode::InvalidMint,
        constraint = source.owner == authority.key() @ ErrorCode::InvalidOwner,
    )]
    pub source: InterfaceAccount<'info, TokenAccount>,

    #[account(
        mut,
        constraint = destination.mint == mint.key() @ ErrorCode::InvalidMint,
    )]
    pub destination: InterfaceAccount<'info, TokenAccount>,

    pub mint: InterfaceAccount<'info, Mint>,

    pub authority: Signer<'info>,

    pub token_program: Interface<'info, TokenInterface>,
}
```

#### Native Rust Approach

```rust
// ❌ Dangerous - no validation
pub fn unsafe_transfer(
    source: &AccountInfo,
    destination: &AccountInfo,
    authority: &AccountInfo,
) -> ProgramResult {
    // No checks! Attacker can pass any accounts
    invoke(&transfer_instruction, &accounts)?;
    Ok(())
}

// ✅ Safe - validates everything
pub fn safe_transfer(
    source: &AccountInfo,
    destination: &AccountInfo,
    authority: &AccountInfo,
    expected_mint: &Pubkey,
) -> ProgramResult {
    // Validate source
    validate_token_account(source, authority.key, expected_mint)?;

    // Validate destination
    let dest_token = TokenAccount::unpack(&destination.data.borrow())?;
    if dest_token.mint != *expected_mint {
        return Err(ProgramError::InvalidAccountData);
    }

    invoke(&transfer_instruction, &accounts)?;
    Ok(())
}
```

### 2. Check Token Program ID

#### Anchor Approach

```rust
// Anchor automatically validates via Interface type
pub token_program: Interface<'info, TokenInterface>,
```

#### Native Rust Approach

```rust
pub fn validate_token_program(token_program: &AccountInfo) -> ProgramResult {
    if token_program.key != &spl_token::ID && token_program.key != &spl_token_2022::ID {
        msg!("Invalid Token Program");
        return Err(ProgramError::IncorrectProgramId);
    }
    Ok(())
}
```

### 3. Verify Mint Matches

**Attack scenario:** Attacker passes token account for wrong mint.

#### Anchor Approach

```rust
#[account(
    constraint = token_account.mint == expected_mint.key() @ ErrorCode::InvalidMint,
)]
pub token_account: InterfaceAccount<'info, TokenAccount>,
```

#### Native Rust Approach

```rust
// Always verify mint
let source_token = TokenAccount::unpack(&source.data.borrow())?;
let dest_token = TokenAccount::unpack(&dest.data.borrow())?;

if source_token.mint != dest_token.mint {
    msg!("Mint mismatch between source and destination");
    return Err(ProgramError::InvalidAccountData);
}
```

### 4. Authority Checks

#### Anchor Approach

```rust
#[account(
    constraint = token_account.owner == authority.key() @ ErrorCode::Unauthorized,
)]
pub token_account: InterfaceAccount<'info, TokenAccount>,

pub authority: Signer<'info>,  // Automatically validates is_signer
```

#### Native Rust Approach

```rust
// Verify authority matches token account owner
let token_account = TokenAccount::unpack(&token_account_info.data.borrow())?;

if token_account.owner != *authority.key {
    msg!("Authority doesn't own token account");
    return Err(ProgramError::IllegalOwner);
}

// Verify authority signed
if !authority.is_signer {
    msg!("Authority must sign");
    return Err(ProgramError::MissingRequiredSignature);
}
```

### 5. Account State Checks

#### Anchor Approach

```rust
use spl_token::state::AccountState;

pub fn check_not_frozen(ctx: Context<SomeContext>) -> Result<()> {
    let token_account = &ctx.accounts.token_account;

    require!(
        token_account.state == AccountState::Initialized,
        ErrorCode::AccountFrozen
    );

    Ok(())
}
```

#### Native Rust Approach

```rust
let token_account = TokenAccount::unpack(&token_account_info.data.borrow())?;

// Check not frozen
if token_account.state == spl_token::state::AccountState::Frozen {
    msg!("Token account is frozen");
    return Err(ProgramError::InvalidAccountData);
}

// Check initialized
if token_account.state == spl_token::state::AccountState::Uninitialized {
    msg!("Token account not initialized");
    return Err(ProgramError::UninitializedAccount);
}
```

### 6. Use TransferChecked Over Transfer

**Why:** `transfer_checked` validates the mint and decimals, preventing certain attack vectors.

#### Anchor Approach

```rust
// ✅ Preferred - validates mint and decimals
token_interface::transfer_checked(
    cpi_context,
    amount,
    decimals,
)?;

// ❌ Less secure - no mint/decimal validation
token_interface::transfer(
    cpi_context,
    amount,
)?;
```

#### Native Rust Approach

```rust
// ✅ Preferred
invoke(
    &transfer_checked(
        token_program.key,
        source.key,
        mint.key,
        destination.key,
        authority.key,
        &[],
        amount,
        decimals,
    )?,
    &accounts,
)?;

// ❌ Less secure
invoke(
    &transfer(
        token_program.key,
        source.key,
        destination.key,
        authority.key,
        &[],
        amount,
    )?,
    &accounts,
)?;
```

---

## Summary

### Key Takeaways

**Anchor Advantages:**
- Automatic account validation through constraints
- Cleaner, more concise code
- Built-in safety checks
- Type-safe account structures
- Simplified CPI with `CpiContext`

**Native Rust Advantages:**
- Full control over all operations
- No framework overhead
- Explicit validation (can be more transparent)
- Useful for understanding low-level mechanics

### Common Operations Quick Reference

| Operation | Anchor Module | Native Rust Crate |
|-----------|---------------|-------------------|
| Mint tokens | `token_interface::mint_to` | `spl_token::instruction::mint_to` |
| Transfer tokens | `token_interface::transfer` | `spl_token::instruction::transfer` |
| Transfer checked | `token_interface::transfer_checked` | `spl_token::instruction::transfer_checked` |
| Burn tokens | `token_interface::burn` | `spl_token::instruction::burn` |
| Create ATA | `associated_token` constraint | `spl_associated_token_account` |
| Close account | `token_interface::close_account` | `spl_token::instruction::close_account` |
| Freeze account | `token_interface::freeze_account` | `spl_token::instruction::freeze_account` |

### Security Checklist

- ✅ Validate token program ID
- ✅ Verify token account ownership
- ✅ Check mint matches expected
- ✅ Confirm authority is signer
- ✅ Ensure account not frozen
- ✅ Validate ATA derivation if applicable
- ✅ Use `transfer_checked` instead of `transfer`
- ✅ Validate account state (initialized/frozen)
- ✅ Check sufficient balance before operations

### Token Account Sizes

- **Mint account:** 82 bytes
- **Token account:** 165 bytes
- **Token-2022 with extensions:** 82/165 + extension sizes

Token integration is fundamental for DeFi, NFT, and gaming programs on Solana. Whether using Anchor or native Rust, understanding both approaches provides the flexibility to choose the right tool for your use case.
