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
        } catch (e) {
            console.error('Permission request failed', e);
            return false;
        }
    },

    async getHeartRateData(startTime: Date, endTime: Date): Promise<any[]> {
        if (Capacitor.getPlatform() !== 'android') return [];
        try {
            const result = await HealthConnect.readRecords({
                type: 'HeartRateSeries',
                timeRangeFilter: {
                    type: 'between',
                    startTime: startTime,
                    endTime: endTime
                }
            });
            return result.records || [];
        } catch (e) {
            console.error('Failed to fetch heart rate data', e);
            throw e;
        }
    }
};
