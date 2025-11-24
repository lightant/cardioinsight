import { useState, useEffect, useMemo } from 'react';
import { parseHtmlData, calculateAge, parseRecordDate } from './utils/parser';
import { AppData, HeartRateRecord } from './types';
import { Upload, Settings, FileText, User, Activity } from 'lucide-react';
import { format, getWeek, startOfWeek } from 'date-fns';
import { enUS, zhCN, zhTW } from 'date-fns/locale';
import HRChart from './components/HRChart';
import DailyCard from './components/DailyCard';
import { useTranslation } from 'react-i18next';
import { Edit2 } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { aggregateData } from './utils/aggregator';
import { HealthService } from './services/health';
import { adaptHealthConnectData } from './utils/health-adapter';
import { Capacitor } from '@capacitor/core';
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';
import { Share } from '@capacitor/share';

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
    const [visibleCount, setVisibleCount] = useState(10);

    // Get date-fns locale
    const dateLocale = useMemo(() => {
        switch (i18n.language) {
            case 'zh-CN': return zhCN;
            case 'zh-TW': return zhTW;
            default: return enUS;
        }
    }, [i18n.language]);

    // Theme Effect
    useEffect(() => {
        const root = window.document.documentElement;
        root.classList.remove('light', 'dark');

        if (theme === 'system') {
            const systemTheme = window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
            root.classList.add(systemTheme);
        } else {
            root.classList.add(theme);
        }
    }, [theme]);

    const handleSync = async () => {
        if (Capacitor.getPlatform() !== 'android') {
            alert(t('syncAndroidOnly'));
            return;
        }
        setSyncing(true);
        try {
            const available = await HealthService.checkAvailability();
            if (!available) {
                alert(t('healthConnectNotAvailable'));
                setSyncing(false);
                return;
            }

            const permitted = await HealthService.requestPermissions();
            if (!permitted) {
                alert(t('permissionsDenied'));
                setSyncing(false);
                return;
            }

            const end = new Date();
            const start = new Date();
            start.setDate(start.getDate() - 90);

            const records = await HealthService.getHeartRateData(start, end);
            if (records.length > 0) {
                const newRecords = adaptHealthConnectData(records);

                setData(prevData => {
                    const existingRecords = prevData?.records || [];
                    // Merge and deduplicate based on fullDate/time
                    // For simplicity, we'll just append and re-sort for now, or maybe filter out duplicates?
                    // Let's just combine them.
                    const combinedRecords = [...existingRecords, ...newRecords];

                    // Sort by date descending
                    combinedRecords.sort((a, b) => {
                        // Helper to parse date string for sorting
                        const parse = (d: string) => {
                            try {
                                const parts = d.split(' ');
                                const year = new Date().getFullYear();
                                return new Date(`${parts[1]} ${parts[2]} ${year} ${parts[3] || '00:00'}`).getTime();
                            } catch { return 0; }
                        };
                        return parse(b.fullDate) - parse(a.fullDate);
                    });

                    return {
                        profile: prevData?.profile || {
                            name: 'User',
                            dob: '1990-01-01', // Default
                            activityLevel: 'Moderate',
                            sex: 'Male',
                            height: '175cm',
                            weight: '70kg'
                        },
                        records: combinedRecords
                    };
                });

                alert(t('syncedResult', { rawCount: records.length, newCount: newRecords.length }));
            } else {
                alert(t('noRecentData'));
            }
        } catch (e: any) {
            console.error(e);
            alert(t('syncFailed', { error: e.message }));
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
                    setSelectedMonth(format(latestDate, 'yyyy-MM'));
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
                return format(date, 'yyyy-MM') === selectedMonth;
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
        const months = new Map<string, string>(); // value (yyyy-MM) -> label (MMM yyyy)
        data.records.forEach(r => {
            const date = parseRecordDate(r.fullDate);
            const value = format(date, 'yyyy-MM');
            const label = format(date, 'MMM yyyy', { locale: dateLocale });
            months.set(value, label);
        });
        return Array.from(months.entries()).map(([value, label]) => ({ value, label }));
    }, [data, dateLocale]);

    // Available Weeks in Selected Month with Start Date
    const availableWeeks = useMemo(() => {
        if (!data || !selectedMonth) return [];
        const weeksMap = new Map<number, Date>();

        data.records.forEach(r => {
            const date = parseRecordDate(r.fullDate);
            if (format(date, 'yyyy-MM') === selectedMonth) {
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
                label: format(startDate, i18n.language.startsWith('zh') ? 'MMM d 日' : 'MMM d', { locale: dateLocale })
            }));
    }, [data, selectedMonth, dateLocale, i18n.language]);

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

    // Progressive Loading Effect
    useEffect(() => {
        setVisibleCount(10);
    }, [dailyGroups]);

    useEffect(() => {
        if (visibleCount < dailyGroups.length) {
            const timer = setTimeout(() => {
                setVisibleCount(prev => Math.min(prev + 10, dailyGroups.length));
            }, 100);
            return () => clearTimeout(timer);
        }
    }, [visibleCount, dailyGroups.length]);

    // Gemini Report Generation
    const generateReport = async () => {
        if (!apiKey) {
            alert(t('enterApiKey'));
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
        Respond in ${i18n.language} language.
        
        Requirements:
        1. Use a clear **Title** with an icon (e.g., 🩺 Cardio Analysis). Use a single # for the title.
        2. Use **Headers** (##) for sections like "Overview", "Key Insights", "Recommendations".
        3. Use **Bold** text for important numbers and key takeaways.
        4. Use **Bullet points** for readability.
        5. Use **Icons** (emoji) for section titles to make it visually appealing.
        6. Keep paragraphs short and concise.
        7. Highlight any abnormal readings or trends.
        8. Ensure there is a blank line between headers and content.
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
            // All Time (Show Months)
            const allData = aggregateData(filteredRecords, 'all');
            // Format labels for chart
            return allData.map(d => ({
                ...d,
                label: d.label // Already formatted in aggregateData, but we might want to localize if not already
            }));
        }
    }, [filteredRecords, selectedDay, selectedWeek, selectedMonth]);

    // Format chart data labels for display
    const displayChartData = useMemo(() => {
        return chartData.map(d => {
            let label = d.label;
            // If showing days (month view), simplify label to just day number
            if (selectedMonth && !selectedWeek && !selectedDay) {
                // Parse the full date from the record if possible, or assume label is date string
                try {
                    const date = new Date(d.label);
                    // If valid date
                    if (!isNaN(date.getTime())) {
                        label = format(date, i18n.language.startsWith('zh') ? 'd 日' : 'd', { locale: dateLocale });
                    }
                } catch (e) { }
            }
            return { ...d, label };
        });
    }, [chartData, selectedMonth, selectedWeek, selectedDay, i18n.language, dateLocale]);

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
                            <span className="hidden sm:inline">{t('import')}</span>
                        </button>
                        <button
                            onClick={async () => {
                                if (Capacitor.getPlatform() !== 'android') {
                                    alert(t('syncAndroidOnly'));
                                    return;
                                }
                                try {
                                    const end = new Date();
                                    const start = new Date();
                                    start.setDate(start.getDate() - 90);
                                    const records = await HealthService.getHeartRateData(start, end);

                                    const htmlContent = `
                                        <html>
                                        <head><title>Health Connect Debug Data</title></head>
                                        <body>
                                            <h1>Raw Health Connect Data</h1>
                                            <p>Range: ${start.toISOString()} to ${end.toISOString()}</p>
                                            <p>Count: ${records.length}</p>
                                            <pre>${JSON.stringify(records, null, 2)}</pre>
                                        </body>
                                        </html>
                                    `;

                                    // Use Filesystem to write file
                                    const fileName = `health_debug_${format(new Date(), 'yyyyMMdd_HHmmss')}.html`;
                                    const result = await Filesystem.writeFile({
                                        path: fileName,
                                        data: htmlContent,
                                        directory: Directory.Documents,
                                        encoding: Encoding.UTF8
                                    });

                                    // Use Share to let user pick where to save/send
                                    await Share.share({
                                        title: 'Health Connect Debug Data',
                                        text: 'Here is the raw debug data from Health Connect.',
                                        url: result.uri,
                                        dialogTitle: 'Export Debug Data'
                                    });
                                } catch (e: any) {
                                    alert(t('debugExportFailed', { error: e.message }));
                                }
                            }}
                            className="p-2 rounded-full bg-red-100 dark:bg-red-900 text-red-600 dark:text-red-300 hover:bg-red-200"
                            title="Debug: Export Raw Data"
                        >
                            <FileText size={20} />
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
                                {calculateAge(data.profile.dob)} {t('years')} • {t(data.profile.sex?.toLowerCase() || '') || data.profile.sex} • {data.profile.height || '-'} • {data.profile.weight || '-'}
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
                        <h2 className="text-xl font-bold mb-4 text-gray-800 dark:text-white">{t('editProfile')}</h2>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">{t('name')}</label>
                                <input
                                    value={editProfile.name || ''}
                                    onChange={e => setEditProfile({ ...editProfile, name: e.target.value })}
                                    className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">{t('sex')}</label>
                                    <select
                                        value={editProfile.sex || ''}
                                        onChange={e => setEditProfile({ ...editProfile, sex: e.target.value })}
                                        className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white"
                                    >
                                        <option value="">{t('select')}</option>
                                        <option value="Male">{t('male')}</option>
                                        <option value="Female">{t('female')}</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">{t('dob')}</label>
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
                                    <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">{t('height')}</label>
                                    <input
                                        value={editProfile.height || ''}
                                        onChange={e => setEditProfile({ ...editProfile, height: e.target.value })}
                                        className="w-full p-2 border rounded-lg bg-gray-50 dark:bg-gray-700 border-gray-300 dark:border-gray-600 text-gray-800 dark:text-white"
                                        placeholder="e.g. 175cm"
                                    />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">{t('weight')}</label>
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
                                {t('cancel')}
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
                                {t('save')}
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
                            key={m.value}
                            className={`px-4 py-2 rounded-full whitespace-nowrap transition-colors ${selectedMonth === m.value ? 'bg-cardio-orange text-white' : 'bg-white dark:bg-gray-800 text-gray-600 dark:text-gray-300 shadow-sm'}`}
                            onClick={() => {
                                setSelectedMonth(m.value);
                                setSelectedWeek(null);
                                setSelectedDay(null);
                            }}
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
                            {selectedDay ? `${t('hrTrend')} - ${selectedDay}` :
                                selectedMonth ? `${t('hrTrend')} - ${availableMonths.find(m => m.value === selectedMonth)?.label || selectedMonth}` :
                                    t('hrTrend')}
                        </h3>
                        {selectedDay && (
                            <button
                                onClick={() => setSelectedDay(null)}
                                className="text-xs bg-gray-200 dark:bg-gray-700 px-2 py-1 rounded-full text-gray-600 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
                            >
                                {t('clearSelection')}
                            </button>
                        )}
                    </div>
                    <HRChart data={displayChartData} maxHr={userMaxHr} />
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
                    {dailyGroups.slice(0, visibleCount).map((group, i) => (
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
