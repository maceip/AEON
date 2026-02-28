import fs from 'node:fs';
import path from 'node:path';
import * as wbnSign from 'wbn-sign';
import crypto from 'node:crypto';

async function sign() {
    const wbnPath = 'dist/friscy.wbn';
    const swbnPath = 'public/.well-known/friscy.swbn';
    const keyPath = 'dev-key.pem';
    let privateKey;

    if (!fs.existsSync(wbnPath)) {
        console.error('Unsigned bundle not found at', wbnPath);
        process.exit(1);
    }
    const bundle = fs.readFileSync(wbnPath);

    if (process.env.IWA_SIGNING_KEY) {
        console.log('Using signing key from environment variable...');
        privateKey = wbnSign.parsePemKey(process.env.IWA_SIGNING_KEY);
    } else if (fs.existsSync(keyPath)) {
        console.log('Using signing key from local file:', keyPath);
        privateKey = wbnSign.parsePemKey(fs.readFileSync(keyPath));
    } else {
        console.log('Generating new Ed25519 development key...');
        const { privateKey: newKey } = crypto.generateKeyPairSync('ed25519', {
            privateKeyEncoding: { format: 'pem', type: 'pkcs8' }
        });
        fs.writeFileSync(keyPath, newKey);
        privateKey = wbnSign.parsePemKey(newKey);
        console.log('Development key saved to', keyPath, '(DO NOT COMMIT THIS)');
    }

    console.log('Signing Web Bundle...');
    try {
        const webBundleId = new wbnSign.WebBundleId(privateKey);
        
        // Use wbnSign to add integrity block
        // Constructor: webBundle, webBundleId, signingStrategies
        const integrityBlock = new wbnSign.IntegrityBlockSigner(bundle, webBundleId, [new wbnSign.NodeCryptoSigningStrategy(privateKey)]);
        const { signedWebBundle } = await integrityBlock.sign();
        
        fs.writeFileSync(swbnPath, signedWebBundle);
        
        console.log('Successfully signed bundle.');
        console.log('Signed Bundle placed at', swbnPath);
        
        console.log('Web Bundle ID:', webBundleId.toString());
        console.log('Manifest is at public/.well-known/manifest.json');
    } catch (err) {
        console.error('Failed to sign bundle:', err);
        process.exit(1);
    }
}

sign();
