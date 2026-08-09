import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

interface ContractDeployment {
    address: string;
    chainId: number;
    deploymentBlock: number;
    deploymentTx: string;
    contractName: string;
    version: string;
}

interface DeploymentManifest {
    gitCommit: string;
    timestamp: number;
    contracts: {
        [chainId: string]: {
            [contractName: string]: ContractDeployment
        }
    };
    // We can add more metadata here later
}

function getLatestDeployment() {
    const ignitionDir = path.join(__dirname, '..', 'ignition', 'deployments');
    const chainDirs = fs.readdirSync(ignitionDir)
        .filter(f => f.startsWith('chain-'))
        .map(dir => ({
            dir,
            chainId: parseInt(dir.split('-')[1])
        }));

    const deployments: Record<string, any> = {};

    for (const { dir, chainId } of chainDirs) {
        const chainDir = path.join(ignitionDir, dir);

        // Read deployed addresses
        const addressesPath = path.join(chainDir, 'deployed_addresses.json');
        if (fs.existsSync(addressesPath)) {
            const addresses = JSON.parse(fs.readFileSync(addressesPath, 'utf8'));

            // Read journal for deployment details
            const journalPath = path.join(chainDir, 'journal.jsonl');
            const journal = fs.readFileSync(journalPath, 'utf8')
                .split('\n')
                .filter(Boolean)
                .map(line => JSON.parse(line));

            // Find deployment confirmation
            const deploymentConfirm = journal.find(entry =>
                entry.type === 'TRANSACTION_CONFIRM' &&
                entry.receipt?.status === 'SUCCESS'
            );

            if (deploymentConfirm) {
                deployments[chainId] = {
                    addresses,
                    blockNumber: deploymentConfirm.receipt.blockNumber,
                    transactionHash: deploymentConfirm.hash
                };
            }
        }
    }

    return deployments;
}

function generateManifest(): DeploymentManifest {
    const gitCommit = execSync('git rev-parse HEAD').toString().trim();
    const deployment = getLatestDeployment();

    // For now, just BlueRailroadV2 on Polygon
    const manifest: DeploymentManifest = {
        gitCommit,
        timestamp: Date.now(),
        contracts: {
            "137": {
                "BlueRailroadV2": {
                    address: "0xb96A231384eEeA72A0EDF8b2e896FA4BaCAa22fF",
                    chainId: 137,
                    deploymentBlock: 51234567, // We should get this from deployment artifacts
                    deploymentTx: "0x...",     // We should get this from deployment artifacts
                    contractName: "BlueRailroadV2",
                    version: "2.0.0"
                }
            }
        }
    };

    // Write to blox-office's deployment directory
    const outputPath = path.join(__dirname, '..', 'deployments', 'manifest.json');
    fs.mkdirSync(path.dirname(outputPath), { recursive: true });
    fs.writeFileSync(outputPath, JSON.stringify(manifest, null, 2));

    return manifest;
}

// Run if called directly
if (require.main === module) {
    generateManifest();
}

export { generateManifest, DeploymentManifest };

export function readManifest(): DeploymentManifest {
    const manifestPath = path.join(__dirname, '..', 'deployments', 'manifest.json');
    if (!fs.existsSync(manifestPath)) {
        throw new Error('Manifest not found. Run generate-manifest first.');
    }
    return JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
}