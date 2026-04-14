import { useAccount, useConnect, useDisconnect } from "wagmi";

function ConnectWallet() {
  const { isConnected, address } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();

  if (isConnected) {
    return (
      <div className="text-center mt-20">
        <p className="text-gray-400 mb-4">
          Connected: {address?.slice(0, 6)}...{address?.slice(-4)}
        </p>
        <button
          onClick={() => disconnect()}
          className="bg-red-500 px-4 py-2 rounded-lg"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-center justify-center mt-32">
      <h2 className="text-2xl font-semibold mb-6">
        Connect Your Wallet
      </h2>

      {connectors.map((connector) => (
        <button
          key={connector.uid}
          onClick={() => connect({ connector })}
          className="bg-white text-black px-6 py-3 rounded-lg mb-3 hover:bg-gray-200 transition"
        >
          Connect {connector.name}
        </button>
      ))}
    </div>
  );
}

export default ConnectWallet;