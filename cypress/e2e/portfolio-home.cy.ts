import { HomePage } from '../pages/HomePage'

const homePage = new HomePage()

// List of companies to be tested in the portfolio home page
const companies = [
  'Experience at Southern Company',
  'Experience at Lockheed Martin',
  'Experience at Fiserv',
  'Experience at Ford Motor Company',
  'Experience at Royal Caribbean Ltd.',
  'Experience at Canfield Scientific'
]
const pause = () => cy.wait(1000)

describe('Portfolio home page experience tests', () => {
  companies.forEach((companyName) => {
    it(`Checks work description flow for ${companyName}`, () => {
      cy.visit('/')
      pause()

      // Verify that the portfolio home page loads correctly by checking for the presence of the user's name and links
      cy.contains('Alex').should('be.visible')
      cy.get('a').should('have.length.greaterThan', 0)

      // Interact with the company block to verify the work description button
      homePage
        .getChooseWorkDescriptionButton(companyName)
        .should('be.visible')
        .click()
        pause()

      // Verify that the "Short Details" menu item is visible and can be clicked, and that the work story heading updates accordingly
        homePage
        .getShortDetailsMenuItem(companyName)
        .should('be.visible')
        .click()
        pause()

      // Verify that the work story heading updates to "Work description" after clicking the "Short Details" menu item
        homePage
        .getWorkStoryHeading(companyName)
        .should('be.visible')
        .and('have.text', 'Work description')
        pause()

      // Verify that the "Long Story" menu item is visible and can be clicked, and that the work story heading updates accordingly
        homePage
        .getLongStoryMenuItem(companyName)
        .should('be.visible')
        .click()
        pause()

      // Verify that the work story heading updates to "Work story" after clicking the "Long Story" menu item
        homePage
        .getWorkStoryHeading(companyName)
        .should('be.visible')
        .and('have.text', 'Work story')
        pause()
    })
  })
})