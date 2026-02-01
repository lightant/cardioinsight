import { Capacitor } from '@capacitor/core';
import { HealthConnect } from 'capacitor-health-connect';

export const HealthService = {
    async checkAvailability(): Promise<boolean> {
        if (Capacitor.getPlatform() !== 'android') {
            return false;
        }
        try {
            const result = await HealthConnect.checkAvailability();
            return result.availability === 'Available';
        } catch (e) {
            console.error('Health Connect availability check failed', e);
            return false;
        }
    },

    async requestPermissions(): Promise<boolean> {
        if (Capacitor.getPlatform() !== 'android') return false;
        try {
            const result = await HealthConnect.requestHealthPermissions({
                read: ['HeartRateSeries', 'Steps'],
                write: []
            });
            return result.hasAllPermissions;
        } catch (e: any) {
            console.error('Permission request failed', e);
            throw new Error(e.message || 'Permission request failed');
        }
    },

    async getHeartRateData(startTime: Date, endTime: Date): Promise<any[]> {
        if (Capacitor.getPlatform() !== 'android') return [];
        try {
            const allRecords: any[] = [];
            let currentStart = new Date(startTime);

            // Health Connect limit is 1000 records per request. 
            // We fetch day by day to ensure we get all data.
            while (currentStart < endTime) {
                const currentEnd = new Date(currentStart);
                currentEnd.setDate(currentEnd.getDate() + 1);

                // Don't exceed the global endTime
                const chunkEnd = currentEnd > endTime ? endTime : currentEnd;
                let pageToken: string | undefined = undefined;

                do {
                    const result: { records: any[]; pageToken?: string } = await HealthConnect.readRecords({
                        type: 'HeartRateSeries',
                        timeRangeFilter: {
                            type: 'between',
                            startTime: currentStart,
                            endTime: chunkEnd
                        },
                        pageToken: pageToken
                    });

                    if (result.records) {
                        allRecords.push(...result.records);
                    }

                    pageToken = result.pageToken;
                } while (pageToken);

                currentStart = currentEnd;
            }

            return allRecords;
        } catch (e) {
            console.error('Failed to fetch heart rate data', e);
            throw e;
        }
    }
};
