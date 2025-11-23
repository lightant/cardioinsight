import { AppData, HeartRateRecord, UserProfile } from '../types';
import { adaptHealthConnectData } from './health-adapter';

export const parseHtmlData = (html: string): AppData => {
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, 'text/html');

    // Check if this is a Health Connect Debug file
    const preTag = doc.querySelector('pre');
    if (preTag && doc.title === 'Health Connect Debug Data') {
        try {
            const jsonContent = JSON.parse(preTag.textContent || '[]');
            const records = adaptHealthConnectData(jsonContent);
            return {
                profile: {
                    name: 'Debug User',
                    dob: '1990-01-01',
                    activityLevel: 'Unknown'
                },
                records
            };
        } catch (e) {
            console.error('Failed to parse debug data', e);
        }
    }

    // Parse Profile
    // The structure is specific based on the provided file
    const profileDivs = Array.from(doc.querySelectorAll('div'));
    let name = '';
    let dob = '';
    let activityLevel = '';

    // Find the profile section
    const profileHeader = profileDivs.find(d => d.textContent?.trim() === '1. Profile');
    if (profileHeader) {
        const profileContent = profileHeader.nextElementSibling;
        if (profileContent) {
            const lines = profileContent.querySelectorAll('div');
            lines.forEach(line => {
                const text = line.textContent || '';
                if (text.includes('Name :')) name = text.replace('Name :', '').trim();
                if (text.includes('Date of birth :')) dob = text.replace('Date of birth :', '').trim();
                if (text.includes('Activity level :')) activityLevel = text.replace('Activity level :', '').trim();
            });
        }
    }

    const profile: UserProfile = {
        name,
        dob,
        activityLevel,
    };

    // Parse Table
    const rows = Array.from(doc.querySelectorAll('tr'));
    const records: HeartRateRecord[] = [];

    // Skip header row (index 0)
    for (let i = 1; i < rows.length; i++) {
        const cells = rows[i].querySelectorAll('td');
        if (cells.length < 5) continue;

        const dateLabel = cells[0].textContent?.trim() || '';
        const fullTimeStr = cells[1].textContent?.trim() || ''; // e.g., "Thu 20 Nov 20:00 - 20:32"
        const hrStr = cells[2].textContent?.trim() || '';
        const tag = cells[3].textContent?.trim() || '';
        const notes = cells[4].textContent?.trim() || '';

        // Parse HR
        let minHr = 0, maxHr = 0;
        if (hrStr.includes('-')) {
            const parts = hrStr.split('-');
            minHr = parseInt(parts[0]);
            maxHr = parseInt(parts[1]);
        } else {
            minHr = parseInt(hrStr);
            maxHr = parseInt(hrStr);
        }

        records.push({
            date: dateLabel,
            fullDate: fullTimeStr,
            timeRange: fullTimeStr.split(' ').slice(3).join(' '), // Rough extraction
            minHr,
            maxHr,
            avgHr: Math.round((minHr + maxHr) / 2),
            tag,
            notes
        });
    }

    return { profile, records };
};

export const calculateAge = (dob: string): number => {
    if (!dob) return 0;
    const birthDate = new Date(dob);
    const ageDifMs = Date.now() - birthDate.getTime();
    const ageDate = new Date(ageDifMs); // miliseconds from epoch
    return Math.abs(ageDate.getUTCFullYear() - 1970);
};

export const parseRecordDate = (fullDateStr: string): Date => {
    // Format: "Thu 20 Nov 20:00 - 20:32" or "Thu 20 Nov 16:12"
    // We need to extract "20 Nov" and add a year.
    // Assuming current year for now, or infer from context.
    // Since the file has "20 Nov", and today is 21 Nov 2025, it's likely 2025.

    try {
        const parts = fullDateStr.split(' ');
        // parts[0] = "Thu", parts[1] = "20", parts[2] = "Nov"
        const day = parts[1];
        const month = parts[2];
        const year = new Date().getFullYear(); // Default to current year

        return new Date(`${month} ${day}, ${year}`);
    } catch (e) {
        return new Date();
    }
};
