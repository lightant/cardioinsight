import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ReferenceDot, ReferenceLine, Cell } from 'recharts';
import { ChartPoint } from '../utils/aggregator';
import { useTranslation } from 'react-i18next';
import { enUS, zhCN, zhTW } from 'date-fns/locale';
import { getLocalizedDate } from '../utils/date-formatter';


interface Props {
    data: ChartPoint[];
    maxHr: number;
}

const CustomTooltip = ({ active, payload }: any) => {
    const { t, i18n } = useTranslation();
    const dateLocale = i18n.language === 'zh-CN' ? zhCN : i18n.language === 'zh-TW' ? zhTW : enUS;
    const isChinese = i18n.language.startsWith('zh');

    if (active && payload && payload.length) {
        const data = payload[0].payload;
        // Use full date stored in data.date if available, otherwise fallback to label
        const displayDate = data.date ? getLocalizedDate(data.date, t, dateLocale, isChinese) : data.label;

        return (
            <div className="bg-white dark:bg-gray-800 p-3 rounded-lg shadow-lg border border-gray-100 dark:border-gray-700">
                <p className="font-bold text-gray-700 dark:text-gray-200 mb-2">{displayDate}</p>
                <p className="text-sm text-gray-600 dark:text-gray-300">
                    <span className="font-medium">{t('range')}:</span> {data.min} - {data.max} {t('bpm')}
                </p>
                <p className="text-sm text-cardio-orange font-medium mt-1">
                    {t('avgHr')}: {data.avg} {t('bpm')}
                </p>
            </div>
        );
    }
    return null;
};

export default function HRChart({ data, maxHr }: Props) {
    const { t } = useTranslation();


    const getZoneColor = (val: number) => {
        const pct = val / maxHr;
        if (pct >= 0.9) return '#B91C1C'; // Zone 5 - Red
        if (pct >= 0.8) return '#F97316'; // Zone 4 - Orange
        if (pct >= 0.7) return '#EAB308'; // Zone 3 - Yellow
        if (pct >= 0.6) return '#65A30D'; // Zone 2 - Green
        return '#3B82F6'; // Zone 1 - Blue
    };

    // Find global max and min points
    const globalMaxVal = data.length ? Math.max(...data.map(d => d.max)) : 0;
    const minValues = data.map(d => d.min).filter(v => v > 0);
    const globalMinVal = minValues.length ? Math.min(...minValues) : 0;

    const maxPoint = data.find(d => d.max === globalMaxVal);
    const minPoint = data.find(d => d.min === globalMinVal);

    // Prepare data for BarChart (range)
    // Recharts Bar can take [min, max] as value
    const chartData = data.map(d => ({
        ...d,
        range: [d.min, d.max]
    }));

    return (
        <div>
            <div className="h-64 w-full">
                <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chartData} margin={{ top: 20, right: 0, left: -20, bottom: 0 }}>
                        <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e5e7eb" />
                        <XAxis
                            dataKey="label"
                            tick={{ fontSize: 10, fill: '#9ca3af' }}
                            tickLine={false}
                            axisLine={false}
                            interval="preserveStartEnd"
                        />
                        <YAxis
                            domain={[globalMinVal > 0 ? globalMinVal - 10 : 0, globalMaxVal + 10]}
                            tick={{ fontSize: 10, fill: '#9ca3af' }}
                            tickLine={false}
                            axisLine={false}
                        />
                        <Tooltip content={<CustomTooltip />} cursor={{ fill: 'transparent' }} />

                        {globalMaxVal > 0 && (
                            <ReferenceLine y={globalMaxVal} stroke="#ef4444" strokeDasharray="3 3" opacity={0.5} />
                        )}
                        {globalMinVal > 0 && (
                            <ReferenceLine y={globalMinVal} stroke="#3b82f6" strokeDasharray="3 3" opacity={0.5} />
                        )}

                        <Bar dataKey="range" radius={[10, 10, 10, 10]} barSize={data.length > 20 ? 6 : 12} animationDuration={300} animationEasing="ease-out">
                            {
                                chartData.map((entry, index) => {
                                    return <Cell key={`cell-${index}`} fill={getZoneColor(entry.max)} />;
                                })
                            }
                        </Bar>

                        {maxPoint && (
                            <ReferenceDot
                                x={maxPoint.label}
                                y={maxPoint.max}
                                r={4}
                                fill="#ef4444"
                                stroke="white"
                                strokeWidth={2}
                                isFront={true}
                                label={{ value: `${maxPoint.max}`, position: 'top', fill: '#ef4444', fontSize: 12, fontWeight: 'bold' }}
                            />
                        )}
                        {minPoint && (
                            <ReferenceDot
                                x={minPoint.label}
                                y={minPoint.min}
                                r={4}
                                fill="#3b82f6"
                                stroke="white"
                                strokeWidth={2}
                                isFront={true}
                                label={{ value: `${minPoint.min}`, position: 'bottom', fill: '#3b82f6', fontSize: 12, fontWeight: 'bold' }}
                            />
                        )}
                    </BarChart>
                </ResponsiveContainer>
            </div>
            <div className="flex justify-center gap-4 mt-2 text-xs text-gray-500 dark:text-gray-400 flex-wrap">
                <div className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-[#B91C1C]"></div> {t('zone')} 5 ({'>'}90%)</div>
                <div className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-[#F97316]"></div> {t('zone')} 4 (80-90%)</div>
                <div className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-[#EAB308]"></div> {t('zone')} 3 (70-80%)</div>
                <div className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-[#65A30D]"></div> {t('zone')} 2 (60-70%)</div>
                <div className="flex items-center gap-1"><div className="w-2 h-2 rounded-full bg-[#3B82F6]"></div> {t('zone')} 1 ({'<'}60%)</div>
            </div>
        </div>
    );
}
