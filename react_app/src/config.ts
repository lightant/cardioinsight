/**
 * Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
 * All rights reserved.
 */
export const CONFIG = {
    // Set to true to enable debug features (Load cached data, Debug Export, Benchmarks)
    IS_DEBUG: import.meta.env.VITE_DEBUG_MODE === 'true' || import.meta.env.DEV,
};
