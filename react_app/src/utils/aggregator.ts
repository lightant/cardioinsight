/**
 * Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
 * All rights reserved.
 */
import { HeartRateRecord } from '../types';


export interface ChartPoint {
    id: string;
    label: string;
    min: number;
    max: number;
    avg: number;
    date: string; // For reference
    originalData?: any;
}

export const aggregateData = (
    records: HeartRateRecord[],
    view: 'day' | 'week' | 'month' | 'all'
): ChartPoint[] => {
    if (records.length === 0) return [];

    if (view === 'day') {
        // Records are already per time-range. Just map them.
        // Assuming records are for a single day.
        // Sort by time.
        return [...records].reverse().map((r, i) => ({
            id: i.toString(),
            label: r.timeRange,
            min: r.minHr,
            max: r.maxHr,
            avg: r.avgHr || Math.round((r.minHr + r.maxHr) / 2),
            date: r.date
        }));
    }

    if (view === 'week' || view === 'month' || view === 'all') {
        // Group by Day (e.g., "Mon", "Tue", "18 Nov")
        const groups: Record<string, HeartRateRecord[]> = {};
        records.forEach(r => {
            // Use r.date as the key (e.g., "Today", "Yesterday", "18 Nov")
            // This assumes r.date is unique for each day in the dataset
            if (!groups[r.date]) groups[r.date] = [];
            groups[r.date].push(r);
        });

        return Object.entries(groups).map(([date, group], i) => {
            const mins = group.map(r => r.minHr);
            const maxs = group.map(r => r.maxHr);
            const avgs = group.map(r => r.avgHr || 0);
            return {
                id: i.toString(),
                label: date,
                min: Math.min(...mins),
                max: Math.max(...maxs),
                avg: Math.round(avgs.reduce((a, b) => a + b, 0) / avgs.length),
                date: date
            };
        }).reverse(); // Assuming input was reverse chronological
    }

    return [];
};
