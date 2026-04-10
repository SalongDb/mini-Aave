import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import Providers from './providers/WagmiProviders.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Providers> {/* Makes blockchain + data available to whole app */}
      <App />
    </Providers>
  </StrictMode>,
)