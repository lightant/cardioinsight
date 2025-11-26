import { useTranslation } from 'react-i18next';
import { Brain, Download } from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import { format } from 'date-fns';

interface Props {
    reportContent: string;
    onGenerate: () => void;
    loading: boolean;
    hasApiKey: boolean;
}

export default function InsightView({ reportContent, onGenerate, loading, hasApiKey }: Props) {
    const { t } = useTranslation();

    if (!reportContent) {
        return (
            <div className="flex flex-col items-center justify-center min-h-[60vh] px-4 text-center space-y-6">
                <div className="w-24 h-24 bg-purple-100 dark:bg-purple-900 rounded-full flex items-center justify-center text-purple-600 dark:text-purple-300 mb-4">
                    <Brain size={48} />
                </div>
                <h2 className="text-2xl font-bold text-gray-800 dark:text-white">{t('aiInsight')}</h2>
                <p className="text-gray-500 dark:text-gray-400 max-w-xs">
                    {t('aiInsightDesc')}
                </p>

                {!hasApiKey && (
                    <div className="bg-yellow-50 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-200 p-4 rounded-xl text-sm max-w-sm">
                        {t('apiKeyWarning')}
                    </div>
                )}

                <button
                    onClick={onGenerate}
                    disabled={loading}
                    className="w-full max-w-xs bg-gradient-to-r from-blue-600 to-purple-600 text-white p-4 rounded-2xl font-semibold flex items-center justify-center gap-2 shadow-lg hover:opacity-90 transition-opacity disabled:opacity-50"
                >
                    {loading ? t('generating') : (
                        <>
                            <Brain size={20} />
                            {t('generateReport')}
                        </>
                    )}
                </button>
            </div>
        );
    }

    return (
        <div className="pb-24 px-4">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-2xl font-bold text-gray-800 dark:text-white">{t('aiInsight')}</h2>
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
                    className="p-2 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 rounded-full hover:bg-gray-200 dark:hover:bg-gray-600"
                    title={t('saveToFile')}
                >
                    <Download size={20} />
                </button>
            </div>

            <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-sm prose dark:prose-invert max-w-none">
                <ReactMarkdown className="font-sans text-sm text-gray-800 dark:text-gray-200">
                    {reportContent}
                </ReactMarkdown>
            </div>

            <div className="mt-8 flex justify-center">
                <button
                    onClick={onGenerate}
                    disabled={loading}
                    className="text-sm text-blue-600 dark:text-blue-400 hover:underline"
                >
                    {t('regenerate')}
                </button>
            </div>
        </div>
    );
}
