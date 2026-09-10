/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{html,ts}",
  ],

  theme: {
    extend: {
      colors: {
        bridge: {
          // ─────────────────────────────
          // Backgrounds
          // ─────────────────────────────
          darkest: '#070B14', // App/page background
          dark: '#0B1120',    // Secondary background
          card: '#111827',    // Cards / panels
          elevated: '#172033', // Hover / elevated surfaces

          // ─────────────────────────────
          // Borders
          // ─────────────────────────────
          border: '#243047',       // Default border
          'border-soft': '#1A2436', // Subtle separators
          'border-strong': '#334155', // Focused / emphasized border

          // ─────────────────────────────
          // Primary — Teal
          // ─────────────────────────────
          primary: '#14B8A6',       // Main actions
          'primary-hover': '#0D9488',
          'primary-active': '#0F766E',
          'primary-soft': '#0F3D3A', // Darkened + separated from accent-soft

          // ─────────────────────────────
          // Secondary accent — Cyan
          // ─────────────────────────────
          accent: '#22D3EE',
          'accent-soft': '#1E5A73', // Lightened + separated from primary-soft

          // ─────────────────────────────
          // Text
          // ─────────────────────────────
          text: '#F8FAFC',          // Main text
          'text-secondary': '#CBD5E1',
          muted: '#94A3B8',
          'muted-dark': '#64748B',

          // ─────────────────────────────
          // Semantic
          // Soft variants are translucent tints (rgba), not solid fills,
          // so they read as subtle chips/badges over any bridge background.
          // ─────────────────────────────
          success: '#22C55E',
          'success-soft': 'rgba(34, 197, 94, 0.16)',

          warning: '#F59E0B',
          'warning-soft': 'rgba(245, 158, 11, 0.16)',

          error: '#EF4444',
          'error-soft': 'rgba(239, 68, 68, 0.16)',

          info: '#3B82F6',
          'info-soft': 'rgba(59, 130, 246, 0.16)',
        }
      },

      keyframes: {
        'slide-in-from-top': {
          '0%': { opacity: '0', transform: 'translateY(-8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
      animation: {
        'slide-in-from-top': 'slide-in-from-top 0.3s ease-out',
      },
    },
  },

  plugins: [],
}