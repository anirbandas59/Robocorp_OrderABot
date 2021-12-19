*** Settings ***
Documentation     Robo will orders new robots from RobotSpareBin Industries Inc.
...               Robo will saves the order HTML receipt as a PDF file.
...               Robo will save the screenshot of the ordered robot
...               Robo will embed the screenshot to the PDF receipt
...               Robo will create zipped archive of the receipts and images.
Library           RPA.HTTP
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.PDF
Library           RPA.Robocorp.Vault
Library           RPA.JSON
Library           RPA.FileSystem
Library           String
Library           RPA.Tables

*** Variables ***
${ENV_VAR_FILE}=    env_variables.json
&{ENV_JSON}=      Key=Value
${ORDERS_FILE}
${ROBOT_ORDERS}

*** Tasks ***
Order Build-A-Bot from RobotSpareBin Industries Inc. and save the receipt/screenshot to PDF and create zipped archive.
    Log    Starting Build-A-Bot Order.
# Get Variables From JSON file
    Get Variables from JSON File
# Download Orders file from the intranet site
    Download Orders CSV File
    ${file_exists}=    Does File Exist    ${ORDERS_FILE}
    IF    ${file_exists} == ${true}
        # Read the CSV File and get orders
        Read Orders from CSV File
        Log    ${ROBOT_ORDERS}
    END
# Open RobotSpareBin Industries Inc site
    # Open intranet site

*** Keywords ***
Get Variables from JSON File
    ${json_text}=    Load JSON from file    ${ENV_VAR_FILE}
    # &{ENV_JSON}=    Load JSON from file    ${ENV_VAR_FILE}    utf-8
    Set Global Variable    &{ENV_JSON}    &{json_text}

Open intranet site
    Log    Opening ${ENV_JSON}[rb_order_website]
    Open Available Browser    ${ENV_JSON}[rb_order_website]
    # Click on OK alert button
    Wait Until Element Is Visible    //*[@id="root"]//button[1]
    Click Button    OK

Download Orders CSV File
    @{orders}=    Split String From Right    ${ENV_JSON}[rb_order_requests_file]    /    1
    Set Global Variable    ${ORDERS_FILE}    ${orders}[1]
    Download    ${ENV_JSON}[rb_order_requests_file]    target_file=${orders}[1]    overwrite=${True}

Read Orders from CSV File
    ${ROBOT_ORDERS}=    Read table from CSV    ${ORDERS_FILE}    header=True    delimiters=,
