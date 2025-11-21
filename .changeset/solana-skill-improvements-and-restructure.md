---
"solana-skill": minor
---

Major improvements and reorganization of Solana development skill

**New Content:**
- **production-deployment.md**: Complete guide for verified builds with Anchor 0.32.1, explaining why `anchor deploy` shouldn't be used for production and the proper `solana-verify build` workflow
- **Mollusk 0.5.1 compatibility**: Documented that Mollusk 0.5.1 is the last version compatible with Anchor 0.32.1 (Solana SDK 2.2.x)
- **Test Pyramid Structure**: Added comprehensive 4-level testing strategy (inline tests → Mollusk → SDK integration → devnet/mainnet)

**File Organization - Progressive Disclosure:**

Split large reference files into focused, manageable documents using flat structure with prefixed naming:

**Tokens (5 files, was 1 @ 2,427 lines):**
- `tokens-overview.md` (~400 lines): Token fundamentals, account structures, ATAs
- `tokens-operations.md` (~1,180 lines): Create, mint, transfer, burn, close operations
- `tokens-validation.md` (~300 lines): Account validation patterns
- `tokens-2022.md` (~190 lines): Token Extensions Program features
- `tokens-patterns.md` (~360 lines): Common patterns (escrow, staking, NFT) + security

**Testing (3 files, was 1 @ 2,121 lines):**
- `testing-overview.md` (~470 lines): Test pyramid, strategy, fundamentals
- `testing-frameworks.md` (~1,190 lines): Mollusk, Anchor test, Native Rust details
- `testing-practices.md` (~500 lines): Best practices, patterns, CI/CD

**Benefits:**
- Users needing Token-2022 info won't load 1,800 lines of basic operations
- Anchor developers won't load Native Rust testing patterns they don't use
- Clearer progressive disclosure without nested subdirectories
- All reference files remain one level deep from SKILL.md (Anthropic best practice)

**Updated:**
- SKILL.md with new file references (8 locations updated)
