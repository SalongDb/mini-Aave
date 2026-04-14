import { useNavigate } from "react-router-dom";

function LandingPage() {
  const navigate = useNavigate();

  const tokens = [
    {
      name: "ETH",
      img: "https://cryptologos.cc/logos/ethereum-eth-logo.png",
    },
    {
      name: "BTC",
      img: "https://cryptologos.cc/logos/bitcoin-btc-logo.png",
    },
    {
      name: "USDC",
      img: "https://cryptologos.cc/logos/usd-coin-usdc-logo.png",
    },
    {
      name: "DAI",
      img: "https://cryptologos.cc/logos/multi-collateral-dai-dai-logo.png",
    },
  ];

  return (
    <div className="min-h-screen bg-black text-white flex flex-col relative overflow-hidden">

      {/* 🌈 Background Glow */}
      <div className="absolute top-[-200px] left-1/2 -translate-x-1/2 w-[800px] h-[800px] bg-purple-600/20 rounded-full blur-3xl" />
      <div className="absolute bottom-[-200px] right-[-100px] w-[600px] h-[600px] bg-blue-600/20 rounded-full blur-3xl" />

      {/* 🔹 Navbar */}
      <nav className="flex justify-between items-center px-10 py-5 border-b border-white/10 backdrop-blur-md relative z-10">
        <h1 className="text-xl font-semibold tracking-tight">
          DeFi Protocol
        </h1>

        <button onClick={() => navigate("/app")}  className="bg-white text-black px-5 py-2 rounded-lg hover:bg-gray-200 transition font-medium">
          Launch App
        </button>
      </nav>

      {/* 🔹 Hero */}
      <section className="flex flex-col items-center text-center px-6 py-28 relative z-10">

        <h1 className="text-5xl md:text-6xl font-bold max-w-3xl leading-tight">
          The Future of
          <span className="block bg-gradient-to-r from-purple-400 to-blue-400 bg-clip-text text-transparent">
            Decentralized Finance
          </span>
        </h1>

        <p className="mt-6 text-lg text-gray-400 max-w-xl">
          Earn yield, borrow assets, and manage your crypto portfolio —
          all in one seamless DeFi experience.
        </p>

        <div className="flex gap-4 mt-10">
          <button className="bg-gradient-to-r from-purple-500 to-blue-500 px-8 py-3 rounded-xl text-lg font-medium hover:opacity-90 transition">
            Get Started
          </button>

          <button className="border border-white/20 px-8 py-3 rounded-xl text-lg hover:bg-white/5 transition">
            Learn More
          </button>
        </div>
      </section>

      {/* 🔹 Tokens */}
      <section className="px-10 py-20 relative z-10">
        <h2 className="text-2xl font-semibold text-center mb-12">
          Supported Assets
        </h2>

        <div className="flex flex-wrap justify-center gap-10">
          {tokens.map((token, i) => (
            <div
              key={i}
              className="bg-white/5 backdrop-blur-lg border border-white/10 rounded-2xl p-6 w-36 text-center hover:bg-white/10 hover:-translate-y-1 transition shadow-lg"
            >
              <img
                src={token.img}
                alt={token.name}
                className="w-14 mx-auto mb-4"
              />
              <p className="font-medium text-gray-200">{token.name}</p>
            </div>
          ))}
        </div>
      </section>

      {/* 🔹 Footer */}
      <footer className="mt-auto border-t border-white/10 py-8 text-center text-gray-500 text-sm relative z-10">
        © 2026 DeFi Protocol. Built with DeFi ⚡
      </footer>
    </div>
  );
}

export default LandingPage;