/**
 * Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
 * All rights reserved.
 */
export interface HeartRateRecord {
    date: string; // "Today", "Yesterday", "18 Nov"
    fullDate: string; // "Thu 20 Nov"
    timeRange: string; // "20:00 - 20:32" or "16:12"
    minHr: number;
    maxHr: number;
    avgHr?: number;
    tag: string; // "Resting", "Exercising", ""
    notes: string;
}

export interface UserProfile {
    name: string;
    dob: string;
    activityLevel: string;
    sex?: string;
    height?: string;
    weight?: string;
}

export interface AppData {
    profile: UserProfile;
    records: HeartRateRecord[];
}
