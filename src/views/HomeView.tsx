import { useTranslation } from 'react-i18next';
import { enUS, zhCN, zhTW } from 'date-fns/locale';
import { getLocalizedDate } from '../utils/date-formatter';
import { AppData, HeartRateRecord } from '../types';
import HRChart from '../components/HRChart';
import DailyCard from '../components/DailyCard';
import { ChartPoint } from '../utils/aggregator';
import { User, Activity, Edit2, Upload } from 'lucide-react';
import { calculateAge } from '../utils/parser';

interface Props {
    data: AppData | null;
    profile: AppData['profile'];
    stats: { avg: number; min: number; peak: number };
    dailyGroups: { date: string; min: number; max: number; avg: number; resting?: number; records: HeartRateRecord[] }[];
    visibleCount: number;
    userMaxHr: number;
    selectedMonth: string;
    selectedWeek: number | null;
    selectedDay: string | null;
    availableMonths: { value: string; label: string }[];
    availableWeeks: { weekNum: number; label: string }[];
    displayChartData: ChartPoint[];
    onSelectMonth: (month: string) => void;
    onSelectWeek: (week: number | null) => void;
    onSelectDay: (day: string | null) => void;
    onEditProfile: () => void;
    onFileUpload: (event: React.ChangeEvent<HTMLInputElement>) => void;
}

export default function HomeView({
    data,
    profile,
    stats,
    dailyGroups,
    visibleCount,
    userMaxHr,
    selectedMonth,
    selectedWeek,
    selectedDay,
    availableMonths,
    availableWeeks,
    displayChartData,
    onSelectMonth,
    onSelectWeek,
    onSelectDay,
    onEditProfile,
    onFileUpload
}: Props) {
    const { t, i18n } = useTranslation();
    const dateLocale = i18n.language === 'zh-CN' ? zhCN : i18n.language === 'zh-TW' ? zhTW : enUS;
    const isChinese = i18n.language.startsWith('zh');

    if (!data) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[70vh] text-center px-6 space-y-6">
                <div className="w-24 h-24 bg-gradient-to-br from-cardio-orange to-red-500 rounded-3xl flex items-center justify-center shadow-xl shadow-orange-200 dark:shadow-none mb-4 transform rotate-3">
                    <Activity size={48} className="text-white" />
                </div>
                <div>
                    <h1 className="text-3xl font-bold text-gray-800 dark:text-white mb-2">{t('welcomeTitle')}</h1>
                    <p className="text-gray-500 dark:text-gray-400 max-w-xs mx-auto">
                        {t('welcomeSubtitle')}
                    </p>
                </div>

                <label className="flex flex-col items-center gap-4 p-6 bg-white dark:bg-gray-800 rounded-2xl shadow-lg cursor-pointer hover:scale-[1.02] transition-transform border-2 border-dashed border-gray-200 dark:border-gray-700 w-full max-w-xs">
                    <div className="w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-300">
                        <Upload size={32} />
                    </div>
                    <div className="text-center">
                        <h3 className="font-semibold text-gray-800 dark:text-white">{t('import')}</h3>
                        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{t('importHint')}</p>
                    </div>
                    <input type="file" accept=".html" onChange={onFileUpload} className="hidden" />
                </label>
            </div>
        );
    }

    return (
        <div className="space-y-6 pb-24">
            {/* Profile Header */}
            <div className="flex items-center justify-between bg-white dark:bg-gray-800 p-4 rounded-2xl shadow-sm">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white shadow-md">
                        <User size={24} />
                    </div>
                    <div>
                        <div className="text-xs text-gray-500 dark:text-gray-400 uppercase font-medium">{t('welcomeBack')}</div>
                        <div className="text-xl font-bold text-gray-800 dark:text-white">{profile.name}</div>
                        <div className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                            {calculateAge(profile.dob)} {t('years')} • {profile.height || '-'} • {profile.weight || '-'}
                        </div>
                    </div>
                </div>
                <button
                    onClick={onEditProfile}
                    className="p-2 text-gray-400 hover:text-cardio-orange hover:bg-gray-100 dark:hover:bg-gray-700 rounded-full transition-colors"
                >
                    <Edit2 size={20} />
                </button>
            </div>

            {/* Month Selector */}
            <div className="flex overflow-x-auto gap-2 pb-2 scrollbar-hide">
                <button
                    className={`px-4 py-2 rounded-full whitespace-nowrap transition-colors ${!selectedMonth ? 'bg-cardio-orange text-white' : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 shadow-sm'}`}
                    onClick={() => onSelectMonth('')}
                >
                    {t('allTime')}
                </button>
                {availableMonths.map(m => (
                    <button
                        key={m.value}
                        className={`px-4 py-2 rounded-full whitespace-nowrap transition-colors ${selectedMonth === m.value ? 'bg-cardio-orange text-white' : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 shadow-sm'}`}
                        onClick={() => onSelectMonth(m.value)}
                    >
                        {m.label}
                    </button>
                ))}
            </div>

            {/* Week Selector */}
            {selectedMonth && (
                <div className="flex overflow-x-auto gap-2 pb-2 scrollbar-hide">
                    <button
                        className={`px-4 py-1 text-sm rounded-full whitespace-nowrap transition-colors ${selectedWeek === null ? 'bg-gray-800 dark:bg-gray-600 text-white' : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300'}`}
                        onClick={() => onSelectWeek(null)}
                    >
                        {t('allWeeks')}
                    </button>
                    {availableWeeks.map(w => (
                        <button
                            key={w.weekNum}
                            className={`px-4 py-1 text-sm rounded-full whitespace-nowrap transition-colors ${selectedWeek === w.weekNum ? 'bg-gray-800 dark:bg-gray-600 text-white' : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300'}`}
                            onClick={() => onSelectWeek(w.weekNum)}
                        >
                            {w.label}
                        </button>
                    ))}
                </div>
            )}

            {/* Stats Cards */}
            <div className="grid grid-cols-3 gap-4">
                <div className="bg-white dark:bg-gray-800 p-4 rounded-2xl shadow-sm text-center transition-colors">
                    <div className="text-xs text-gray-500 dark:text-gray-400 uppercase mb-1">{t('avgHr')}</div>
                    <div className="text-2xl font-bold text-gray-800 dark:text-white">{stats.avg}</div>
                    <div className="text-xs text-gray-400">{t('bpm')}</div>
                </div>
                <div className="bg-white dark:bg-gray-800 p-4 rounded-2xl shadow-sm text-center transition-colors">
                    <div className="text-xs text-gray-500 dark:text-gray-400 uppercase mb-1">{t('minHr')}</div>
                    <div className="text-2xl font-bold text-blue-500">{stats.min}</div>
                    <div className="text-xs text-gray-400">{t('bpm')}</div>
                </div>
                <div className="bg-white dark:bg-gray-800 p-4 rounded-2xl shadow-sm text-center transition-colors">
                    <div className="text-xs text-gray-500 dark:text-gray-400 uppercase mb-1">{t('peak')}</div>
                    <div className="text-2xl font-bold text-red-500">{stats.peak}</div>
                    <div className="text-xs text-gray-400">{t('bpm')}</div>
                </div>
            </div>

            {/* Chart Section */}
            <div className="bg-white dark:bg-gray-800 p-4 rounded-2xl shadow-sm transition-colors">
                <div className="flex justify-between items-center mb-4">
                    <h3 className="font-semibold text-gray-700 dark:text-gray-200">
                        {selectedDay ? `${t('hrTrend')} - ${getLocalizedDate(selectedDay, t, dateLocale, isChinese)}` :
                            selectedMonth ? `${t('hrTrend')} - ${availableMonths.find(m => m.value === selectedMonth)?.label || selectedMonth}` :
                                t('hrTrend')}
                    </h3>
                    {selectedDay && (
                        <button
                            onClick={() => onSelectDay(null)}
                            className="text-xs bg-gray-200 dark:bg-gray-700 px-2 py-1 rounded-full text-gray-600 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                        >
                            {t('clearSelection')}
                        </button>
                    )}
                </div>
                <HRChart data={displayChartData} maxHr={userMaxHr} />
            </div>

            {/* Daily List */}
            <div className="space-y-4">
                <h3 className="font-semibold text-gray-700 dark:text-gray-200">{t('dailyRecords')}</h3>
                {
                    dailyGroups.slice(0, visibleCount).map((group, i) => (
                        <DailyCard
                            key={i}
                            stats={group}
                            maxHr={userMaxHr}
                            onClick={() => {
                                onSelectDay(group.date);
                                window.scrollTo({ top: 0, behavior: 'smooth' });
                            }}
                        />
                    ))
                }
            </div >
        </div >
    );
}
