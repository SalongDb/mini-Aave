import { useMemo } from "react";

function DashboardContent() {
  const greeting = useMemo(() => {
    const hour = new Date().getHours();
    if (hour < 12) return "Good Morning ☀️";
    if (hour < 18) return "Good Afternoon 🌤️";
    return "Good Evening 🌙";
  }, []);

  const deposits = [
    { token: "ETH", amount: 1.2, value: 3600 },
    { token: "USDC", amount: 500, value: 500 },
  ];

  const borrows = [
    { token: "DAI", amount: 200, value: 200 },
  ];

  // 🔥 Derived values
  const totalDeposits = deposits.reduce((acc, d) => acc + d.value, 0);
  const totalBorrows = borrows.reduce((acc, b) => acc + b.value, 0);

  const healthFactor =
    totalBorrows === 0
      ? "∞"
      : ((totalDeposits * 0.75) / totalBorrows).toFixed(2);

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

          <div className="bg-white/5 px-4 py-2 rounded-lg border border-white/10 text-sm text-gray-300">
            0xA1b2...9F3d
          </div>
        </div>

        {/* 🔸 Greeting */}
        <h2 className="text-3xl font-semibold mb-8 tracking-tight">
          {greeting}
        </h2>

        {/* 🔥 Stats Section */}
        <div className="grid grid-cols-3 gap-6 mb-12">
          <div className="bg-white/5 border border-white/10 rounded-xl p-6">
            <p className="text-gray-400 text-sm mb-2">Total Deposits</p>
            <h3 className="text-2xl font-semibold">
              ${totalDeposits.toLocaleString()}
            </h3>
          </div>

          <div className="bg-white/5 border border-white/10 rounded-xl p-6">
            <p className="text-gray-400 text-sm mb-2">Total Borrowed</p>
            <h3 className="text-2xl font-semibold">
              ${totalBorrows.toLocaleString()}
            </h3>
          </div>

          <div className="bg-white/5 border border-white/10 rounded-xl p-6">
            <p className="text-gray-400 text-sm mb-2">Health Factor</p>
            <h3
              className={`text-2xl font-semibold ${
                healthFactor === "∞"
                  ? "text-green-400"
                  : Number(healthFactor) > 1.5
                  ? "text-green-400"
                  : Number(healthFactor) > 1
                  ? "text-yellow-400"
                  : "text-red-400"
              }`}
            >
              {healthFactor}
            </h3>
          </div>
        </div>

        {/* 🔹 Deposits */}
        <section className="mb-14">
          <h3 className="text-lg font-semibold mb-6 text-gray-200">
            Your Deposits
          </h3>

          <div className="grid grid-cols-4 text-sm text-gray-500 mb-3 px-4">
            <span>Token</span>
            <span>Quantity</span>
            <span>Value</span>
            <span className="text-right">Action</span>
          </div>

          <div className="space-y-3">
            {deposits.map((d, i) => (
              <div
                key={i}
                className="grid grid-cols-4 items-center bg-white/5 border border-white/10 rounded-xl px-4 py-4 hover:bg-white/10 transition"
              >
                <span className="font-medium">{d.token}</span>
                <span className="text-gray-300">{d.amount}</span>
                <span className="text-gray-300">
                  ${d.value.toLocaleString()}
                </span>

                <div className="text-right">
                  <button className="bg-red-500/80 px-4 py-2 rounded-lg text-sm hover:bg-red-500 transition">
                    Withdraw
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* 🔹 Borrows */}
        <section>
          <h3 className="text-lg font-semibold mb-6 text-gray-200">
            Your Borrows
          </h3>

          <div className="grid grid-cols-4 text-sm text-gray-500 mb-3 px-4">
            <span>Token</span>
            <span>Quantity</span>
            <span>Value</span>
            <span className="text-right">Action</span>
          </div>

          <div className="space-y-3">
            {borrows.map((b, i) => (
              <div
                key={i}
                className="grid grid-cols-4 items-center bg-white/5 border border-white/10 rounded-xl px-4 py-4 hover:bg-white/10 transition"
              >
                <span className="font-medium">{b.token}</span>
                <span className="text-gray-300">{b.amount}</span>
                <span className="text-gray-300">
                  ${b.value.toLocaleString()}
                </span>

                <div className="text-right">
                  <button className="bg-green-500/80 px-4 py-2 rounded-lg text-sm hover:bg-green-500 transition">
                    Repay
                  </button>
                </div>
              </div>
            ))}
          </div>
        </section>

      </main>
    </div>
  );
}

export default DashboardContent;