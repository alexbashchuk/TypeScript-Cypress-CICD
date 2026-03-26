import { defineConfig } from 'cypress'

export default defineConfig({
  reporter: 'junit',
  reporterOptions: {
    mochaFile: 'results/junit-[hash].xml',
    toConsole: true,
  },

  e2e: {
    setupNodeEvents(on, config) {
      return config
    },
    baseUrl: 'https://alexbashchuk.github.io',
  },
})