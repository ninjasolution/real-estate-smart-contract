const { keccak256, defaultAbiCoder, solidityKeccak256 } = require('ethers/lib/utils');
const { MerkleTree } = require('merkletreejs');

function generateMerkleProof(wallet, tier) {
    const allocations = [
        { wallet: '0x303333556eeEDFD7a744d1AC05C63879C7fE3340', tier: 1},
        { wallet: '0xC4f1ba4545cC2CbFd1296dAf3b88ed573d0B01fe', tier: 2},
        { wallet: '0x0f326E5C91290B816BF475155CEF11857B8B0AF3', tier: 3},
        { wallet: '0x1574C001e8E9325d688AD0C7E6C7A1DdEDa01553', tier: 4},
        { wallet: '0xe7C611269B28AB0748EB5eAB1F7c75D9Be23F9bF', tier: 5},
    ];

    const leaves = allocations.map(({wallet: w, tier: t}) => {
        const rawEncoded = defaultAbiCoder.encode(
            ['address', 'uint256'],
            [w, t]
        )

        return keccak256(rawEncoded);
    });
    
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const root = tree.getHexRoot();

    const userRawEncoded = defaultAbiCoder.encode(
        ['address', 'uint256'],
        [wallet, tier]
    )
    const leaf = keccak256(userRawEncoded);
    const proof = tree.getHexProof(leaf);

    return { root, proof };
}

async function main(wallet, tier) {
    const {root, proof} = generateMerkleProof(wallet, tier);

    const encodedData = defaultAbiCoder.encode(
            ['bytes32', 'bytes32[]'],
            [root, proof]
        )

    console.log(encodedData);
}

const args = process.argv.slice(2);
main(...args)
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });