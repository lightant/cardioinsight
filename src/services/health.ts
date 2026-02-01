/**
 * Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
 * All rights reserved.
 */
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
            // Fetch all data for the requested range using pagination
            // This is much faster than fetching day-by-day as it reduces the number of bridge calls
            // from (Days) to (TotalRecords / 1000).
            let pageToken: string | undefined = undefined;

            do {
                const result: { records: any[]; pageToken?: string } = await HealthConnect.readRecords({
                    type: 'HeartRateSeries',
                    timeRangeFilter: {
                        type: 'between',
                        startTime: startTime,
                        endTime: endTime
                    },
                    pageToken: pageToken
                });

                if (result.records) {
                    allRecords.push(...result.records);
                }

                pageToken = result.pageToken;
            } while (pageToken);

            return allRecords;
        } catch (e) {
            console.error('Failed to fetch heart rate data', e);
            throw e;
        }
    }
};
