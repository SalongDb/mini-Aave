function BorrowContent() {
  const tokens = [
    { name: "DAI", symbol: "Dai Stablecoin", rate: "4.2%" },
    { name: "USDC", symbol: "USD Coin", rate: "3.8%" },
    { name: "ETH", symbol: "Ethereum", rate: "5.1%" },
    { name: "BTC", symbol: "Bitcoin", rate: "4.7%" },
  ];

  return (
    <div className="flex min-h-screen bg-black text-white">

      {/* 🔹 Main */}
      <main className="flex-1 px-10 py-8">

        {/* 🔸 Top Bar */}
        <div className="flex justify-between items-center mb-12">
          <input
            type="text"
            placeholder="Search token..."
            className="bg-white/5 border border-white/10 rounded-lg px-4 py-2 w-80 text-sm outline-none focus:ring-2 focus:ring-purple-500"
          />

          <button className="bg-gradient-to-r from-purple-500 to-blue-500 px-6 py-2 rounded-lg text-sm font-medium hover:opacity-90 transition">
            Get Started
          </button>
        </div>

        {/* 🔸 Heading */}
        <div className="mb-10">
          <h2 className="text-3xl font-semibold tracking-tight mb-2">
            Borrow
          </h2>
          <p className="text-gray-400 text-sm">
            Borrow assets against your collateral. Maintain a healthy position to avoid liquidation.
          </p>
        </div>

        {/* 🔹 Table Header */}
        <div className="grid grid-cols-4 text-sm text-gray-500 mb-3 px-4">
          <span>Asset</span>
          <span>Symbol</span>
          <span>Interest Rate</span>
          <span className="text-right">Action</span>
        </div>

        {/* 🔹 Token List */}
        <div className="space-y-3">
          {tokens.map((token, i) => (
            <div
              key={i}
              className="grid grid-cols-4 items-center bg-white/5 border border-white/10 rounded-xl px-4 py-4 hover:bg-white/10 transition"
            >
              <span className="font-medium">{token.name}</span>
              <span className="text-gray-300">{token.symbol}</span>
              <span className="text-yellow-400">{token.rate}</span>

              <div className="text-right">
                <button className="bg-white text-black px-4 py-2 rounded-lg text-sm hover:bg-gray-200 transition">
                  Borrow
                </button>
              </div>
            </div>
          ))}
        </div>

      </main>
    </div>
  );
}

export default BorrowContent;