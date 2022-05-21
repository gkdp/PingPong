module.exports = {
  mode: 'jit',
  purge: ['./js/**/*.js', '../lib/*_web/**/*.*ex'],
  darkMode: 'class',
  theme: {
    textShadow: {
      default: '1px 2px #000',
    },
  },
  variants: {},
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/custom-forms'),
    require('tailwindcss-textshadow'),
  ],
}
