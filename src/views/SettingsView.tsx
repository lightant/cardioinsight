import { useTranslation } from 'react-i18next';
import { User, Settings, Edit2, Info, Globe, Moon, Key } from 'lucide-react';
import { AppData } from '../types';
import { calculateAge } from '../utils/parser';

interface Props {
    profile: AppData['profile'];
    onUpdateProfile: (profile: AppData['profile']) => void;
    apiKey: string;
    setApiKey: (key: string) => void;
    theme: 'light' | 'dark' | 'system';
    setTheme: (theme: 'light' | 'dark' | 'system') => void;
    showProfileEdit: boolean;
    setShowProfileEdit: (show: boolean) => void;
    editProfile: Partial<AppData['profile']>;
    setEditProfile: (profile: Partial<AppData['profile']>) => void;
}

export default function SettingsView({
    profile,
    onUpdateProfile,
    apiKey,
    setApiKey,
    theme,
    setTheme,
    showProfileEdit,
    setShowProfileEdit,
    editProfile,
    setEditProfile
}: Props) {
    const { t, i18n } = useTranslation();

    return (
        <div className="pb-24 px-4 space-y-6">
            <h2 className="text-2xl font-bold text-gray-800 dark:text-white mb-6">{t('settings')}</h2>

            {/* Profile Card */}
            <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-sm">
                <div className="flex items-center justify-between mb-4">
                    <h3 className="font-semibold text-gray-700 dark:text-gray-200 flex items-center gap-2">
                        <User size={20} />
                        {t('profile')}
                    </h3>
                    <button
                        onClick={() => {
                            setEditProfile(profile);
                            setShowProfileEdit(true);
                        }}
                        className="p-2 text-cardio-orange hover:bg-orange-50 dark:hover:bg-orange-900/20 rounded-full transition-colors"
                    >
                        <Edit2 size={18} />
                    </button>
                </div>
                <div className="flex items-center gap-4">
                    <div className="w-16 h-16 bg-gray-100 dark:bg-gray-700 rounded-full flex items-center justify-center text-gray-400 dark:text-gray-500">
                        <User size={32} />
                    </div>
                    <div>
                        <div className="font-bold text-lg text-gray-800 dark:text-white">{profile.name}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">
                            {calculateAge(profile.dob)} {t('years')} • {t(profile.sex?.toLowerCase() || '') || profile.sex}
                        </div>
                        <div className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                            {profile.height || '-'} • {profile.weight || '-'}
                        </div>
                    </div>
                </div>
            </div>

            {/* Settings Section */}
            <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-sm space-y-6">
                <h3 className="font-semibold text-gray-700 dark:text-gray-200 flex items-center gap-2">
                    <Settings size={20} />
                    {t('preferences')}
                </h3>

                {/* API Key */}
                <div>
                    <label className="block text-sm font-medium mb-2 text-gray-600 dark:text-gray-300 flex items-center gap-2">
                        <Key size={16} />
                        {t('apiKey')}
                    </label>
                    <input
                        type="password"
                        value={apiKey}
                        onChange={(e) => {
                            setApiKey(e.target.value);
                            localStorage.setItem('gemini_api_key', e.target.value);
                        }}
                        className="w-full p-3 border rounded-xl bg-gray-50 dark:bg-gray-700 border-gray-200 dark:border-gray-600 text-gray-800 dark:text-white focus:ring-2 focus:ring-cardio-orange focus:border-transparent outline-none transition-all"
                        placeholder={t('enterApiKey')}
                    />
                </div>

                {/* Theme */}
                <div>
                    <label className="block text-sm font-medium mb-2 text-gray-600 dark:text-gray-300 flex items-center gap-2">
                        <Moon size={16} />
                        {t('theme')}
                    </label>
                    <div className="flex gap-2 p-1 bg-gray-100 dark:bg-gray-700 rounded-xl">
                        {(['light', 'dark', 'system'] as const).map((m) => (
                            <button
                                key={m}
                                onClick={() => setTheme(m)}
                                className={`flex-1 py-2 rounded-lg text-sm font-medium capitalize transition-all ${theme === m ? 'bg-white dark:bg-gray-600 text-cardio-orange shadow-sm' : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'}`}
                            >
                                {t(m)}
                            </button>
                        ))}
                    </div>
                </div>

                {/* Language */}
                <div>
                    <label className="block text-sm font-medium mb-2 text-gray-600 dark:text-gray-300 flex items-center gap-2">
                        <Globe size={16} />
                        {t('language')}
                    </label>
                    <div className="flex gap-2 p-1 bg-gray-100 dark:bg-gray-700 rounded-xl">
                        {[
                            { code: 'en', label: 'English' },
                            { code: 'zh-CN', label: '简体' },
                            { code: 'zh-TW', label: '繁體' }
                        ].map((l) => (
                            <button
                                key={l.code}
                                onClick={() => i18n.changeLanguage(l.code)}
                                className={`flex-1 py-2 rounded-lg text-sm font-medium transition-all ${i18n.language === l.code ? 'bg-white dark:bg-gray-600 text-cardio-orange shadow-sm' : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'}`}
                            >
                                {l.label}
                            </button>
                        ))}
                    </div>
                </div>
            </div>

            {/* About */}
            <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl shadow-sm">
                <h3 className="font-semibold text-gray-700 dark:text-gray-200 flex items-center gap-2 mb-2">
                    <Info size={20} />
                    {t('about')}
                </h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                    CardioInsight v1.0.0
                </p>
                <p className="text-xs text-gray-400 mt-1">
                    {t('copyright')}
                </p>
            </div>

            {/* Profile Edit Modal (Inline for now, could be separate) */}
            {showProfileEdit && (
                <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[60] backdrop-blur-sm px-4">
                    <div className="bg-white dark:bg-gray-800 p-6 rounded-2xl w-full max-w-md shadow-xl">
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
                                    onUpdateProfile(editProfile as AppData['profile']);
                                    setShowProfileEdit(false);
                                }}
                                className="px-4 py-2 bg-cardio-orange text-white rounded-lg hover:opacity-90"
                            >
                                {t('save')}
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
