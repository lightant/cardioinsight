import { format, parse, parseISO, isToday, isYesterday, isValid } from 'date-fns';
import { Locale } from 'date-fns';
import { TFunction } from 'i18next';

export const getLocalizedDate = (dateStr: string, t: TFunction, locale: Locale, isChinese: boolean): string => {
    if (!dateStr) return '';

    // Handle "Today" / "Yesterday" strings from legacy data
    if (dateStr.toLowerCase() === 'today') return t('today');
    if (dateStr.toLowerCase() === 'yesterday') return t('yesterday');

    const dateFormat = isChinese ? 'M月d日' : 'd MMM';

    // Try ISO format first (yyyy-MM-dd)
    const isoDate = parseISO(dateStr);
    if (isValid(isoDate)) {
        if (isToday(isoDate)) return t('today');
        if (isYesterday(isoDate)) return t('yesterday');
        return format(isoDate, dateFormat, { locale });
    }

    // Try parsing legacy format "d MMM" (e.g., "20 Nov")
    // We assume current year for legacy data without year
    const legacyDate = parse(dateStr, 'd MMM', new Date());
    if (isValid(legacyDate)) {
        return format(legacyDate, dateFormat, { locale });
    }

    // Also try "d MMM yyyy" just in case
    const legacyDateWithYear = parse(dateStr, 'd MMM yyyy', new Date());
    if (isValid(legacyDateWithYear)) {
        return format(legacyDateWithYear, dateFormat, { locale });
    }

    // Fallback: return original string
    return dateStr;
};
