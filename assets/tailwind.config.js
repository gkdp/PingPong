module.exports = {
  mode: 'jit',
  darkMode: false,
  purge: ['./js/**/*.js', '../lib/*_web/**/*.*ex'],
  theme: {},
  variants: {},
  plugins: [require('@tailwindcss/forms')],
}
