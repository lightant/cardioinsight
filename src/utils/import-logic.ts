import { HeartRateRecord } from '../types';
import { format, parseISO } from 'date-fns';
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';

export interface HealthConnectExport {
    type: string;
    metadata: any;
    startTime: string;
    endTime: string;
    samples: {
        time: string;
        beatsPerMinute: number;
    }[];
}

export const ImportLogic = {
    parseHtmlFile(htmlContent: string): HeartRateRecord[] {
        try {
            // Extract the JSON content from the <pre> tag
            const preMatch = htmlContent.match(/<pre>([\s\S]*?)<\/pre>/);
            if (!preMatch || !preMatch[1]) {
                throw new Error('No JSON data found in HTML file');
            }

            const jsonContent = preMatch[1];
            const rawData: HealthConnectExport[] = JSON.parse(jsonContent);

            const records: HeartRateRecord[] = [];

            rawData.forEach(series => {
                if (series.type === 'HeartRateSeries' && series.samples && series.samples.length > 0) {
                    series.samples.forEach(sample => {
                        const dateObj = parseISO(sample.time);
                        records.push({
                            date: format(dateObj, 'd MMM'), // "18 Nov"
                            fullDate: format(dateObj, 'EEE d MMM'), // "Thu 20 Nov"
                            timeRange: format(dateObj, 'HH:mm'), // "20:00"
                            minHr: sample.beatsPerMinute,
                            maxHr: sample.beatsPerMinute,
                            avgHr: sample.beatsPerMinute,
                            tag: '',
                            notes: 'Imported from Health Connect'
                        });
                    });
                }
            });

            return records;
        } catch (e) {
            console.error('Failed to parse import file', e);
            throw e;
        }
    },

    async saveSimplifiedData(records: HeartRateRecord[]): Promise<void> {
        try {
            // Aggregate by hour (0-23)
            // User Request: "only take the higest and lowest HR per hour"
            // We group by full Date + Hour to handle multi-day imports correctly.
            const aggregated = new Map<string, {
                date: string; fullDate: string; hour: number;
                min: number; max: number; sum: number; count: number
            }>();

            records.forEach(r => {
                // r.timeRange is "HH:mm".
                const [hStr] = r.timeRange.split(':');
                const h = parseInt(hStr, 10);

                if (!isNaN(h)) {
                    const key = `${r.fullDate}-${h}`; // e.g., "Thu 20 Nov-22"

                    if (!aggregated.has(key)) {
                        aggregated.set(key, {
                            date: r.date,
                            fullDate: r.fullDate,
                            hour: h,
                            min: 1000,
                            max: 0,
                            sum: 0,
                            count: 0
                        });
                    }

                    const entry = aggregated.get(key)!;
                    entry.min = Math.min(entry.min, r.minHr);
                    entry.max = Math.max(entry.max, r.maxHr);
                    entry.sum += r.avgHr || r.minHr;
                    entry.count++;
                }
            });

            const simplified = Array.from(aggregated.values()).map(a => ({
                d: a.date,
                fd: a.fullDate,
                tr: `${a.hour.toString().padStart(2, '0')}:00`, // Store simple hour start
                mn: a.min,
                mx: a.max,
                av: Math.round(a.sum / a.count)
            }));

            await Filesystem.writeFile({
                path: 'simplified_hr_data.json',
                data: JSON.stringify(simplified),
                directory: Directory.Data,
                encoding: Encoding.UTF8
            });
            console.log('Saved simplified data (aggregated hourly):', JSON.stringify(simplified, null, 2));
        } catch (e) {
            console.error('Failed to save simplified data', e);
        }
    },

    async loadSimplifiedData(): Promise<HeartRateRecord[]> {
        try {
            const result = await Filesystem.readFile({
                path: 'simplified_hr_data.json',
                directory: Directory.Data,
                encoding: Encoding.UTF8
            });

            const raw = JSON.parse(result.data as string);
            return raw.map((r: any) => ({
                date: r.d,
                fullDate: r.fd,
                timeRange: r.tr,
                minHr: r.mn,
                maxHr: r.mx,
                avgHr: r.av,
                tag: '',
                notes: 'Loaded from cache'
            }));
        } catch (e) {
            console.log('No saved data found or load failed');
            return [];
        }
    }
};
