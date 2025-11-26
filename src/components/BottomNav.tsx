import { Home, Upload, Brain, Settings } from 'lucide-react';
import { useTranslation } from 'react-i18next';

interface Props {
    activeTab: 'home' | 'import' | 'insight' | 'settings';
    onTabChange: (tab: 'home' | 'import' | 'insight' | 'settings') => void;
}

export default function BottomNav({ activeTab, onTabChange }: Props) {
    const { t } = useTranslation();

    const tabs = [
        { id: 'home', label: t('home'), icon: Home },
        { id: 'import', label: t('import'), icon: Upload },
        { id: 'insight', label: t('insight'), icon: Brain },
        { id: 'settings', label: t('settings'), icon: Settings },
    ] as const;

    return (
        <div className="fixed bottom-0 left-0 right-0 bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 pb-safe pt-2 px-4 shadow-lg z-50">
            <div className="flex justify-around items-center max-w-md mx-auto">
                {tabs.map((tab) => {
                    const Icon = tab.icon;
                    const isActive = activeTab === tab.id;
                    return (
                        <button
                            key={tab.id}
                            onClick={() => onTabChange(tab.id)}
                            className={`flex flex-col items-center gap-1 p-2 rounded-xl transition-all duration-300 ${isActive ? 'text-cardio-orange scale-110' : 'text-gray-400 hover:text-gray-600 dark:hover:text-gray-300'}`}
                        >
                            <Icon size={24} strokeWidth={isActive ? 2.5 : 2} />
                            <span className="text-[10px] font-medium">{tab.label}</span>
                        </button>
                    );
                })}
            </div>
        </div>
    );
}
