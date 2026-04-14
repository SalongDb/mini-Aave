import './App.css'
import LandingPage from './pages/LandingPage';
import DashboardLayout from './pages/DashboardLayout';
import { BrowserRouter, Route, Routes } from 'react-router-dom';

function App() {
  
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage/>}></Route>
        <Route path="/app" element={<DashboardLayout/>}></Route>
      </Routes>
    </BrowserRouter>
  );
}

export default App;