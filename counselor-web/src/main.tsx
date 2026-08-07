import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import './index.css';
import { isKnownAppPath } from './routeResolution';

if (!isKnownAppPath(window.location.pathname)) {
  window.history.replaceState(null, '', '/counselor');
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
