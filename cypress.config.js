const { defineConfig } = require("cypress");

module.exports = defineConfig({
  allowCypressEnv: false,

  e2e: {
    baseUrl: "https://alexbashchuk.github.io",

    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
});