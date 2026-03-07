/**
 * Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
 * All rights reserved.
 */
import { AppData } from '../types';

const DB_NAME = 'CardioInsightDB';
const STORE_NAME = 'AppDataStore';
const DATA_KEY = 'app-data';
const REPORT_KEY = 'report-data';

const getDB = (): Promise<IDBDatabase> => {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, 1);
        
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve(request.result);
        
        request.onupgradeneeded = (event) => {
            const db = (event.target as IDBOpenDBRequest).result;
            if (!db.objectStoreNames.contains(STORE_NAME)) {
                db.createObjectStore(STORE_NAME);
            }
        };
    });
};

export const StorageService = {
    async saveData(data: AppData): Promise<void> {
        try {
            const db = await getDB();
            return new Promise((resolve, reject) => {
                const transaction = db.transaction(STORE_NAME, 'readwrite');
                const store = transaction.objectStore(STORE_NAME);
                
                const request = store.put(data, DATA_KEY);
                request.onsuccess = () => resolve();
                request.onerror = () => reject(request.error);
            });
        } catch (e) {
            console.error('Failed to save data to IndexedDB:', e);
        }
    },

    async loadData(): Promise<AppData | null> {
        try {
            const db = await getDB();
            return new Promise((resolve, reject) => {
                const transaction = db.transaction(STORE_NAME, 'readonly');
                const store = transaction.objectStore(STORE_NAME);
                
                const request = store.get(DATA_KEY);
                request.onsuccess = () => {
                    resolve(request.result ? (request.result as AppData) : null);
                };
                request.onerror = () => reject(request.error);
            });
        } catch (e) {
            console.log('No saved data found in IndexedDB');
            return null;
        }
    },

    async saveReport(content: string): Promise<void> {
        try {
            const db = await getDB();
            return new Promise((resolve, reject) => {
                const transaction = db.transaction(STORE_NAME, 'readwrite');
                const store = transaction.objectStore(STORE_NAME);
                
                const request = store.put(content, REPORT_KEY);
                request.onsuccess = () => resolve();
                request.onerror = () => reject(request.error);
            });
        } catch (e) {
            console.error('Failed to save report to IndexedDB:', e);
        }
    },

    async loadReport(): Promise<string> {
        try {
            const db = await getDB();
            return new Promise((resolve, reject) => {
                const transaction = db.transaction(STORE_NAME, 'readonly');
                const store = transaction.objectStore(STORE_NAME);
                
                const request = store.get(REPORT_KEY);
                request.onsuccess = () => {
                    resolve(request.result ? (request.result as string) : '');
                };
                request.onerror = () => reject(request.error);
            });
        } catch (e) {
            return '';
        }
    }
};
