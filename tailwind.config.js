/** @type {import('tailwindcss').Config} */
export default {
    content: [
        "./index.html",
        "./src/**/*.{js,ts,jsx,tsx}",
    ],
    theme: {
        extend: {
            colors: {
                'cardio-orange': '#FF783C',
                'cardio-dark': '#252525',
            },
            fontFamily: {
                sans: ['Inter', 'sans-serif'],
            }
        },
    },
    darkMode: 'class',
    plugins: [
        require('@tailwindcss/typography'),
    ],
}
