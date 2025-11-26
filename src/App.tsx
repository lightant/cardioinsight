import { useState, useEffect, useMemo } from 'react';
import { parseHtmlData, calculateAge, parseRecordDate } from './utils/parser';
import { AppData, HeartRateRecord } from './types';
import { format, getWeek, startOfWeek } from 'date-fns';
import { enUS, zhCN, zhTW } from 'date-fns/locale';
import { useTranslation } from 'react-i18next';
import { aggregateData } from './utils/aggregator';
import { HealthService } from './services/health';
import { StorageService } from './services/storage';
import { adaptHealthConnectData } from './utils/health-adapter';
import { Capacitor } from '@capacitor/core';
import { Activity } from 'lucide-react';

// Views & Components
import BottomNav from './components/BottomNav';
import HomeView from './views/HomeView';
import ImportView from './views/ImportView';
import InsightView from './views/InsightView';
import SettingsView from './views/SettingsView';

function App() {
    const { t, i18n } = useTranslation();
    const [data, setData] = useState<AppData | null>(null);
    const [selectedMonth, setSelectedMonth] = useState<string>('');
    const [selectedWeek, setSelectedWeek] = useState<number | null>(null);
    const [selectedDay, setSelectedDay] = useState<string | null>(null);
    const [apiKey, setApiKey] = useState(() => localStorage.getItem('gemini_api_key') || '');
    const [reportContent, setReportContent] = useState('');
    const [loadingReport, setLoadingReport] = useState(false);
    const [theme, setTheme] = useState<'light' | 'dark' | 'system'>('system');
    const [showProfileEdit, setShowProfileEdit] = useState(false);
    const [editProfile, setEditProfile] = useState<Partial<AppData['profile']>>({});
    const [syncing, setSyncing] = useState(false);
    const [visibleCount, setVisibleCount] = useState(10);

    // Navigation State
    const [activeTab, setActiveTab] = useState<'home' | 'import' | 'insight' | 'settings'>('home');

    // Get date-fns locale
    const dateLocale = useMemo(() => {
        switch (i18n.language) {
            case 'zh-CN': return zhCN;
            case 'zh-TW': return zhTW;
            default: return enUS;
        }
    }, [i18n.language]);

    // Load data from storage on mount
    useEffect(() => {
        const load = async () => {
            const savedData = await StorageService.loadData();
            if (savedData) setData(savedData);

            const savedReport = await StorageService.loadReport();
            if (savedReport) setReportContent(savedReport);
        };
        load();
    }, []);

    // Save data when it changes
    useEffect(() => {
        if (data) {
            StorageService.saveData(data);
        }
    }, [data]);

    // Save report when it changes
    useEffect(() => {
        if (reportContent) {
            StorageService.saveReport(reportContent);
        }
    }, [reportContent]);

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

                // Overwrite existing data with new import
                setData({
                    profile: data?.profile || {
                        name: 'User',
                        dob: '1990-01-01',
                        activityLevel: 'Moderate',
                        sex: 'Male',
                        height: '175cm',
                        weight: '70kg'
                    },
                    records: newRecords
                });

                alert(t('syncedResult', { rawCount: records.length, newCount: newRecords.length }));
                setActiveTab('home'); // Switch to home after sync
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
                setActiveTab('home'); // Switch to home after import
            };
            reader.readAsText(file);
        }
    };

    // Filter data
    const filteredRecords = useMemo(() => {
        if (!data) return [];
        let records = data.records;

        if (selectedMonth) {
            records = records.filter(r => {
                const date = parseRecordDate(r.fullDate);
                return format(date, 'yyyy-MM') === selectedMonth;
            });
        }

        if (selectedWeek !== null) {
            records = records.filter(r => {
                const date = parseRecordDate(r.fullDate);
                return getWeek(date, { weekStartsOn: 1 }) === selectedWeek;
            });
        }

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
        const months = new Map<string, string>();
        data.records.forEach(r => {
            const date = parseRecordDate(r.fullDate);
            const value = format(date, 'yyyy-MM');
            const label = format(date, 'MMM yyyy', { locale: dateLocale });
            months.set(value, label);
        });
        return Array.from(months.entries()).map(([value, label]) => ({ value, label }));
    }, [data, dateLocale]);

    // Available Weeks
    const availableWeeks = useMemo(() => {
        if (!data || !selectedMonth) return [];
        const weeksMap = new Map<number, Date>();

        data.records.forEach(r => {
            const date = parseRecordDate(r.fullDate);
            if (format(date, 'yyyy-MM') === selectedMonth) {
                const weekNum = getWeek(date, { weekStartsOn: 1 });
                if (!weeksMap.has(weekNum)) {
                    weeksMap.set(weekNum, startOfWeek(date, { weekStartsOn: 1 }));
                }
            }
        });

        return Array.from(weeksMap.entries())
            .sort((a, b) => b[0] - a[0])
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
            setActiveTab('settings'); // Redirect to settings
            return;
        }

        setLoadingReport(true);
        try {
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
        } catch (error) {
            console.error(error);
            alert('Failed to generate report. Check console for details.');
        } finally {
            setLoadingReport(false);
        }
    };

    // Determine chart data with fixed axes
    const chartData = useMemo(() => {
        if (!data) return [];

        if (selectedDay) {
            // Day View: 00:00 to 23:00
            const dayRecords = filteredRecords.filter(r => r.date === selectedDay);
            // Aggregate existing data by hour
            // Note: aggregateData('day') returns labels like "HH:mm" from records. 
            // We need to ensure we match "HH:00" format.
            // Actually, health-adapter produces "HH:mm".
            // Let's just map 00 to 23.

            const hours = Array.from({ length: 24 }, (_, i) => {
                return i.toString().padStart(2, '0') + ':00';
            });

            // We need to aggregate the dayRecords into these hours first
            const hourlyMap = new Map<string, HeartRateRecord[]>();
            dayRecords.forEach(r => {
                // r.timeRange is "HH:mm". We want to group by hour.
                const hour = r.timeRange.split(':')[0] + ':00';
                if (!hourlyMap.has(hour)) hourlyMap.set(hour, []);
                hourlyMap.get(hour)?.push(r);
            });

            return hours.map(hour => {
                const records = hourlyMap.get(hour);
                if (records && records.length > 0) {
                    const mins = records.map(r => r.minHr);
                    const maxs = records.map(r => r.maxHr);
                    const avgs = records.map(r => r.avgHr || 0);
                    return {
                        id: hour,
                        label: hour,
                        min: Math.min(...mins),
                        max: Math.max(...maxs),
                        avg: Math.round(avgs.reduce((a, b) => a + b, 0) / avgs.length),
                        date: selectedDay,
                        empty: false
                    };
                }
                return {
                    id: hour,
                    label: hour,
                    min: 0,
                    max: 0,
                    avg: 0,
                    date: selectedDay,
                    empty: true
                };
            });

        } else if (selectedWeek !== null && selectedMonth) {
            // Week View: Mon to Sun

            // We need a reference date.
            let referenceDate = new Date();
            if (filteredRecords.length > 0) {
                referenceDate = parseRecordDate(filteredRecords[0].fullDate);
            } else {
                // Try to construct from selectedMonth
                const [y, m] = selectedMonth.split('-');
                referenceDate = new Date(parseInt(y), parseInt(m) - 1, 1);
            }

            const weekStartObj = startOfWeek(referenceDate, { weekStartsOn: 1 }); // Mon

            const days = Array.from({ length: 7 }, (_, i) => {
                const d = new Date(weekStartObj);
                d.setDate(d.getDate() + i);
                return d;
            });

            // Aggregate filteredRecords by date
            const dailyMap = new Map<string, HeartRateRecord[]>();
            filteredRecords.forEach(r => {
                // r.date is "d MMM" or "Today". We need to match with our generated days.
                // This is tricky because r.date is formatted.
                // Let's use r.fullDate to parse and compare.
                const rDate = parseRecordDate(r.fullDate);
                const key = format(rDate, 'yyyy-MM-dd');
                if (!dailyMap.has(key)) dailyMap.set(key, []);
                dailyMap.get(key)?.push(r);
            });

            return days.map(d => {
                const key = format(d, 'yyyy-MM-dd');
                const records = dailyMap.get(key);
                // Label format: "d" or "d MMM" depending on preference. 
                // App uses "d" for week view usually? Or "Mon", "Tue"?
                // User asked for "Monday to Sunday". Let's use Day Name.
                const label = format(d, 'EEE', { locale: dateLocale });

                if (records && records.length > 0) {
                    const mins = records.map(r => r.minHr);
                    const maxs = records.map(r => r.maxHr);
                    const avgs = records.map(r => r.avgHr || 0);
                    return {
                        id: key,
                        label,
                        min: Math.min(...mins),
                        max: Math.max(...maxs),
                        avg: Math.round(avgs.reduce((a, b) => a + b, 0) / avgs.length),
                        date: format(d, 'd MMM'),
                        empty: false
                    };
                }
                return {
                    id: key,
                    label,
                    min: 0,
                    max: 0,
                    avg: 0,
                    date: format(d, 'd MMM'),
                    empty: true
                };
            });

        } else if (selectedMonth) {
            // Month View: 1 to End of Month
            const [y, m] = selectedMonth.split('-');
            const year = parseInt(y);
            const month = parseInt(m) - 1; // 0-indexed
            const daysInMonth = new Date(year, month + 1, 0).getDate();

            const days = Array.from({ length: daysInMonth }, (_, i) => {
                return new Date(year, month, i + 1);
            });

            const dailyMap = new Map<string, HeartRateRecord[]>();
            filteredRecords.forEach(r => {
                const rDate = parseRecordDate(r.fullDate);
                const key = format(rDate, 'yyyy-MM-dd');
                if (!dailyMap.has(key)) dailyMap.set(key, []);
                dailyMap.get(key)?.push(r);
            });

            return days.map(d => {
                const key = format(d, 'yyyy-MM-dd');
                const records = dailyMap.get(key);
                // Label: just the day number "d"
                const label = format(d, 'd');

                if (records && records.length > 0) {
                    const mins = records.map(r => r.minHr);
                    const maxs = records.map(r => r.maxHr);
                    const avgs = records.map(r => r.avgHr || 0);
                    return {
                        id: key,
                        label,
                        min: Math.min(...mins),
                        max: Math.max(...maxs),
                        avg: Math.round(avgs.reduce((a, b) => a + b, 0) / avgs.length),
                        date: format(d, 'd MMM'),
                        empty: false
                    };
                }
                return {
                    id: key,
                    label,
                    min: 0,
                    max: 0,
                    avg: 0,
                    date: format(d, 'd MMM'),
                    empty: true
                };
            });

        } else {
            // All Time (Show Months) - Keep existing logic but maybe fill gaps?
            // For now, let's just use existing aggregateData for all time as it's less critical to have empty months usually.
            const allData = aggregateData(filteredRecords, 'all');
            return allData.map(d => ({ ...d, label: d.label, empty: false }));
        }
    }, [filteredRecords, selectedDay, selectedWeek, selectedMonth, dateLocale, availableWeeks]);

    // displayChartData is now just chartData because we formatted labels inside
    const displayChartData = chartData;

    const userMaxHr = useMemo(() => {
        if (!data?.profile.dob) return 190;
        const age = calculateAge(data.profile.dob);
        return 220 - age;
    }, [data?.profile.dob]);

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900 transition-colors duration-300 flex flex-col">
            {/* Global Header */}
            <header className="bg-white dark:bg-gray-800 shadow-sm sticky top-0 z-10 px-4 py-3 flex items-center justify-center shrink-0">
                <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-gradient-to-br from-cardio-orange to-red-500 rounded-lg flex items-center justify-center text-white shadow-sm">
                        <Activity size={20} />
                    </div>
                    <h1 className="text-lg font-bold bg-clip-text text-transparent bg-gradient-to-r from-cardio-orange to-red-600">
                        Cardio Insight
                    </h1>
                </div>
            </header>

            {/* Main Content Area */}
            <main className="flex-1 pt-4 px-4 pb-24 overflow-y-auto">
                {activeTab === 'home' && (
                    <HomeView
                        data={data}
                        profile={data?.profile || { name: 'User', dob: '', sex: 'Male', height: '', weight: '', activityLevel: 'Moderate' }}
                        stats={stats}
                        dailyGroups={dailyGroups}
                        visibleCount={visibleCount}
                        userMaxHr={userMaxHr}
                        selectedMonth={selectedMonth}
                        selectedWeek={selectedWeek}
                        selectedDay={selectedDay}
                        availableMonths={availableMonths}
                        availableWeeks={availableWeeks}
                        displayChartData={displayChartData}
                        onSelectMonth={(m) => {
                            setSelectedMonth(m);
                            setSelectedWeek(null);
                            setSelectedDay(null);
                        }}
                        onSelectWeek={setSelectedWeek}
                        onSelectDay={setSelectedDay}
                        onEditProfile={() => setShowProfileEdit(true)}
                        onFileUpload={handleFileUpload}
                    />
                )}

                {activeTab === 'import' && (
                    <ImportView
                        onFileUpload={handleFileUpload}
                        onSync={handleSync}
                        syncing={syncing}
                    />
                )}

                {activeTab === 'insight' && (
                    <InsightView
                        reportContent={reportContent}
                        onGenerate={generateReport}
                        loading={loadingReport}
                        hasApiKey={!!apiKey}
                    />
                )}

                {activeTab === 'settings' && (
                    <SettingsView
                        profile={data?.profile || { name: 'User', dob: '', sex: 'Male', height: '', weight: '', activityLevel: 'Moderate' }}
                        onUpdateProfile={(p) => setData(prev => prev ? { ...prev, profile: p } : null)}
                        apiKey={apiKey}
                        setApiKey={setApiKey}
                        theme={theme}
                        setTheme={setTheme}
                        showProfileEdit={showProfileEdit}
                        setShowProfileEdit={setShowProfileEdit}
                        editProfile={editProfile}
                        setEditProfile={setEditProfile}
                    />
                )}
            </main>

            {/* Bottom Navigation */}
            <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />
        </div>
    );
}

export default App;
