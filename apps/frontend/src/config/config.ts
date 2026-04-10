import { createConfig, http, injected } from 'wagmi';
import { sepolia } from 'wagmi/chains';

// Wagmi config for Sepolia network + wallet connection
export const config = createConfig({
    chains: [sepolia],

    // Enables injected wallets (e.g. MetaMask)
    connectors: [
        injected(),
    ],

    // RPC endpoint for blockchain communication
    transports: {
        [sepolia.id]: http(import.meta.env.VITE_SEPOLIA_URL),
    },
})