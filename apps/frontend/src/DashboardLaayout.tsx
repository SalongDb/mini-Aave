import { useState } from "react";
import DashboardContent from "./components/DashboardContent";
import DepositContent from "./components/DepositContent";
import BorrowContent from "./components/BorrowContent";

function DashboardLayout() {
  const [activeTab, setActiveTab] = useState<
    "dashboard" | "deposit" | "borrow"
  >("dashboard");

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
            className={`text-left ${
              activeTab === "dashboard" ? "text-white" : "text-gray-400"
            }`}
          >
            Dashboard
          </button>

          <button
            onClick={() => setActiveTab("deposit")}
            className={`text-left ${
              activeTab === "deposit" ? "text-white" : "text-gray-400"
            }`}
          >
            Deposit
          </button>

          <button
            onClick={() => setActiveTab("borrow")}
            className={`text-left ${
              activeTab === "borrow" ? "text-white" : "text-gray-400"
            }`}
          >
            Borrow
          </button>
        </nav>
      </aside>

      {/* 🔹 Main Content */}
      <main className="flex-1 px-10 py-8">

        {/* 🔥 Conditional Rendering */}
        {activeTab === "dashboard" && <DashboardContent />}
        {activeTab === "deposit" && <DepositContent />}
        {activeTab === "borrow" && <BorrowContent />}

      </main>
    </div>
  );
}

export default DashboardLayout;