/**
 * Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
 * All rights reserved.
 */
import { HeartRateRecord } from '../types';
import { ResponsiveContainer, BarChart, Bar, YAxis, Cell } from 'recharts';
import { useTranslation } from 'react-i18next';
import { enUS, zhCN, zhTW } from 'date-fns/locale';
import { getLocalizedDate } from '../utils/date-formatter';

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
    const { t, i18n } = useTranslation();
    const dateLocale = i18n.language === 'zh-CN' ? zhCN : i18n.language === 'zh-TW' ? zhTW : enUS;
    const isChinese = i18n.language.startsWith('zh');

    // Generate 24h grid (24 hours) for the Daily Chart
    const fullDayData = new Array(24).fill(null).map((_, i) => ({
        hourIndex: i,
        range: [0, 0] as [number, number],
        avg: 0,
        hasData: false
    }));

    stats.records.forEach(r => {
        // Parse "HH:mm" from timeRange to get hour
        const [hStr] = r.timeRange.split(':');
        const h = parseInt(hStr, 10);

        if (!isNaN(h) && h >= 0 && h < 24) {
            fullDayData[h] = {
                hourIndex: h,
                range: [r.minHr, r.maxHr],
                avg: r.avgHr || (r.minHr + r.maxHr) / 2,
                hasData: true
            };
        }
    });

    const chartData = fullDayData;

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
            <div className="mb-3">
                <h4 className="font-bold text-lg text-gray-800 dark:text-white mb-2">{getLocalizedDate(stats.date, t, dateLocale, isChinese)}</h4>
                <div className="flex gap-4">
                    <div className="flex flex-col">
                        <span className="text-[10px] uppercase text-gray-500 dark:text-gray-400 font-semibold">{t('avgHr')}</span>
                        <span className="text-lg font-bold text-gray-800 dark:text-white">{stats.avg} <span className="text-[10px] font-normal text-gray-400">{t('bpm')}</span></span>
                    </div>
                    <div className="flex flex-col">
                        <span className="text-[10px] uppercase text-gray-500 dark:text-gray-400 font-semibold">{t('minHr')}</span>
                        <span className="text-lg font-bold text-blue-500">{stats.min} <span className="text-[10px] font-normal text-gray-400">{t('bpm')}</span></span>
                    </div>
                    <div className="flex flex-col">
                        <span className="text-[10px] uppercase text-gray-500 dark:text-gray-400 font-semibold">{t('peak')}</span>
                        <span className="text-lg font-bold text-red-500">{stats.max} <span className="text-[10px] font-normal text-gray-400">{t('bpm')}</span></span>
                    </div>
                </div>
            </div>

            {/* Sparkline - Daily Chart */}
            <div className="h-16 w-full">
                <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chartData}>
                        <Bar
                            dataKey="range"
                            barSize={6}
                            radius={[10, 10, 10, 10]}
                            isAnimationActive={false}
                        >
                            {
                                chartData.map((entry, index) => (
                                    <Cell
                                        key={`cell-${index}`}
                                        fill={entry.hasData ? getZoneColor(entry.range[1]) : 'transparent'}
                                    />
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
