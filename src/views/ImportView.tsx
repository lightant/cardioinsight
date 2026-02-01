import { useTranslation } from 'react-i18next';
import { Upload, Activity, FileText } from 'lucide-react';
import { Capacitor } from '@capacitor/core';
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';
import { Share } from '@capacitor/share';
import { format } from 'date-fns';
import { HealthService } from '../services/health';
import { CONFIG } from '../config';

interface Props {
    onFileUpload: (event: React.ChangeEvent<HTMLInputElement>) => void;
    onSync: () => void;
    syncing: boolean;
}

export default function ImportView({ onFileUpload, onSync, syncing }: Props) {
    const { t } = useTranslation();

    return (
        <div className="flex flex-col items-center justify-center min-h-[70vh] space-y-8 px-4">
            <h2 className="text-2xl font-bold text-gray-800 dark:text-white mb-4">{t('importData')}</h2>

            {/* File Upload */}
            <label className="w-full max-w-sm p-6 bg-white dark:bg-gray-800 rounded-2xl shadow-lg cursor-pointer hover:scale-[1.02] transition-transform border-2 border-dashed border-gray-200 dark:border-gray-700 flex flex-col items-center gap-4">
                <div className="w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-300">
                    <Upload size={32} />
                </div>
                <div className="text-center">
                    <h3 className="font-semibold text-gray-800 dark:text-white">{t('importFromFile')}</h3>
                    <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{t('importHint')}</p>
                </div>
                <input
                    type="file"
                    accept=".html"
                    onChange={async (e) => {
                        if (e.target.files && e.target.files.length > 0) {
                            const file = e.target.files[0];
                            const text = await file.text();
                            try {
                                const { ImportLogic } = await import('../utils/import-logic');
                                const records = ImportLogic.parseHtmlFile(text);
                                console.log('Imported records:', records);

                                // Save simplified version
                                await ImportLogic.saveSimplifiedData(records);
                                alert(`Imported ${records.length} records successfully. Data cached.`);

                                // In a real app we'd save these to state/context.
                            } catch (err: any) {
                                alert('Error importing file: ' + err.message);
                            }
                            if (onFileUpload) onFileUpload(e);
                        }
                    }}
                    className="hidden"
                />


                {CONFIG.IS_DEBUG && (
                    <div className="w-full max-w-sm">
                        <button
                            onClick={async () => {
                                try {
                                    const { ImportLogic } = await import('../utils/import-logic');
                                    const records = await ImportLogic.loadSimplifiedData();
                                    if (records.length > 0) {
                                        alert(`Loaded ${records.length} records from cache.`);
                                        // Should load into app context normally
                                    } else {
                                        alert('No cached data found.');
                                    }
                                } catch (e) {
                                    console.error(e);
                                }
                            }}
                            className="text-sm text-blue-500 hover:underline w-full text-center mb-4"
                        >
                            {t('loadCachedData', { defaultValue: 'Load Cached Data' })}
                        </button>
                    </div>
                )}
            </label>

            {/* Health Connect Sync */}
            <button
                onClick={onSync}
                disabled={syncing}
                className="w-full max-w-sm p-6 bg-white dark:bg-gray-800 rounded-2xl shadow-lg hover:scale-[1.02] transition-transform border border-gray-100 dark:border-gray-700 flex flex-col items-center gap-4 relative overflow-hidden"
            >
                {syncing && <div className="absolute inset-0 bg-white/50 dark:bg-black/50 z-10 flex items-center justify-center"><Activity className="animate-spin text-cardio-orange" size={32} /></div>}
                <div className="w-16 h-16 bg-green-100 dark:bg-green-900 rounded-full flex items-center justify-center text-green-600 dark:text-green-300">
                    <Activity size={32} />
                </div>
                <div className="text-center">
                    <h3 className="font-semibold text-gray-800 dark:text-white">{t('syncHealthConnect')}</h3>
                    <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{t('syncHint')}</p>
                </div>
            </button>

            {/* Debug Export (Optional/Hidden-ish) */}
            {CONFIG.IS_DEBUG && (
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

                            const fileName = `health_debug_${format(new Date(), 'yyyyMMdd_HHmmss')}.html`;
                            const result = await Filesystem.writeFile({
                                path: fileName,
                                data: htmlContent,
                                directory: Directory.Documents,
                                encoding: Encoding.UTF8
                            });

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
                    className="text-xs text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 flex items-center gap-1 mt-8"
                >
                    <FileText size={12} />
                    {t('debugExport')}
                </button>
            )}
        </div >
    );
}
