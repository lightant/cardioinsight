import { HeartRateRecord } from '../types';
import { format } from 'date-fns';

interface HealthConnectSample {
    time: string | Date;
    beatsPerMinute: number;
}

interface HealthConnectRecord {
    startTime: string | Date;
    endTime: string | Date;
    samples: HealthConnectSample[];
}

export const adaptHealthConnectData = (records: HealthConnectRecord[]): HeartRateRecord[] => {
    // 1. Flatten all samples
    const allSamples: HealthConnectSample[] = records.flatMap(r => r.samples);

    // 2. Group by day
    const groups: Record<string, HealthConnectSample[]> = {};

    allSamples.forEach(sample => {
        const date = new Date(sample.time);
        // Group by Hour to show hourly range in charts
        const key = format(date, 'yyyy-MM-dd HH');
        if (!groups[key]) {
            groups[key] = [];
        }
        groups[key].push(sample);
    });

    // 3. Convert groups to HeartRateRecord
    const adaptedRecords: HeartRateRecord[] = Object.entries(groups).map(([_, samples]) => {
        // Sort samples by time (ascending for calculation, but we might want descending for display?)
        // The app seems to expect records sorted by date, but within a record, it's a summary.
        samples.sort((a, b) => new Date(a.time).getTime() - new Date(b.time).getTime());

        const hrs = samples.map(s => s.beatsPerMinute);
        const minHr = Math.min(...hrs);
        const maxHr = Math.max(...hrs);
        const avgHr = Math.round(hrs.reduce((a, b) => a + b, 0) / hrs.length);

        const startTime = new Date(samples[0].time);
        const endTime = new Date(samples[samples.length - 1].time);

        const fullDate = format(startTime, 'yyyy-MM-dd HH:mm');
        const timeRange = `${format(startTime, 'HH:mm')} - ${format(endTime, 'HH:mm')}`;

        return {
            date: format(startTime, 'yyyy-MM-dd'),
            fullDate: fullDate,
            timeRange: timeRange,
            minHr,
            maxHr,
            avgHr,
            tag: 'Health Connect',
            notes: `Imported ${samples.length} samples`
        };
    });

    // Better sort:
    adaptedRecords.sort((a, b) => {
        // Parse "EEE d MMM HH:mm" back to date. 
        // This is tricky without year. 
        // Let's assume current year for simplicity as the parser does.
        const dateA = parseDateStr(a.fullDate);
        const dateB = parseDateStr(b.fullDate);
        return dateB.getTime() - dateA.getTime();
    });

    return adaptedRecords;
};

const parseDateStr = (dateStr: string): Date => {
    try {
        let currentYear = new Date().getFullYear();
        // "Thu 20 Nov 20:00" -> "20 Nov 2025 20:00"
        const parts = dateStr.split(' ');
        // parts[0]=Thu, parts[1]=20, parts[2]=Nov, parts[3]=20:00

        // Construct
        let date = new Date(`${parts[1]} ${parts[2]} ${currentYear} ${parts[3]}`);

        // If future, subtract year
        if (date > new Date()) {
            currentYear -= 1;
            date = new Date(`${parts[1]} ${parts[2]} ${currentYear} ${parts[3]}`);
        }

        return date;
    } catch {
        return new Date();
    }
};
