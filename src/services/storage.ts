import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';
import { AppData } from '../types';

const DATA_FILE = 'app-data.json';
const REPORT_FILE = 'report.md';

export const StorageService = {
    async saveData(data: AppData): Promise<void> {
        try {
            await Filesystem.writeFile({
                path: DATA_FILE,
                data: JSON.stringify(data),
                directory: Directory.Data,
                encoding: Encoding.UTF8
            });
        } catch (e) {
            console.error('Failed to save data:', e);
        }
    },

    async loadData(): Promise<AppData | null> {
        try {
            const result = await Filesystem.readFile({
                path: DATA_FILE,
                directory: Directory.Data,
                encoding: Encoding.UTF8
            });
            return JSON.parse(result.data as string);
        } catch (e) {
            // File might not exist yet
            console.log('No saved data found');
            return null;
        }
    },

    async saveReport(content: string): Promise<void> {
        try {
            await Filesystem.writeFile({
                path: REPORT_FILE,
                data: content,
                directory: Directory.Data,
                encoding: Encoding.UTF8
            });
        } catch (e) {
            console.error('Failed to save report:', e);
        }
    },

    async loadReport(): Promise<string> {
        try {
            const result = await Filesystem.readFile({
                path: REPORT_FILE,
                directory: Directory.Data,
                encoding: Encoding.UTF8
            });
            return result.data as string;
        } catch (e) {
            return '';
        }
    }
};
