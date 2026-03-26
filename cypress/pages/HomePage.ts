export class HomePage {

  // Method to get the company block based on the block name
  getCompanyBlock(blockName: string) {
    return cy.get(`[aria-label="${blockName}"]`)
  }

  // Method to get the "Choose work description" button within a specific company block
  getChooseWorkDescriptionButton(blockName: string) {
    return this.getCompanyBlock(blockName)
      .find('button')
      .contains('Choose work description')
  }

  // Method to get the "Short Details" menu item within a specific company block
  getShortDetailsMenuItem(blockName: string) {
    return this.getCompanyBlock(blockName)
      .contains('[role="menuitem"]', 'Short Details')
  }

  // Method to get the "Long Story" menu item within a specific company block
  getLongStoryMenuItem(blockName: string) {
    return this.getCompanyBlock(blockName)
      .contains('[role="menuitem"]', 'Long Story')
  }

  // Method to get the heading of the work story within a specific company block
  getWorkStoryHeading(blockName: string) {
    return this.getCompanyBlock(blockName).find('.expBodyTitle')
  }

  // Method to get a certificate link based on the certificate name
  getCertificate(certName: string) {
    return cy.contains('.certLink', certName)
  }

  // Method to get the certificate modal window
  getCertificateModal() {
  return cy.get('[role="dialog"][aria-modal="true"]')
}

  // Method to get the close button within the certificate modal window
  getCertificateModalCloseButton() {
    return this.getCertificateModal().contains('button', 'CLOSE')
  }

}