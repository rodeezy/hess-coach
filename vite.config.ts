import react from '@vitejs/plugin-react'
import inertia from '@inertiajs/vite'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  server: {
    // Reachable from an iPhone on the same wifi. Rails proxies /vite-dev/ to
    // here, so the phone only ever connects to Rails.
    host: '0.0.0.0',
    allowedHosts: true,
  },
  plugins: [
    tailwindcss(),
    RubyPlugin(),
    inertia(),
    react(),
  ],
})
