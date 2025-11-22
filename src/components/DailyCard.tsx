import { HeartRateRecord } from '../types';
import { ResponsiveContainer, BarChart, Bar, YAxis, Cell } from 'recharts';

interface DailyStats {
    date: string;
    min: number;
    max: number;
    avg: number;
    resting?: number;
    records: HeartRateRecord[];
}

interface Props {
    stats: DailyStats;
    maxHr: number;
    onClick: () => void;
}

export default function DailyCard({ stats, maxHr, onClick }: Props) {
    const chartData = stats.records.map((r, i) => ({
        i,
        range: [r.minHr, r.maxHr],
        avg: r.avgHr || (r.minHr + r.maxHr) / 2
    }));

    const getZoneColor = (val: number) => {
        const pct = val / maxHr;
        if (pct >= 0.9) return '#B91C1C'; // Zone 5 - Red
        if (pct >= 0.8) return '#F97316'; // Zone 4 - Orange
        if (pct >= 0.7) return '#EAB308'; // Zone 3 - Yellow
        if (pct >= 0.6) return '#65A30D'; // Zone 2 - Green
        return '#3B82F6'; // Zone 1 - Blue
    };

    return (
        <div onClick={onClick} className="glass p-4 rounded-2xl card-hover mb-4 cursor-pointer transition-transform active:scale-[0.99]">
            <div className="flex justify-between items-start mb-4">
                <div>
                    <h4 className="font-bold text-lg text-gray-800 dark:text-white">{stats.date}</h4>
                    <div className="text-sm text-gray-500 dark:text-gray-400 flex gap-3 mt-1">
                        <span>Avg: {stats.avg}</span>
                        {stats.resting && <span className="text-blue-500 font-medium">Resting: {stats.resting}</span>}
                    </div>
                </div>
                <div className="text-right">
                    <div className="text-xl font-bold text-gray-800 dark:text-white">{stats.min}-{stats.max} <span className="text-xs font-normal text-gray-400">bpm</span></div>
                </div>
            </div>

            {/* Sparkline */}
            <div className="h-16 w-full">
                <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chartData}>
                        <Bar dataKey="range" radius={[4, 4, 4, 4]} barSize={4}>
                            {
                                chartData.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={getZoneColor(entry.range[1])} />
                                ))
                            }
                        </Bar>
                        <YAxis domain={['dataMin - 5', 'dataMax + 5']} hide />
                    </BarChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
}
