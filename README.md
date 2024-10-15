# Merkle Airdrop Project

This project implements a secure and gas-efficient token airdrop system using Merkle trees and EIP-712 signatures.

## Contracts

### VineToken

A simple ERC20 token contract with minting capabilities.

- **Name:** Vine Token
- **Symbol:** VINE
- **Features:**
  - Minting restricted to the contract owner

### MerkleAirdrop

A contract for distributing tokens to users who can prove their inclusion in a Merkle tree.

- **Features:**
  - Merkle tree verification for efficient gas usage
  - EIP-712 signature verification for added security
  - Prevention of double claims

## Key Functionalities

1. **Token Creation:** `VineToken` allows the owner to mint new tokens.

2. **Airdrop Claiming:** Users can claim tokens if they:
   - Are included in the Merkle tree
   - Provide a valid Merkle proof
   - Sign their claim with their Ethereum account

3. **Security Measures:**
   - Merkle tree verification prevents unauthorized claims
   - EIP-712 signatures ensure claim authenticity
   - Mapping tracks claimed addresses to prevent double-claiming

## Usage

1. Deploy `VineToken` contract
2. Mint tokens to the `MerkleAirdrop` contract
3. Generate Merkle tree off-chain with eligible addresses and amounts
4. Deploy `MerkleAirdrop` contract with the Merkle root and `VineToken` address
5. Users call `claim()` function with their proof and signature to receive tokens

## Functions

### VineToken

- `mint(address account, uint256 amount)`: Mints new tokens to a specified account (owner only)

### MerkleAirdrop

- `claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)`: Allows users to claim their tokens
- `getMessageHash(address account, uint256 amount)`: Returns the EIP-712 typed data hash for signing
- `getMerkleRoot()`: Returns the Merkle root used for verification
- `getAirdropToken()`: Returns the address of the token being airdropped

## Error Handling

The `MerkleAirdrop` contract includes custom errors for better gas efficiency and clarity:

- `MerkleAirdrop__InvalidProof()`: Thrown when the provided Merkle proof is invalid
- `MerkleAirdrop__AlreadyClaimed()`: Thrown when an address attempts to claim twice
- `MerkleAirdrop__InvalidSignature()`: Thrown when the provided signature is invalid

## Security Considerations

- The Merkle root should be generated securely off-chain
- The contract owner should ensure the correct Merkle root is set during deployment
- Users should keep their Merkle proofs private to prevent front-running

## Dependencies

- OpenZeppelin Contracts (ERC20, Ownable, MerkleProof, SafeERC20, EIP712, ECDSA)

## License

This project is licensed under the MIT License.
