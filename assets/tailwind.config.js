module.exports = {
  mode: 'jit',
  purge: ['./js/**/*.js', '../lib/*_web/**/*.*ex'],
  darkMode: false,
  // darkMode: 'media',
  theme: {},
  variants: {},
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/custom-forms'),
  ],
}
