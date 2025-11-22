import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
    appId: 'com.cardioinsight.app',
    appName: 'Cardio Insight',
    webDir: 'dist',
    server: {
        androidScheme: 'https'
    }
};

export default config;
