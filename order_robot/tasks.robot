*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.Archive
Library           RPA.Tables
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    0.3s

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Click ok
    Download the CSV file
    ${orders}=    Read csv table
    FOR    ${Order number}    IN    @{orders}
        Get orders    ${Order number}
        Preview
        Order until success
        Make pdf    ${Order number}
        Order another
        Click ok
    END
    Create ZIP package from PDF files
    [Teardown]    Close the browser

Minimal task
    Log    Done.

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    credentials
    Open Available Browser    ${secret}[webpage]

Collect Search Query From User
    Add text input    search    label=Order CSV URL    placeholder=https://robotsparebinindustries.com/orders.csv
    ${response}=    Run dialog    title= Enter CSV URL
    [Return]    ${response.search}

Download the CSV file
    ${search_query}=    Collect search query from user
    Download    ${search_query}    overwrite=True

Read csv table
    ${order}=    Read table from CSV    orders.csv
    [Return]    ${order}

Get orders
    [Arguments]    ${Order number}
    Select From List By Value    head    ${Order number}[Head]
    Select Radio Button    body    ${Order number}[Body]
    Input Text    css:Input.form-control    ${Order number}[Legs]
    Input Text    address    ${Order number}[Address]

Preview
    Click Button    preview

Order until success
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Order

Order
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Make pdf
    [Arguments]    ${Order number}
    ${pdf_text}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Html To Pdf    ${pdf_text}    ${OUTPUT_DIR}${/}/receipts/Order${Order number}[Order number].pdf
    Open Pdf    ${OUTPUT_DIR}${/}/receipts/Order${Order number}[Order number].pdf
    ${Screenshot}=    Capture Element Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}/receipts/Order${Order number}[Order number].png
    Add Watermark Image To Pdf    ${Screenshot}    ${OUTPUT_DIR}${/}/receipts/Order${Order number}[Order number].pdf    ${pdf}
    Close Pdf

Order another
    Click Button    order-another

Click ok
    Click Button    OK

Create ZIP package from PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}/receipts    ${OUTPUT_DIR}${/}/orders.zip

Close the browser
    Close Browser
