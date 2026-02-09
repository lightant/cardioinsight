const assert = require('assert');

// Mock function similar to implemented logic
const parseRecordDate = (fullDateStr) => {
    // Format: "Thu 20 Nov 20:00 - 20:32"
    try {
        const parts = fullDateStr.split(' ');
        const day = parts[1];
        const month = parts[2];
        let year = new Date().getFullYear(); // 2026 (based on system time)

        let timeStr = '';
        if (parts[3]) {
            timeStr = parts[3].split('-')[0];
        }

        let dateStr = `${month} ${day}, ${year} ${timeStr}`;
        let date = new Date(dateStr);

        console.log(`Parsed initial: ${dateStr} -> ${date}`);

        if (date > new Date()) {
            console.log("Future date detected, subtracting year...");
            year -= 1;
            dateStr = `${month} ${day}, ${year} ${timeStr}`;
            date = new Date(dateStr);
            console.log(`Corrected: ${dateStr} -> ${date}`);
        }
        return date;
    } catch (e) {
        return new Date();
    }
};

// Test 1: Past date in current year (e.g., Jan 1, 2026 is past relative to Jan 31 2026)
// Assuming today is Jan 31 2026.
const jan1 = parseRecordDate("Thu 01 Jan 10:00 - 11:00");
// Should be Jan 01 2026.
assert.strictEqual(jan1.getFullYear(), 2026);
assert.strictEqual(jan1.getMonth(), 0); // Jan is 0
console.log('Test 1 Passed: Jan 1 is 2026');

// Test 2: Future date in current year (e.g., Dec 25) -> Should be last year (2025)
const dec25 = parseRecordDate("Thu 25 Dec 10:00 - 11:00");
assert.strictEqual(dec25.getFullYear(), 2025);
assert.strictEqual(dec25.getMonth(), 11); // Dec is 11
console.log('Test 2 Passed: Dec 25 is 2025');

// Test 3: Edge case - Tomorrow? (Feb 1 2026) -> Should be 2025
// If today is Jan 31 2026.
const feb1 = parseRecordDate("Sun 01 Feb 10:00");
assert.strictEqual(feb1.getFullYear(), 2025);
console.log('Test 3 Passed: Feb 1 is 2025');

console.log('All tests passed');
