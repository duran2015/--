import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App.tsx';
import ClientApp from './client-app/ClientApp.tsx';
import './index.css';
import { isKnownAppPath, resolveAppRoute } from './routeResolution';

if (!isKnownAppPath(window.location.pathname)) {
  window.history.replaceState(null, '', '/counselor');
}

const route = resolveAppRoute(window.location.pathname);

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    {route === 'client' ? <ClientApp /> : <App />}
  </StrictMode>,
);
