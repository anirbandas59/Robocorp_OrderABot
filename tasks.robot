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
Library           OperatingSystem
Library           RPA.Archive
Library           RPA.Dialogs

*** Variables ***
${ENV_VAR_FILE}=    env_variables.json
${HTML_TEMPLATE_FILE}=    receipt_template.html
&{ENV_JSON}=      Key=Value
${ORDERS_FILE}=    ${null}
${ROBOT_ORDERS}=    ${null}
&{ROBOT_SPECS}=    Order number=${1}    Head=${1}    Body=${1}    Legs=${1}    Address=${null}
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
    # Log    Starting Build-A-Bot Order.
    # Get Variables From JSON file
    Get Variables from JSON File
    Run Keyword And Continue On Failure    Access Secret Vaults
    ${fileUrl}=    Get Orders URL from User
    ${length}=    Get Length    ${fileUrl}
    IF    ${length} == 0
        ${fileUrl}
        ...    Set Variable    ${ENV_JSON}[rb_order_requests_file]
        Notify User with Default Value
        ...    Using default orders file from URL: ${fileUrl}
    END
    # Download Orders file from the intranet site
    Download Orders CSV File    url=${fileUrl}
    ${file_exists}=    Does File Exist    ${ORDERS_FILE}
    IF    ${file_exists} == ${true}
        # Read the CSV File and get orders
        ${ROBOT_ORDERS}=    Read Orders from CSV File
        # Log    ${ROBOT_ORDERS}
    END
    # Open RobotSpareBin Industries Inc site
    Open intranet site
    # Fill in the dummy order into the site
    FOR    ${order}    IN    @{ROBOT_ORDERS}
        Log    ${order}
        Wait Until Keyword Succeeds
        ...    ${ENV_JSON}[rb_retry_limit]
        ...    ${ENV_JSON}[rb_retry_interval]
        ...    Fill the form and Submit the order    ${order}
        Sleep    5
        Run Keyword And Continue On Failure    Get Receipt and Save Screenshot in PDF    ${order}[Order number]
        # Create Error Log File    ${order}[Order number]_Error.pdf
        Order Another Robot
    END
    # create zipped folder of all PDFs
    Create Archived File of receipts
    # Close the browser
    [Teardown]    Close the Browser

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
    # Log    ${ROBOT_SPECS}

Open intranet site
    # Log    Opening ${ENV_JSON}[rb_order_website]
    Open Available Browser    ${ENV_JSON}[rb_order_website]
    # Click on OK alert button
    Remove Annoying alert
    Maximize Browser Window

Remove Annoying alert
    Wait Until Element Is Visible    ${POPUP_OK_BUTTON_SELECTOR}
    ${button_visible}=    Is Element Visible    ${POPUP_OK_BUTTON_SELECTOR}
    IF    ${button_visible}
        Click Button    OK
    END

Download Orders CSV File
    [Arguments]    ${url}
    @{orders}=    Split String From Right    ${url}    /    1
    Set Global Variable    ${ORDERS_FILE}    ${orders}[1]
    Download    ${url}    target_file=${orders}[1]    overwrite=${True}

Read Orders from CSV File
    ${orders}=
    ...    Read table from CSV
    ...    ${ORDERS_FILE}
    ...    header=True
    ...    delimiters=,
    [Return]    ${orders}

Fill the form and Submit the order
    [Arguments]
    ...    ${robot_specs}
    ${order_number}    Set Variable    ${robot_specs}[Order number]
    ${head_value}    Set Variable    ${robot_specs}[Head]
    ${body_value}=    Format String    ${BODY_SELECTOR_VALUE}    ${robot_specs}[Body]
    ${legs_value}    Set Variable    ${robot_specs}[Legs]
    ${address_value}    Set Variable    ${robot_specs}[Address]
    # Log    Order Number=${order_number}, Head=${head_value}, Body=${body_value}, Legs=${legs_value}, Address=${address_value}
    Select From List By Value    ${HEAD_SELECTOR}    ${head_value}
    Select Radio Button    ${BODY_SELECTOR_GROUP}    ${body_value}
    Input Text    ${LEGS_SELECTOR}    xpath:${legs_value}
    Input Text    ${ADDRESS_SELECTOR}    ${address_value}
    Click Button    Preview
    Click Button    Order
    Wait Until Element Is Visible    ${RECEIPT_SELECTOR}
    Assert Submit Order

Assert Submit Order
    Page Should Not Contain Element    ${ERROR_MESSAGE_SELECTOR}
    Page Should Contain Element    ${RECEIPT_SELECTOR}
    Element Should Contain    ${RECEIPT_SELECTOR}    Receipt

Get Receipt and Save Screenshot in PDF
    [Arguments]
    ...    ${order_number}
    Wait Until Element Is Visible    ${RECEIPT_SELECTOR}
    ${Message}=    Get Text    ${RECEIPT_SELECTOR}
    Preview and Take Screenshot of Robot    ${order_number}.png
    Create Order Receipt in PDF    ${order_number}    ${Message}    ${OUTPUT_DIR}${/}${order_number}.png

Preview and Take Screenshot of Robot
    [Arguments]
    ...    ${filename}
    ${file_exists}=    Does File Exist    $filename
    IF    ${file_exists}
        RPA.FileSystem.Remove File    ${OUTPUT_DIR}${/}${filename}
    END
    Screenshot    ${PREVIEW_SELECTOR}    ${OUTPUT_DIR}${/}${filename}
    Assert File is present or not    ${OUTPUT_DIR}${/}${filename}

Assert File is present or not
    [Arguments]
    ...    ${filepath}
    File Should Exist    ${filepath}

Order Another Robot
    ${available_button}=    Is Element Visible    ${ENV_JSON}[order_another_btn_selector]
    IF    ${available_button}
        Click Button    ${ENV_JSON}[order_another_btn_selector]
        Wait Until Element Is Visible    ${HEAD_SELECTOR}
    END
    Remove Annoying alert

Create Order Receipt in PDF
    [Arguments]
    ...    ${order_number}
    ...    ${message}
    ...    ${screenshot_filepath}
    @{message_list}=    Split To Lines    ${message}
    ${template_html}=    Read File    ${HTML_TEMPLATE_FILE}
    # Log    ${message_list}
    # Log    ${template_html}
    ${template_text}=    Format String
    ...    ${template_html}
    ...    ${order_number}
    ...    ${message_list}[1]
    ...    ${message_list}[2]
    ...    ${message_list}[3]
    ...    ${message_list}[4]
    ...    ${message_list}[5]
    ...    ${message_list}[6]
    ...    ${message_list}[7]
    ...    ${screenshot_filepath}
    # Log    ${template_text}
    Convert HTML to PDF
    ...    ${order_number}.pdf
    ...    ${template_text}

Convert HTML to PDF
    [Arguments]
    ...    ${filename}
    ...    ${filecontent}
    ${file_exists}=    Does File Exist    ${OUTPUT_DIR}${/}${filename}
    IF    ${file_exists}
        RPA.FileSystem.Remove File    ${OUTPUT_DIR}${/}${filename}
    END
    Html To Pdf
    ...    ${filecontent}
    ...    ${OUTPUT_DIR}${/}${filename}
    Assert File is present or not    ${OUTPUT_DIR}${/}${filename}

Create Error Log File
    [Arguments]    ${filepath}
    Touch File    ${filepath}

Create Archived File of receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    ${zip_folder_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs
    ${folder_exists}=    Does Directory Exist    ${zip_folder_name}
    IF    ${folder_exists} == ${true}
        RPA.FileSystem.Remove Directory    ${zip_folder_name}    recursive=true
        RPA.FileSystem.Create Directory    ${zip_folder_name}
    ELSE
        RPA.FileSystem.Create Directory    ${zip_folder_name}
    END
    ${pdf_files}=    List Directory    path=${OUTPUT_DIR}    pattern=*.pdf
    FOR    ${pdf_file}    IN    @{pdf_files}
        # Log    ${OUTPUT_DIR}${/}${pdf_file}
        RPA.FileSystem.Move File
        ...    ${OUTPUT_DIR}${/}${pdf_file}
        ...    ${zip_folder_name}${/}${pdf_file}
    END
    Archive Folder With Zip    ${zip_folder_name}    ${zip_file_name}

Get Orders URL from User
    Add heading    Provide URL for the orders CSV file
    Add text input    fileUrl    label=Orders File URL
    ${result}=    Run dialog    title=Enter URL
    [Return]    ${result.fileUrl}

Notify User with Default Value
    [Arguments]    ${message}
    Add icon    Success
    Add heading    ${message}
    Run dialog    title=Information

Access Secret Vaults
    ${secret}=    Get Secret    credentials
    Notify User with Default Value    Fetching Secrets from Vault: ${secret}[username] ...

Close the Browser
    Close Browser
