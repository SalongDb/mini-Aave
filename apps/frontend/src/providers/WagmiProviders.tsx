import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { config } from "../config/config";
import { WagmiProvider } from "wagmi";
import type { ReactNode } from "react";

// React Query client for caching blockchain data
const queryClient = new QueryClient();

// Global providers for wagmi (web3) and react-query
function Providers({ children }: {
    children : ReactNode
}) {
    return (
        <WagmiProvider config={config}>
            <QueryClientProvider client={queryClient}>
                {children}
            </QueryClientProvider>
        </WagmiProvider>
    )
}

export default Providers;