/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        bg: '#070b14',
        panel: '#0e1524',
        panel2: '#131c30',
        line: '#1f2b45',
        ink: '#e6ecf8',
        mute: '#8b9ab8',
        S: '#4da3ff',
        E: '#f5b83d',
        I: '#ff5d6c',
        R: '#4ad6a0',
        accent: '#5eead4',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'ui-monospace', 'monospace'],
      },
    },
  },
  plugins: [],
}
