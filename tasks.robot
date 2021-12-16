*** Settings ***
Documentation     Robo will orders new robots from RobotSpareBin Industries Inc.
...               Robo will saves the order HTML receipt as a PDF file.
...               Robo will save the screenshot of the ordered robot
...               Robo will embed the screenshot to the PDF receipt
...               Robo will create zipped archive of the receipts and images.
Library           RPA.HTTP
Library           RPA.Browser.Selenium
Library           RPA.PDF
Library           RPA.Robocorp.Vault

*** Variables ***

*** Tasks ***
Minimal task
    Log    Done.

*** Keywords ***
