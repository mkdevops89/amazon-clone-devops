/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        amazon: {
          DEFAULT: '#131921', // Dark blue header
          light: '#232f3e',   // Lighter blue sub-header
          yellow: '#febd69',  // Primary button color
          orange: '#f08804',  // Cart count / accented orange
          blue: '#007185',    // Link color
        }
      }
    },
  },
  plugins: [],
}
