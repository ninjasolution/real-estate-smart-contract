const ethers = require('ethers');

// export function getPermitTransferSignature(
//     wallet,
//     permit,
//     permitCaller,
//     privateKey
// ) {
//     let msgHash = _msgHash(permit, permitCaller);

//     let [v, r, s] = ethers.utils.splitSignature(wallet.signMessage(privateKey, msgHash));
//     return ethers.utils.concat(r, s, ethers.utils.hexlify(v));
// }

// export function msgHash(permit, permitCaller) {
//     const tokenPermissionsHash = ethers.utils.keccak256(
//         ethers.utils.defaultAbiCoder.encode(['bytes32', 'address'], [permit.permitted])
//     );

//     const DOMAIN_SEPARATOR = permit;

//     const permitTransferHash = ethers.utils.keccak256(
//         ethers.utils.defaultAbiCoder.encode(['bytes32', 'address', 'uint256', 'uint256'],
//             [tokenPermissionsHash, permitCaller, permit.nonce, permit.deadline])
//     );

//     return ethers.utils.keccak256(
//         ethers.utils.defaultAbiCoder.encode(['bytes1', 'bytes32', 'bytes32'],
//             ['0x19', DOMAIN_SEPARATOR, permitTransferHash])
//     );
// }

// export function generateLeaves(inputs) {
//     return inputs.map((x) =>
//     ethers.utils.solidityKeccak256(
//       ["address", "uint"],
//       [x.address, ethers.utils.parseEther(x.amount.toString())]
//     )
//   );
// }

// export function generateMerkleRootAndProof(leaves, nodeIndex) {
//     const tree = new MerkleTree(leaves, ethers.utils.keccak256, {
//         sortPairs: true,
//     });
//     const root = tree.getHexRoot();

//     const proof = tree.getHexProof(leaves[parseInt(nodeIndex)]);

//     return { root, proof };
// }