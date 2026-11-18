/** @type {import('tailwindcss').Config} */
// Design tokens. Chart/map colours mirror these in src/lib/theme.ts.
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // Navigation (dark blue-grey)
        nav: { DEFAULT: '#17212c', 2: '#1f2b38', 3: '#2a3a4a', line: '#2a3745', ink: '#e8eef3', mute: '#8da0b1' },
        // Content surfaces
        canvas: '#f2f5f7',
        surface: { DEFAULT: '#ffffff', 2: '#f7f9fb', 3: '#eef2f5' },
        line: { DEFAULT: '#e1e7ed', 2: '#cdd7e0' },
        ink: { DEFAULT: '#1a2632', 2: '#3b4b5a' },
        mute: '#5f7285',
        // Primary accent: muted teal
        teal: { 50: '#ecf6f5', 100: '#d6ebe9', 200: '#b0d8d4', 400: '#52b0a8', 500: '#2f9a93', 600: '#23807a', 700: '#1b6661' },
        // Supporting palette (DEFAULT = mark colour, soft = tint, deep = text on tint)
        glacier: { DEFAULT: '#5b9bc4', soft: '#e7f0f7', deep: '#2f6a91' },
        sage: { DEFAULT: '#6ea47a', soft: '#e8f2ea', deep: '#3f7350' },
        coral: { DEFAULT: '#e0735e', soft: '#fbebe7', deep: '#a8452f' },
        amber: { DEFAULT: '#d9982a', soft: '#fbf1dc', deep: '#855a0b' },
        lavender: { DEFAULT: '#8d82cc', soft: '#efedf9', deep: '#5a4fa0' },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'ui-monospace', 'monospace'],
      },
      boxShadow: {
        card: '0 1px 2px rgba(23,33,44,.04), 0 6px 18px -10px rgba(23,33,44,.10)',
        lift: '0 2px 4px rgba(23,33,44,.05), 0 12px 28px -12px rgba(23,33,44,.18)',
        pop: '0 8px 30px -8px rgba(23,33,44,.25)',
      },
      borderRadius: { xl: '12px', lg: '8px', md: '6px' },
      keyframes: {
        'fade-up': { from: { opacity: 0, transform: 'translateY(6px)' }, to: { opacity: 1, transform: 'none' } },
        shimmer: { '100%': { transform: 'translateX(100%)' } },
        stripe: { to: { backgroundPosition: '28px 0' } },
        sweep: { '0%': { transform: 'translateX(-100%)' }, '100%': { transform: 'translateX(350%)' } },
        ring: { '0%': { transform: 'scale(.8)', opacity: .6 }, '100%': { transform: 'scale(2.2)', opacity: 0 } },
        pop: { from: { opacity: 0, transform: 'scale(.97)' }, to: { opacity: 1, transform: 'none' } },
      },
      animation: { 'fade-up': 'fade-up .35s cubic-bezier(.2,.7,.2,1) both', shimmer: 'shimmer 1.4s infinite', stripe: 'stripe 1s linear infinite', sweep: 'sweep 1.6s ease-in-out infinite', ring: 'ring 1.6s ease-out infinite', pop: 'pop .3s cubic-bezier(.2,.7,.2,1) both' },
    },
  },
  plugins: [],
}
