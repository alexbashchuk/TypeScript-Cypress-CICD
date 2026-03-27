import { HomePage } from '../pages/HomePage'

const homePage = new HomePage()

// List of certificates to be tested in the portfolio home page
const certificates = [
  'AS1',
  'AS2',
  'TDS1',
  'TDS2',
  'qTest',
  'CTFL'
]

const pause = () => cy.wait(1000)

describe('Portfolio home page certificates test', () => {
  certificates.forEach((certificateName) => {
    it(`Checks certificate details for ${certificateName}`, () => {
      cy.visit('/')
      pause()

      cy.contains('Alex').should('be.visible')
      cy.get('a').should('have.length.greaterThan', 0)

      // Verify that the certificate link is visible and can be clicked
      homePage
        .getCertificate(certificateName)
        .should('be.visible')
        .click()
        pause()

      // Verify that the certificate modal window appears and is visible
      homePage
        .getCertificateModal()
        .should('be.visible')

      // Verify that the close button within the certificate modal window is visible and can be clicked
      homePage
        .getCertificateModalCloseButton()
        .should('be.visible')
        .click()
       pause()

      // Verify that the certificate modal window is closed after clicking the close button
      homePage
        .getCertificateModal()
        .should('not.exist')
    })
  })
})