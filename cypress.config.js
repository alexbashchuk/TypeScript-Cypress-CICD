import { defineConfig } from 'cypress'
import { allureCypress } from 'allure-cypress/reporter'

export default defineConfig({
  viewportWidth: 1400,
  viewportHeight: 1200,
  reporter: 'junit',
  reporterOptions: {
    mochaFile: 'results/junit-[hash].xml',
    toConsole: true,
  },

  e2e: {
    setupNodeEvents(on, config) {
      allureCypress(on, config, {
        resultsDir: 'allure-results',
      })

      return config
    },
    baseUrl: 'https://alexbashchuk.github.io',
  },
})