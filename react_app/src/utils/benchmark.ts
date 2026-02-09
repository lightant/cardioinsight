/**
 * Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
 * All rights reserved.
 */
import { parseHtmlData } from './parser';
import { HealthService } from '../services/health';

export const runHtmlBenchmark = async (htmlContent: string): Promise<{ timeMs: number; recordCount: number }> => {
    const start = performance.now();
    const result = parseHtmlData(htmlContent);
    const end = performance.now();
    return {
        timeMs: end - start,
        recordCount: result.records.length
    };
};

export const runHealthConnectBenchmark = async (days: number): Promise<{ timeMs: number; recordCount: number }> => {
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - days);

    const startTime = performance.now();
    const records = await HealthService.getHeartRateData(start, end);
    const endTime = performance.now();

    return {
        timeMs: endTime - startTime,
        recordCount: records.length
    };
};
