import { useState, useEffect } from "react";
import DashboardContent from "../components/DashboardContent";
import DepositContent from "../components/DepositContent";
import BorrowContent from "../components/BorrowContent";
import { useAccount, useDisconnect } from "wagmi";
import ConnectWallet from "../wagmi/connectWallet";

function DashboardLayout() {
  const { isConnected, address } = useAccount();
  const { disconnect } = useDisconnect();

  const [activeTab, setActiveTab] = useState<
    "dashboard" | "deposit" | "borrow"
  >("dashboard");

  const [showConnect, setShowConnect] = useState(false);

  // 🔥 Auto close modal after connect
  useEffect(() => {
    if (isConnected) setShowConnect(false);
  }, [isConnected]);

  return (
    <div className="flex min-h-screen bg-black text-white">

      {/* 🔹 Sidebar */}
      <aside className="w-64 bg-white/5 border-r border-white/10 p-6 flex flex-col">
        <h1 className="text-xl font-semibold mb-10 tracking-tight">
          DeFi Protocol
        </h1>

        <nav className="flex flex-col gap-4 text-sm">
          <button
            onClick={() => setActiveTab("dashboard")}
            className={`text-left transition ${activeTab === "dashboard"
                ? "text-white font-medium"
                : "text-gray-400 hover:text-white"
              }`}
          >
            Dashboard
          </button>

          <button
            onClick={() => setActiveTab("deposit")}
            className={`text-left transition ${activeTab === "deposit"
                ? "text-white font-medium"
                : "text-gray-400 hover:text-white"
              }`}
          >
            Deposit
          </button>

          <button
            onClick={() => setActiveTab("borrow")}
            className={`text-left transition ${activeTab === "borrow"
                ? "text-white font-medium"
                : "text-gray-400 hover:text-white"
              }`}
          >
            Borrow
          </button>
        </nav>
      </aside>

      {/* 🔹 Main */}
      <main className="flex-1 px-10 py-8">

        {/* 🔸 Top Bar */}
        <div className="flex justify-between items-center mb-12">

          {/* Search */}
          <input
            type="text"
            placeholder="Search token..."
            className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 w-80 text-sm outline-none focus:ring-2 focus:ring-purple-500"
          />

          {/* Wallet */}
          <div className="flex gap-2 items-center">

            {isConnected && (
              <div className="flex items-center gap-3 bg-white/5 px-4 py-2 rounded-lg border border-white/10">
                <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                <span className="text-sm text-gray-300">
                  {address?.slice(0, 6)}...{address?.slice(-4)}
                </span>
              </div>
            )}

            {isConnected ? (
              <button
                onClick={() => disconnect()}
                className="bg-red-500 px-4 py-2 rounded-lg text-sm hover:bg-red-600 transition"
              >
                Disconnect
              </button>
            ) : (
              <button
                onClick={() => setShowConnect(true)}
                className="bg-gradient-to-r from-purple-500 to-blue-500 px-6 py-2 rounded-lg text-sm font-medium hover:opacity-90 transition"
              >
                Get Started
              </button>
            )}
          </div>
        </div>

        {/* 🔥 DASHBOARD (with overlay) */}
        {activeTab === "dashboard" && (
  <div className="relative">
    
    {/* 🔹 Blur wrapper */}
    <div className={!isConnected ? "blur-sm pointer-events-none" : ""}>
      <DashboardContent />
    </div>

    {/* 🔒 Overlay */}
    {!isConnected && (
      <div className="fixed inset-0 flex items-center justify-center z-50">
        
        {/* dim background but still visible */}
        <div className="absolute inset-0 bg-black/60"></div>

        {/* wallet modal */}
        <div className="relative z-10 w-full max-w-md px-4">
          <ConnectWallet />
        </div>
      </div>
    )}
  </div>
)}

        {/* 🔥 DEPOSIT (always visible) */}
        {activeTab === "deposit" && <DepositContent />}

        {/* 🔥 BORROW (always visible) */}
        {activeTab === "borrow" && <BorrowContent />}

        {/* 🔥 CONNECT WALLET MODAL */}
        {showConnect && (
          <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50">

            <div className="bg-[#0f0f0f] border border-white/10 rounded-xl p-6 w-[400px] relative">

              <button
                onClick={() => setShowConnect(false)}
                className="absolute top-3 right-3 text-gray-400 hover:text-white"
              >
                ✕
              </button>

              <ConnectWallet />
            </div>
          </div>
        )}

      </main>
    </div>
  );
}

export default DashboardLayout;