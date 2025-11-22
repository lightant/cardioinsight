import { useState, useEffect, useMemo } from 'react';
import { parseHtmlData, calculateAge, parseRecordDate } from './utils/parser';
import { AppData, HeartRateRecord } from './types';
import { Upload, Settings, FileText, User, Activity } from 'lucide-react';
import { format, getWeek, startOfWeek } from 'date-fns';
import HRChart from './components/HRChart';
import DailyCard from './components/DailyCard';
import { useTranslation } from 'react-i18next';
import { Edit2 } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { aggregateData } from './utils/aggregator';
import { HealthService } from './services/health';
import { Capacitor } from '@capacitor/core';

function App() {
    const { t, i18n } = useTranslation();
    const [data, setData] = useState<AppData | null>(null);
    const [selectedMonth, setSelectedMonth] = useState<string>('');
    const [selectedWeek, setSelectedWeek] = useState<number | null>(null); // Week number
    const [selectedDay, setSelectedDay] = useState<string | null>(null);
    const [apiKey, setApiKey] = useState(() => localStorage.getItem('gemini_api_key') || '');
    const [showSettings, setShowSettings] = useState(false);
    const [showReport, setShowReport] = useState(false);
    const [reportContent, setReportContent] = useState('');
    const [loadingReport, setLoadingReport] = useState(false);
    const [theme, setTheme] = useState<'light' | 'dark' | 'system'>('system');
    const [showProfileEdit, setShowProfileEdit] = useState(false);
    const [editProfile, setEditProfile] = useState<Partial<AppData['profile']>>({});
    const [syncing, setSyncing] = useState(false);

    // Theme Effect
    useEffect(() => {
        const root = window.document.documentElement;
        root.classList.remove('light', 'dark');

        if (theme === 'system') {
            const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
            root.classList.add(systemTheme);
        } else {
            root.classList.add(theme);
        }
    }, [theme]);

    const handleSync = async () => {
        if (Capacitor.getPlatform() !== 'android') {
            alert('Health Connect sync is only available on Android.');
            return;
        }
        setSyncing(true);
        try {
            const available = await HealthService.checkAvailability();
            if (!available) {
                alert('Health Connect is not available on this device.');
                setSyncing(false);
                return;
            }
            const permitted = await HealthService.requestPermissions();
            if (!permitted) {
                alert('Permissions not granted.');
                setSyncing(false);
                return;
            }

            const end = new Date();
            const start = new Date();
            start.setDate(start.getDate() - 30);

            const records = await HealthService.getHeartRateData(start, end);
            if (records.length > 0) {
                alert(`Synced ${records.length} records from Health Connect!`);
                // TODO: Implement merging logic with existing data
            } else {
                alert('No recent heart rate data found in Health Connect.');
            }
        } catch (e) {
            console.error(e);
            alert('Sync failed.');
        } finally {
            setSyncing(false);
        }
    };

    // Handle file upload
    const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (e) => {
                const content = e.target?.result as string;
                const parsed = parseHtmlData(content);
                setData(parsed);
                // Set default month to latest
                if (parsed.records.length > 0) {
                    const latestDate = parseRecordDate(parsed.records[0].fullDate);
                    setSelectedMonth(format(latestDate, 'MMM yyyy'));
                }
            };
            reader.readAsText(file);
        }
    };

    // Filter data
    const filteredRecords = useMemo(() => {
        if (!data) return [];
        let records = data.records;

        // Filter by month
        if (selectedMonth) {
            records = records.filter(r => {
                const date = parseRecordDate(r.fullDate);
                return format(date, 'MMM yyyy') === selectedMonth;
            });
        }

        // Filter by week
        if (selectedWeek !== null) {
            records = records.filter(r => {
                const date = parseRecordDate(r.fullDate);
                return getWeek(date) === selectedWeek;
            });
        }

        // If All Time (no month selected), limit to latest 30 days
        if (!selectedMonth && !selectedWeek) {
            const uniqueDates = Array.from(new Set(records.map(r => r.date)));
            if (uniqueDates.length > 30) {
                const latest30Dates = uniqueDates.slice(0, 30);
                records = records.filter(r => latest30Dates.includes(r.date));
            }
        }

        return records;
    }, [data, selectedMonth, selectedWeek]);

    // Stats
    const stats = useMemo(() => {
        if (filteredRecords.length === 0) return { avg: 0, resting: 0, peak: 0 };

        const avgs = filteredRecords.map(r => r.avgHr || 0).filter(v => v > 0);
        const avg = avgs.length ? Math.round(avgs.reduce((a, b) => a + b, 0) / avgs.length) : 0;

        const resting = filteredRecords.filter(r => r.tag === 'Resting').map(r => r.minHr);
        const avgResting = resting.length ? Math.round(resting.reduce((a, b) => a + b, 0) / resting.length) : 0;

        const peaks = filteredRecords.map(r => r.maxHr);
        const peak = peaks.length ? Math.max(...peaks) : 0;

        return { avg, resting: avgResting, peak };
    }, [filteredRecords]);

    // Available Months
    const availableMonths = useMemo(() => {
        if (!data) return [];
        const months = new Set<string>();
        data.records.forEach(r => {
            const date = parseRecordDate(r.fullDate);
            months.add(format(date, 'MMM yyyy'));
        });
        return Array.from(months);
    }, [data]);

    // Available Weeks in Selected Month with Start Date
    const availableWeeks = useMemo(() => {
        if (!data || !selectedMonth) return [];
        const weeksMap = new Map<number, Date>();

        data.records.forEach(r => {
            const date = parseRecordDate(r.fullDate);
            if (format(date, 'MMM yyyy') === selectedMonth) {
                const weekNum = getWeek(date);
                if (!weeksMap.has(weekNum)) {
                    // Find the start of this week based on the record's date
                    // Assuming week starts on Monday for consistency with getWeek usually
                    weeksMap.set(weekNum, startOfWeek(date, { weekStartsOn: 1 }));
                }
            }
        });

        return Array.from(weeksMap.entries())
            .sort((a, b) => a[0] - b[0])
            .map(([weekNum, startDate]) => ({
                weekNum,
                label: format(startDate, 'MMM d')
            }));
    }, [data, selectedMonth]);

    // Group by Day
    const dailyGroups = useMemo(() => {
        if (!filteredRecords.length) return [];
        const groups: Record<string, HeartRateRecord[]> = {};
        filteredRecords.forEach(r => {
            if (!groups[r.date]) groups[r.date] = [];
            groups[r.date].push(r);
        });

        return Object.entries(groups).map(([date, records]) => {
            const mins = records.map(r => r.minHr);
            const maxs = records.map(r => r.maxHr);
            const min = Math.min(...mins);
            const max = Math.max(...maxs);
            const avg = Math.round(records.reduce((a, r) => a + (r.avgHr || 0), 0) / records.length);
            const resting = records.find(r => r.tag === 'Resting')?.minHr;

            // Sort records by time (assuming they are in reverse chronological order in the file, so reverse to get chronological)
            // Actually, the file has "Today" at top (newest). So reverse them for the chart.
            const sortedRecords = [...records].reverse();

            return {
                date,
                min,
                max,
                avg,
                resting,
                records: sortedRecords
            };
        });
    }, [filteredRecords]);

    // Gemini Report Generation
    const generateReport = async () => {
        if (!apiKey) {
            alert('Please enter your Gemini API Key in settings');
            setShowSettings(true);
            return;
        }

        setLoadingReport(true);
        try {
            // Dynamic import to avoid issues if not installed yet
            const { GoogleGenerativeAI } = await import('@google/generative-ai');
            const genAI = new GoogleGenerativeAI(apiKey);
            const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

            const prompt = `
        Analyze the following heart rate data for a ${calculateAge(data?.profile.dob || '')} year old ${data?.profile.sex || 'person'}.
        Profile: ${JSON.stringify(data?.profile)}
        Stats: ${JSON.stringify(stats)}
        Recent Records (Last 20): ${JSON.stringify(filteredRecords.slice(0, 20))}
        
        Provide a cardio analysis and suggestions in a structured Markdown format.
        
        Requirements:
        1. Use a clear **Title** with an icon (e.g., 🩺 Cardio Analysis).
        2. Use **Headers** (##) for sections like "Overview", "Key Insights", "Recommendations".
        3. Use **Bold** text for important numbers and key takeaways.
        4. Use **Bullet points** for readability.
        5. Use **Icons** (emoji) for section titles to make it visually appealing.
        6. Keep paragraphs short and concise.
        7. Highlight any abnormal readings or trends.
      `;

            const result = await model.generateContent(prompt);
            const response = await result.response;
            const text = response.text();
            setReportContent(text);
            setShowReport(true);
        } catch (error) {
            console.error(error);
            alert('Failed to generate report. Check console for details.');
        } finally {
            setLoadingReport(false);
        }
    };

    // Determine chart data
    const chartData = useMemo(() => {
        if (selectedDay) {
            // Day View
            const dayRecords = filteredRecords.filter(r => r.date === selectedDay);
            return aggregateData(dayRecords, 'day');
        } else if (selectedWeek !== null) {
            // Week View (Show Days)
            return aggregateData(filteredRecords, 'week');
        } else if (selectedMonth) {
            // Month View (Show Weeks)
            return aggregateData(filteredRecords, 'month');
        } else {
            // All Time (Show Months)
            return aggregateData(filteredRecords, 'all');
        }
    }, [filteredRecords, selectedDay, selectedWeek, selectedMonth]);

    // Calculate Max HR based on age
    const userMaxHr = useMemo(() => {
        if (!data?.profile.dob) return 190; // Default to age 30 if unknown
        const age = calculateAge(data.profile.dob);
        return 220 - age;
    }, [data?.profile.dob]);

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900 pb-20 transition-colors duration-300">
            {/* Header */}
            <header className="bg-white dark:bg-gray-800 p-4 shadow-sm transition-colors duration-300">
                <div className="flex justify-between items-center mb-4">
                    <h1 className="text-2xl font-bold text-cardio-orange">{t('appTitle')}</h1>
                    <div className="flex gap-2">
                        <label className="p-2 rounded-full bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 cursor-pointer text-gray-600 dark:text-gray-300">
                            <Upload size={20} />
                            <input type="file" accept=".html" onChange={handleFileUpload} className="hidden" />
                        </label>
                        <button
                            onClick={handleSync}
                            disabled={syncing}
                            className="flex items-center gap-2 px-4 py-2 rounded-full bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 text-gray-600 dark:text-gray-300 text-sm font-medium transition-colors"
                            title="Sync with Health Connect"
                        >
                            <Activity size={18} className={syncing ? "animate-spin" : ""} />
                            <span className="hidden sm:inline">Import from Health Connect</span>
                        </button>
                        <button onClick={() => setShowSettings(!showSettings)} className="p-2 rounded-full bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 text-gray-600 dark:text-gray-300">
                            <Settings size={20} />
                        </button>
                    </div>
                </div>

                {data && (
                    <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-gray-200 dark:bg-gray-700 rounded-full flex items-center justify-center">
                            <User size={24} className="text-gray-500 dark:text-gray-400" />
                        </div>
                        <div className="flex-1">
                            <div className="flex items-center gap-2">
                                <div className="font-semibold text-lg text-gray-800 dark:text-white">{data.profile.name}</div>
                                <button
                                    onClick={() => {
                                        setEditProfile(data.profile);
                                        setShowProfileEdit(true);
                                    }}
                                    className="p-1 text-gray-400 hover:text-cardio-orange transition-colors"
                                >
                                    <Edit2 size={14} />
                                </button>
                            </div>
                            <div className="text-sm text-gray-500 dark:text-gray-400">
                                {calculateAge(data.profile.dob)} Years • {data.profile.sex || 'N/A'} • {data.profile.height || '-'} • {data.profile.weight || '-'}
                            </div>
                        </div>
                    </div>
                )}
            </header>

            {/* Settings Modal */}
            {showSettings && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 backdrop-blur-sm">
                    <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl w-full max-w-md m-4 shadow-xl">
                        <h2 className="text-xl font-bold mb-4 text-gray-800 dark:text-white">{t('settings')}</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">{t('apiKey')}</label>
                                <input
                                    type="password"
                                    value={apiKey}
                                    onChange={(e) => {
                                        setApiKey(e.target.value);
                                        localStorage.setItem('gemini_api_key', e.target.value);
                                    }}
                                    className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white focus:ring-2 focus:ring-cardio-orange focus:border-transparent"
                                    placeholder={t('enterApiKey')}
                                />
                            </div>

                            {/* Theme Switcher */}
                            <div>
                                <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">{t('theme')}</label>
                                <div className="flex gap-2">
                                    {(['light', 'dark', 'system'] as const).map((m) => (
                                        <button
                                            key={m}
                                            onClick={() => setTheme(m)}
                                            className={`px-3 py-1 rounded-lg text-sm capitalize border ${theme === m ? 'bg-cardio-orange text-white border-cardio-orange' : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300 border-gray-300 dark:border-gray-600'}`}
                                        >
                                            {t(m)}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {/* Language Switcher */}
                            <div>
                                <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">{t('language')}</label>
                                <div className="flex gap-2">
                                    {[
                                        { code: 'en', label: 'English' },
                                        { code: 'zh-CN', label: '简体中文' },
                                        { code: 'zh-TW', label: '繁體中文' }
                                    ].map((l) => (
                                        <button
                                            key={l.code}
                                            onClick={() => i18n.changeLanguage(l.code)}
                                            className={`px-3 py-1 rounded-lg text-sm border ${i18n.language === l.code ? 'bg-cardio-orange text-white border-cardio-orange' : 'bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300 border-gray-300 dark:border-gray-600'}`}
                                        >
                                            {l.label}
                                        </button>
                                    ))}
                                </div>
                            </div>

                        </div>
                        <div className="mt-6 flex justify-end">
                            <button onClick={() => setShowSettings(false)} className="px-4 py-2 bg-cardio-orange text-white rounded-lg hover:opacity-90">
                                {t('done')}
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Profile Edit Modal */}
            {showProfileEdit && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 backdrop-blur-sm">
                    <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl w-full max-w-md m-4 shadow-xl">
                        <h2 className="text-xl font-bold mb-4 text-gray-800 dark:text-white">Edit Profile</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">Name</label>
                                <input
                                    value={editProfile.name || ''}
                                    onChange={e => setEditProfile({ ...editProfile, name: e.target.value })}
                                    className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">Sex</label>
                                    <select
                                        value={editProfile.sex || ''}
                                        onChange={e => setEditProfile({ ...editProfile, sex: e.target.value })}
                                        className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white"
                                    >
                                        <option value="">Select</option>
                                        <option value="Male">Male</option>
                                        <option value="Female">Female</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">DOB</label>
                                    <input
                                        value={editProfile.dob || ''}
                                        onChange={e => setEditProfile({ ...editProfile, dob: e.target.value })}
                                        className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white"
                                        placeholder="DD MMM YYYY"
                                    />
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">Height</label>
                                    <input
                                        value={editProfile.height || ''}
                                        onChange={e => setEditProfile({ ...editProfile, height: e.target.value })}
                                        className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white"
                                        placeholder="e.g. 175cm"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">Weight</label>
                                    <input
                                        value={editProfile.weight || ''}
                                        onChange={e => setEditProfile({ ...editProfile, weight: e.target.value })}
                                        className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white"
                                        placeholder="e.g. 70kg"
                                    />
                                </div>
                            </div>
                        </div>
                        <div className="mt-6 flex justify-end gap-2">
                            <button onClick={() => setShowProfileEdit(false)} className="px-4 py-2 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg">
                                Cancel
                            </button>
                            <button
                                onClick={() => {
                                    if (data) {
                                        setData({ ...data, profile: { ...data.profile, ...editProfile } as any });
                                        setShowProfileEdit(false);
                                    }
                                }}
                                className="px-4 py-2 bg-cardio-orange text-white rounded-lg hover:opacity-90"
                            >
                                Save
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Main Content */}
            <main className="p-4 space-y-6">
                {/* Month Selector */}
                <div className="flex overflow-x-auto gap-2 pb-2 scrollbar-hide">
                    <button
                        className={`px-4 py-2 rounded-full whitespace-nowrap transition-colors ${!selectedMonth ? 'bg-cardio-orange text-white' : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 shadow-sm'}`}
                        onClick={() => {
                            setSelectedMonth('');
                            setSelectedWeek(null);
                            setSelectedDay(null);
                        }}
                    >
                        {t('allTime')}
                    </button>
                    {availableMonths.map(m => (
                        <button
                            key={m}
                            className={`px-4 py-2 rounded-full whitespace-nowrap transition-colors ${selectedMonth === m ? 'bg-cardio-orange text-white' : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 shadow-sm'}`}
                            onClick={() => {
                                setSelectedMonth(m);
                                setSelectedWeek(null);
                                setSelectedDay(null);
                            }}
                        >
                            {m}
                        </button>
                    ))}
                </div>

                {/* Week Selector */}
                {selectedMonth && (
                    <div className="flex overflow-x-auto gap-2 pb-2 scrollbar-hide">
                        <button
                            className={`px-4 py-1 text-sm rounded-full whitespace-nowrap transition-colors ${selectedWeek === null ? 'bg-gray-800 dark:bg-gray-600 text-white' : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300'}`}
                            onClick={() => setSelectedWeek(null)}
                        >
                            {t('allWeeks')}
                        </button>
                        {availableWeeks.map(w => (
                            <button
                                key={w.weekNum}
                                className={`px-4 py-1 text-sm rounded-full whitespace-nowrap transition-colors ${selectedWeek === w.weekNum ? 'bg-gray-800 dark:bg-gray-600 text-white' : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-300'}`}
                                onClick={() => setSelectedWeek(w.weekNum)}
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
                        <div className="text-xs text-gray-500 dark:text-gray-400 uppercase mb-1">{t('resting')}</div>
                        <div className="text-2xl font-bold text-blue-500">{stats.resting}</div>
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
                            {selectedDay ? `${t('hrTrend')} - ${selectedDay}` : t('hrTrend')}
                        </h3>
                        {selectedDay && (
                            <button
                                onClick={() => setSelectedDay(null)}
                                className="text-xs bg-gray-200 dark:bg-gray-700 px-2 py-1 rounded-full text-gray-600 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                            >
                                Clear Selection
                            </button>
                        )}
                    </div>
                    <HRChart data={chartData} maxHr={userMaxHr} />
                </div>

                {/* Gemini Report Button */}
                <button
                    onClick={generateReport}
                    disabled={loadingReport}
                    className="w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white p-4 rounded-2xl font-semibold flex items-center justify-center gap-2 shadow-lg hover:opacity-90 transition-opacity"
                >
                    {loadingReport ? t('generating') : (
                        <>
                            <FileText size={20} />
                            {t('generateReport')}
                        </>
                    )}
                </button>
                {/* Daily List */}
                <div className="space-y-4">
                    <h3 className="font-semibold text-gray-700 dark:text-gray-200">{t('dailyRecords')}</h3>
                    {dailyGroups.map((group, i) => (
                        <DailyCard
                            key={i}
                            stats={group}
                            maxHr={userMaxHr}
                            onClick={() => {
                                setSelectedDay(group.date);
                                window.scrollTo({ top: 0, behavior: 'smooth' });
                            }}
                        />
                    ))}
                </div>
            </main >

            {/* Report Modal */}
            {
                showReport && (
                    <div className="fixed inset-0 bg-white dark:bg-gray-900 z-50 overflow-y-auto">
                        <div className="p-4">
                            <div className="flex justify-between items-center mb-4">
                                <button onClick={() => setShowReport(false)} className="text-blue-600 dark:text-blue-400 font-medium">
                                    ← {t('back')}
                                </button>
                                <button
                                    onClick={() => {
                                        const blob = new Blob([reportContent], { type: 'text/markdown' });
                                        const url = URL.createObjectURL(blob);
                                        const a = document.createElement('a');
                                        a.href = url;
                                        a.download = `cardio_report_${format(new Date(), 'yyyyMMdd_HHmmss')}.md`;
                                        document.body.appendChild(a);
                                        a.click();
                                        document.body.removeChild(a);
                                        URL.revokeObjectURL(url);
                                    }}
                                    className="px-4 py-2 bg-green-600 text-white rounded-lg text-sm hover:bg-green-700"
                                >
                                    {t('saveToFile')}
                                </button>
                            </div>
                            <div className="prose dark:prose-invert max-w-none">
                                <ReactMarkdown className="font-sans text-sm text-gray-800 dark:text-gray-200">
                                    {reportContent}
                                </ReactMarkdown>
                            </div>
                        </div>
                    </div>
                )
            }
        </div >
    );
}

export default App;
