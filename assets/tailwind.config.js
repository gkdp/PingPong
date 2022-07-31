const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  mode: 'jit',
  purge: ['./js/**/*.js', '../lib/*_web/**/*.*ex'],
  darkMode: 'media',
  theme: {
    textShadow: {
      default: '1px 2px #000',
    },
    extend: {
      fontFamily: {
        'montserrat': ['Montserrat', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  variants: {},
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/custom-forms'),
    require('tailwindcss-textshadow'),
  ],
}
