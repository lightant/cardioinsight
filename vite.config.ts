import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react()],
    build: {
        chunkSizeWarningLimit: 1000, // Increase warning limit to 1MB
        rollupOptions: {
            output: {
                manualChunks: {
                    'vendor-react': ['react', 'react-dom'],
                    'vendor-charts': ['recharts'],
                    'vendor-utils': ['date-fns', 'i18next', 'react-i18next', 'lucide-react'],
                    'vendor-capacitor': ['@capacitor/core', '@capacitor/filesystem'],
                }
            }
        }
    }
})
