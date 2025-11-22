# Cardio Insight App

This is a React-based application for viewing Cardio Insight data and generating AI reports.

## Prerequisites

- Node.js (v18 or later)
- Android Studio (for APK building)

## Setup

1.  Navigate to the app directory:
    ```bash
    cd app
    ```

2.  Install dependencies:
    ```bash
    npm install
    ```

3.  Run the development server:
    ```bash
    npm run dev
    ```

## Web App Iteration

To iterate on the design and features as a web application:

1.  Run the development server:
    ```bash
    npm run dev
    ```
2.  Open your browser to the URL shown in the terminal (usually `http://localhost:5173`).
3.  Any changes you make to the code in `src/` will automatically hot-reload in the browser.
4.  You can test all features including file upload and AI report generation directly in the browser.

## Building for Android

1.  **Build Web Assets**:
    ```bash
    npm run build
    ```

2.  **Sync with Capacitor**:
    ```bash
    npx cap sync
    ```

3.  **Open in Android Studio**:
    ```bash
    npx cap open android
    ```

4.  **Run on Device**:
    - Connect a physical Android device (Health Connect may not work on emulators).
    - In Android Studio, select your device and click the **Run** (▶️) button.

> **Note**: For Health Connect to work, you must have the **Samsung Health** app installed and "Sync with Health Connect" enabled in its settings.

## Features

- **Import Data**: Upload your `heart_rate.html` file to view stats.
- **Dashboard**: View average, resting, and peak heart rates.
- **Charts**: Interactive charts for heart rate trends.
- **Daily Records**: Detailed daily breakdown with sparklines.
- **AI Report**: Generate analysis using Google Gemini (requires API Key).
