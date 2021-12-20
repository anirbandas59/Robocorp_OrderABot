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
${HTML_TEMPLATE_FILE}=    receipt_template.html
&{ENV_JSON}=      Key=Value
${ORDERS_FILE}=    ${null}
${ROBOT_ORDERS}=    ${null}
&{ROBOT_SPECS}=    Order_Number=${0}    Head=${0}    Body=${0}    Legs=${0}    Address=${null}
${POPUP_OK_BUTTON_SELECTOR}=    ${null}
${HEAD_SELECTOR}=    ${null}
${BODY_SELECTOR_GROUP}=    ${null}
${BODY_SELECTOR_VALUE}=    ${null}
${LEGS_SELECTOR}=    ${null}
${ADDRESS_SELECTOR}=    ${null}
${PREVIEW_SELECTOR}=    ${null}
${ERROR_MESSAGE_SELECTOR}=    ${null}
${RECEIPT_SELECTOR}=    ${null}

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
    Open intranet site
    # Fill in the dummy order into the site
    Fill the form and Submit the order    ${ROBOT_SPECS}
    # Close the browser
    # [Teardown]    Close the Browser

*** Keywords ***
Get Variables from JSON File
    ${json_text}=    Load JSON from file    ${ENV_VAR_FILE}
    # &{ENV_JSON}=    Load JSON from file    ${ENV_VAR_FILE}    utf-8
    Set Global Variable    &{ENV_JSON}    &{json_text}
    Set Global Variable    ${POPUP_OK_BUTTON_SELECTOR}    ${ENV_JSON}[popup_OK_button_selector]
    Set Global Variable    ${HEAD_SELECTOR}    ${ENV_JSON}[head_selector]
    Set Global Variable    ${BODY_SELECTOR_GROUP}    ${ENV_JSON}[body_selector_group]
    Set Global Variable    ${BODY_SELECTOR_VALUE}    ${ENV_JSON}[body_selector_value]
    Set Global Variable    ${LEGS_SELECTOR}    ${ENV_JSON}[legs_selector]
    Set Global Variable    ${ADDRESS_SELECTOR}    ${ENV_JSON}[address_selector]
    Set Global Variable    ${PREVIEW_SELECTOR}    ${ENV_JSON}[preview_selector]
    Set Global Variable    ${ERROR_MESSAGE_SELECTOR}    ${ENV_JSON}[error_message_selector]
    Set Global Variable    ${RECEIPT_SELECTOR}    ${ENV_JSON}[receipt_selector]
    Log    ${ROBOT_SPECS}

Open intranet site
    Log    Opening ${ENV_JSON}[rb_order_website]
    Open Available Browser    ${ENV_JSON}[rb_order_website]
    # Click on OK alert button
    Wait Until Element Is Visible    ${POPUP_OK_BUTTON_SELECTOR}
    ${button_visible}=    Is Element Visible    ${POPUP_OK_BUTTON_SELECTOR}
    IF    ${button_visible}
        Click Button    OK
    END

Download Orders CSV File
    @{orders}=    Split String From Right    ${ENV_JSON}[rb_order_requests_file]    /    1
    Set Global Variable    ${ORDERS_FILE}    ${orders}[1]
    Download    ${ENV_JSON}[rb_order_requests_file]    target_file=${orders}[1]    overwrite=${True}

Read Orders from CSV File
    ${ROBOT_ORDERS}=    Read table from CSV    ${ORDERS_FILE}    header=True    delimiters=,

Fill the form and Submit the order
    [Arguments]    ${robot_specs}
    ${order_number}    Set Variable    ${robot_specs.Order_Number}
    ${head_value}    Set Variable    ${robot_specs.Head}
    ${body_value}=    Format String    ${BODY_SELECTOR_VALUE}    ${robot_specs.Body}
    ${legs_value}    Set Variable    ${robot_specs.Legs}
    ${address_value}    Set Variable    ${robot_specs}[Address]
    Log    Order Number=${order_number}, Head=${head_value}, Body=${body_value}, Legs=${legs_value}, Address=${address_value}
    Select From List By Value    ${HEAD_SELECTOR}    ${head_value}
    Select Radio Button    ${BODY_SELECTOR_GROUP}    ${body_value}
    Input Text    ${LEGS_SELECTOR}    xpath:${legs_value}
    Input Text    ${ADDRESS_SELECTOR}    Test
    # Click Button    Preview
    Click Button    Order
    Wait Until Element Is Visible    ${RECEIPT_SELECTOR}
    ${Message}=    Get Text    ${RECEIPT_SELECTOR}
    Preview and Take Screenshot of Robot    ${order_number}.png
    log    ${Message}

Preview and Take Screenshot of Robot
    [Arguments]    ${filename}
    Screenshot    ${PREVIEW_SELECTOR}    ${OUTPUT_DIR}${/}${filename}

Order Another Robot
    ${available_button}=    Is Element Visible    ${ENV_JSON}[order_another_btn_selector]
    IF    ${available_button}
        Click Button    ${ENV_JSON}[order_another_btn_selector]
    END

Create Order Receipt in PDF

Close the Browser
    Close Browser
