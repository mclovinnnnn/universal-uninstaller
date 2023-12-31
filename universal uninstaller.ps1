#This ps1-script was merged with one or multiple psm1-modules, this might lead to unstructed code in some sections.

<#
.SYNOPSIS
Beschreibung des Skripts.

.DESCRIPTION
Ausführliche Beschreibung des Skripts.

.PARAMETER Parameter1
Beschreibung des Parameter1.

.PARAMETER Parameter2
Beschreibung des Parameter2.

.EXAMPLE
Beispiel für die Verwendung des Skripts.

.EXAMPLE
Ein weiteres Beispiel für die Verwendung des Skripts.

.NOTES
Zusätzliche Informationen zum Skript.

.LINK
Verweis auf weitere Informationen zum Skript.

# how to run
# .\universalSilentUninstaller.ps1 -AppName '' -AppVersion ''

#>

#region ******************** TOUCH ********************
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

Set-StrictMode -Version Latest
$ScriptDir = $PSScriptRoot
$ModuleDir = $ScriptDir + "\modules\"
$global:PSSession = $null

# Read the JSON content from the file
$configFile = "config.json"
#region ******************** TESTING ********************

#endregion TESTING
#region ******************** MODULES ********************
$modules = @(
( $ModuleDir + "gui\dyngui.psm1" ),
( $ModuleDir + "functions\functions.psm1" ),
( $ModuleDir + "guiDetailView\guiDetailView.psm1" ),
( $ModuleDir + "guiComputerView\guiComputerView.psm1" ),
( $ModuleDir + "validation\validation.psm1" )
)
#endregion MODULES
#endregion TOUCH

#region ******************** ADMIN ********************
# only change this region if necessary. e.g. add more modules or init-folders
function Main {
    Requirements
    Work
    Cleanup
}

Function Requirements {
    try {
        Start-Transcript -Path ($MyInvocation.PSCommandPath + ".log")

        foreach ($module in $modules) {
        }

    }
    catch {
        "FATAL - initialisation not passed - Error at line " + $_.InvocationInfo.ScriptLineNumber + ": " + $_.Exception.Message | Out-File -FilePath ($MyInvocation.PSCommandPath + "_error.log") -Force
        Cleanup
    }
}

# clear variables and console output, remove modules
Function Cleanup {
    try {
        Stop-Transcript
        Get-Module | Remove-Module -Force -ErrorAction SilentlyContinue
        Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
        Get-PSSession | Remove-PSSession  -ErrorAction SilentlyContinue
        Get-Variable -Exclude exitCode, PWD, *Preference | Remove-Variable -Force -ErrorAction SilentlyContinue
        exit

    }
    catch {
        exit 1
    }
}
#endregion ADMIN

#region ******************** WORK ********************
# put your code into the try block, clone the function if needed.
Function Work {
    param(
        $LogText
    )
    try {

        $form, $formItems = Add-Form
        Add-FormAction -formItems $formItems -form $form
        $form.ShowDialog()

    }
    catch {
        Write-Error ("FAIL - $LogText - Error at line " + $_.InvocationInfo.ScriptLineNumber + ": " + $_.Exception.Message)

    }
    finally {
        Cleanup
    }
}

function Add-Form {
    # Erstellen eines neuen Windows-Formulars
    $form = New-Object System.Windows.Forms.Form
    $form.Size = New-Object System.Drawing.Size(1200, 600)
    $form.MinimumSize = $form.Size
    $form.Icon = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new((Get-Base64)).GetHIcon()))


    $form.Text = "Universal Uninstaller"
    $form.KeyPreview = $true
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    # Create the table layout panel
    $mainPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $mainPanel.Dock = 'Fill'
    $mainPanel.Name = "mainPanel"

    $mainPanel.Padding = New-Object System.Windows.Forms.Padding(10, 25, 10, 25)


    $formItems = @{
        ConnectArea  = New-ConnectArea -mainPanel $mainPanel
        OutputArea   = New-OutputArea -mainPanel $mainPanel
        CommandArea  = New-CommandArea -mainPanel $mainPanel
        TableActions = New-TableAction -mainPanel $mainPanel
        Table        = New-Table -mainPanel $mainPanel
        Footer       = New-Footer -mainPanel $mainPanel


        ProgressBar  = New-ProgressBar
        MenuStrip    = (New-MenuStrip).GetEnumerator() | Select-Object -Last 1

    }

    foreach ($item in $formItems.GetEnumerator() | Where-Object { $_.Name -in "ProgressBar", "MenuStrip" }) {
        foreach ($formItem in $item.Value) {
            foreach ($item in $formItem.GetEnumerator()) {
                $form.Controls.Add($item.Value)
            }
        }
    }


    $form.Controls.Add($mainPanel)
    return $form, $formItems
}

function Add-FormAction {
    param (
        $formItems,
        $form
    )


    New-ExitButtonAction -ExitButton ($formItems.Footer.ExitButton) -form $form
    New-MenuStripAction -menuStrip ($formItems.menuStrip.menuStrip) -form $form

    if ((Test-PreRequirement -ouputTextBox ($formItems.OutputArea.ouputTextBox) -requiredVersion "5.1" -requireAdminRights $true )) {

        New-SearchBoxAction -filterTextBox ($formItems.TableActions.filterTextBox)
        New-TableCellClick  -table ($formItems.Table.Table)
        New-TextBoxPopOutFormAction -popOutLabel ($formItems.OutputArea.popOutLabel)
        New-ConectButtonAction -ConectButton ($formItems.ConnectArea.ConnectButton)
        New-SaveButtonAction -SaveButton ($formItems.Footer.saveButton)
        New-UninstallButtonAction -UninstallButton ($formItems.TableActions.UninstallButton)
        New-F5ButtonAction
        New-PWSHCheckBoxChange
        New-InvokeButtonAction -InvokeButton ($formItems.CommandArea.invokeButton)
        New-CommandBoxPopOutFormAction


    }
}

function New-ConectButtonAction {
    param(
        [parameter(Mandatory = $true)]$ConectButton
    )
    $global:ConnectTextlastEntries = New-Object System.Collections.Generic.List[string]

    $ConectButton.Add_Click({
            try {
                $debugMode = Get-ConfigValue -configFile $configFile -configPart "debugMode"
                if ($debugMode) { $targetComputer = Get-ConfigValue -configFile $configFile -configPart "TargetComputer" }
                if ($formItems.ConnectArea.HostnameBox.Text -or $debugMode) {
                    if (!$debugMode) {$targetComputer = $formItems.ConnectArea.HostnameBox.Text}

                    $displaybox = $formItems.OutputArea.ouputTextBox
                    Get-PSSession | Remove-PSSession  -ErrorAction SilentlyContinue
                    Set-DisplayBoxText -displayBox $displaybox -text "Please wait while a connection to $targetComputer is established ..."

                    $global:PSSession = New-PSSession -ComputerName $targetComputer

                    if (!$PSSession) {
                        Set-DisplayBoxText -displayBox $displaybox -text "No connection could be established to with the current credentials. Please provide administrator credentials for $targetComputer" -isError $true
                        [PSCredential]$credential = Get-Credential
                        $global:PSSession = New-PSSession -ComputerName $targetComputer -Credential $credential
                    }
                    if (!$PSSession) {
                        Set-DisplayBoxText -displayBox $displaybox -text "Please wait while a connection to $targetComputer is established ..."
                        Enable-PsRemoting -ComputerName $targetComputer -credential $credential
                        $global:PSSession = New-PSSession -ComputerName $targetComputer -Credential $credential
                    }

                    if ($PSSession) {
                        Set-DisplayBoxText -displayBox $displaybox -text ("Successfully connected to $targetComputer.")
                        Set-ConnectedTo -menuItem $formItems.menuStrip.menuStrip.Items[1] -text ("Connected to: $targetComputer")
                        $InstalledApps = Invoke-Command -Session $PSSession -ScriptBlock ${function:Get-InstalledApp}
                        Update-TableContent -tableContent $InstalledApps -table ($formItems.Table.Table)
                        Start-SystemInfo
                    }
                    else { Set-DisplayBoxText -displayBox $displaybox -text ($error[0].ErrorDetails) -isError $true }

                    $formItems.CommandArea.commandBox.Clear()
                    $formItems.TableActions.filterTextBox.Clear()
                    Set-LastEntry -text $displaybox.Text -lastEntries $ConnectTextlastEntries -autoCompleteSource ($formItems.ConnectArea.HostnameBox.AutoCompleteCustomSource)
                }
            }
            catch {
                Set-DisplayBoxText -displayBox $displaybox -text $_.Exception.Message -isError $true
            }
        })
}

function New-InvokeButtonAction {
    param (
        $InvokeButton
    )

    $global:CommandlastEntries = New-Object System.Collections.Generic.List[string]

    $InvokeButton.Add_Click({
            try {

                if ($PSSession -and $PSSession.Availability -eq "Available" -and ($formItems.CommandArea.commandBox.Text -or $formItems.CommandArea.mlcommandBox.Text)) {

                    if ($formItems.CommandArea.commandBox.Text) {
                        $command = $formItems.CommandArea.commandBox.Text
                    }
                    elseif ($formItems.CommandArea.mlcommandBox.Text) {
                        $command = $formItems.CommandArea.mlcommandBox.Text
                    }


                    Set-LastEntry -text $formItems.CommandArea.commandBox.Text -lastEntries $CommandlastEntries -autoCompleteSource $formItems.CommandArea.commandBox.AutoCompleteCustomSource

                    $exitcode = Invoke-CustomCommand `
                        -command ($command) `
                        -progressBar ($formItems.ProgressBar.ProgressBar) `
                        -type "c_command" `
                        -radioButtonPWSH (($formItems.CommandArea.radioButtonPWSH).Checked)

                    Set-DisplayBoxText -displayBox ($formItems.OutputArea.ouputTextBox) -text $exitcode


                }

            }
            catch {
                Set-DisplayBoxText -displayBox ($formItems.OutputArea.ouputTextBox) -text $_.Exception.Message -isError $true
            }


        })
}

function New-UninstallButtonAction {
    param(
        $UninstallButton
    )
    $UninstallButton.Add_Click({
            try {
                if ($PSSession -and $PSSession.Availability -eq "Available") {
                    $selectedRow = ($formItems.Table.Table).selectedRows[0]
                    $selectedItemName = $selectedRow.Cells["Name"].Value

                    if ($selectedItemName) {
                        $result = [System.Windows.Forms.MessageBox]::Show("Do you want to uninstall '$selectedItemName' ?", "Confirm", "YesNo", "Question")
                        if ($result -eq "Yes") {
                            Invoke-KillProcess -displayName $selectedItemName -ErrorAction SilentlyContinue
                            $exitcode = Invoke-SilentUninstallString `
                                -command ($selectedRow.Cells["Uninstallstring"].Value) `
                                -progressBar ($formItems.ProgressBar.ProgressBar) `
                                -type ($selectedRow.Cells["Type"].Value)

                            switch ($exitcode) {
                                124 { $text = ("The uninstaller ran into a timout of" + (Get-ConfigValue -configFile $configFile -configPart "TargetComputer") + " seconds. This value can be changed in the config.json file. Please verify that " + ($selectedRow.Cells["Uninstallstring"].Value) + " is the correct uninstallstring for the product $selectedItemName.") }
                                0 { $text = ("The product $selectedItemName was uninstalled successful.") }
                                1 { $text = ("Error while uninstalling $selectedItemName. Please verify that " + ($selectedRow.Cells["Uninstallstring"].Value) + " is the correct unintallstring for the product ") }
                                Default { $text = ("Unkown Status") }
                            }

                            $testApp = (Invoke-Command -Session $PSSession -ScriptBlock ${function:Get-InstalledApp} -ArgumentList $selectedItemName)

                            if ($exitcode -eq 0 -and !$testApp) {
                                [System.Windows.Forms.MessageBox]::Show("Uninstallation successful.", "Ok", "OK", "Information")
                                Set-DisplayBoxText -displayBox ($formItems.OutputArea.ouputTextBox) -text $text

                                Get-Table -table ($formItems.Table.Table)
                                $formItems.TableActions.filterTextBox.Clear()

                            }
                            else {
                                [System.Windows.Forms.MessageBox]::Show("Uninstallation not successful.", "Error", "OK", "Hand")
                                Set-DisplayBoxText -displayBox ($formItems.OutputArea.ouputTextBox) -text $text -isError $true
                                $formItems.TableActions.filterTextBox.Clear()

                            }
                        }
                    }
                    else {
                        [System.Windows.Forms.MessageBox]::Show("No element selected.", "Warning", "OK", "Warning")
                    }

                }

            }
            catch {
                Set-DisplayBoxText -displayBox ($formItems.OutputArea.ouputTextBox) -text $_.Exception.Message -isError $true
            }
        })
}

Function New-MenuStripAction {
    param (
        $menuStrip
    )

    $menuStrip.Items["FileMenu"].DropDownItems["exitButton"].Add_Click({
            $form.Close()
        })

    $menuStrip.Items["FileMenu"].DropDownItems["aboutButton"].Add_Click({

        })

    $menuStrip.Items["FileMenu"].DropDownItems["donateButton"].Add_Click({

        })


    $menuStrip.Items["connectedTo"].Add_Click({

            if ($PSSession) {
                $systemInfo = Get-SystemInfo
                if ($systemInfo) {
                    New-ComputerViewForm -systemInfo $systemInfo -OutputArea ($formItems.OutputArea.detailPanel)
                }
            }
        })

    Set-ConnectedTo -menuItem $menuStrip.Items[1] -text ("Connected to: none")
}

function New-SearchBoxAction {
    param (
        $filterTextBox
    )
    $filterTextBox.Add_TextChanged({
            $keyword = ($formItems.TableActions.filterTextBox).Text
            foreach ($row in ($formItems.Table.Table).Rows) {
                if ($row.IsNewRow) {
                    continue
                }
                $match = $false
                foreach ($cell in $row.Cells[0]) {
                    if ($cell.Value.ToString() -like "*$keyword*") {
                        $match = $true
                        break
                    }
                }
                $row.Visible = $match
            }
        })
}


function New-TextBoxPopOutFormAction {
    param (
        $popOutLabel,
        $icon
    )

    $popOutLabel.Add_Click({
            if ($formItems.OutputArea.ouputTextBox.Text) {
                New-TextBoxPopOutForm -text ($formItems.OutputArea.ouputTextBox.Text) -icon (Get-Base64)
            }
        })
}

function New-CommandBoxPopOutFormAction {
    param (
    )

    $formitems.CommandArea.popOutLabel.Add_Click({
            $commandBox = $form.controls[2].controls[2].controls[0].controls[1]
            $mlcommandBox = $form.controls[2].controls[2].controls[0].controls[2]

            $commandBox.Visible = $false
            $mlcommandBox.Text = $commandBox.Text
            $commandBox.Clear()
            $mlcommandBox.Visible = $true
        })

    $formitems.CommandArea.mlPopOutLabel.Add_Click({
            $commandBox = $form.controls[2].controls[2].controls[0].controls[1]
            $mlcommandBox = $form.controls[2].controls[2].controls[0].controls[2]

            $mlcommandBox.Visible = $false
            $commandBox.Text = $mlcommandBox.Text
            $mlcommandBox.Clear()
            $commandBox.Visible = $true
        })
}

function New-PWSHCheckBoxChange {

    $commands = Get-Command
    $global:pwshCommands = $commands | Where-Object { $_.Module -like "Microsoft.Powershell*" } | Select-Object Name

    Set-PWSHCommandAutoComplete -autoCompleteSource ($formItems.CommandArea.commandBox.AutoCompleteCustomSource) -pwshCommands $pwshCommands
    ($formItems.CommandArea.radioButtonPWSH).add_CheckedChanged({

            if (($formItems.CommandArea.radioButtonPWSH).Checked) {
                Set-PWSHCommandAutoComplete -autoCompleteSource ($formItems.CommandArea.commandBox.AutoCompleteCustomSource) -pwshCommands $pwshCommands
            }
            else {
                ($formItems.CommandArea.commandBox.AutoCompleteCustomSource).Clear()
                ($formItems.CommandArea.commandBox.AutoCompleteCustomSource).AddRange($CommandlastEntries)
            }

        })
}

function New-TableCellClick {
    param (
        $table
    )

    $table.Add_CellClick({

            New-DetailViewForm -table ($formItems.Table.Table) -icon (Get-Base64) -OutputArea ($formItems.OutputArea.detailPanel)

        })


}

function New-SaveButtonAction {
    param (
        $saveButton
    )
    $saveButton.Add_Click({
            try {
                $table = ($formItems.Table.Table)
                if ($PSSession -and $PSSession.Availability -eq "Available" -and ($table.Rows[0])) {
                    $csvPath = New-SaveFileDialog -table $table
                    if ($csvPath) {
                        Set-DisplayBoxText -displayBox ($formItems.OutputArea.ouputTextBox) -text ("Data saved to $csvPath" )
                    }
                }
            }
            catch {
                $logMessage = "FAIL - Error: " + $_.Exception.Message
                Set-DisplayBoxText -displayBox ($formItems.OutputArea.ouputTextBox) -text $logMessage -isError $true
            }
        })
}

function New-ExitButtonAction {
    param (
        $form,
        $ExitButton
    )

    $ExitButton.Add_Click({

            Close-Form -form $form

        })
}

function New-F5ButtonAction {
    param (
      )


    $form.Add_KeyDown({
            if ($_.KeyCode -eq "F5") {
                Get-Table -table ($formItems.Table.Table)
            }
        })
}

#endregion WORK

<#
   .< help keyword>
   < help content>
   . . .
   #>

#region LOGGING

Set-StrictMode -Version Latest

function Get-Base64 {

    $iconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADqYAAAOp
gAABdwnLpRPAAAAkxQTFRFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////KI4PAAAAAMJ0Uk5TAAEPOWqiwdrj9f7AaTgRSJHD7v359Oni7cSSAiZ9yPf616x2WUEpISBad67Zx3gjJYnfzoJHGgQFG4bR+92I3POqUB
UXVdhxPLr8q0MJCkWv+LkHbeXNVwsMXdNnEpD2lB6ej6boZmzqoRZLp9JlxUxAWELejH9R62Q9bzcIn7LMH2tftIBEs3BJDc+Dm5OF4Jw6Y3rxjoe+KltgvfBosWIcXNDGVLUk2618YdQiuJqgcjJNT9
U+TpcOE53kBkqwMYTIEUSQAAAAAWJLR0TDimiOQgAAAAlwSFlzAAA7DgAAOw4BzLahgwAABCxJREFUWMOdl/9fU1UYx5/tgrs76gbbvQMZtPFlDHQ6hGUDJwxbUNhgE02mzFkpCtMwm7GAxCI1IgKhpn
wJdRSYZdEXw6ysnr+suzXbF3a3e3d+2Dn3Oa/3Z+d5zrnPPQ9A2iaRUnn5W2S0nBA5Lduav227VALCm0JZUKhSo5phNXSRhmW4YfGOEqVCGK0tLXtOh/ryisoqA1VtrKmmDLU7d5n0qNu9x6zNikvq9t
ajvsHy/L4XEs3WRmXTfhs50GzOtvjKFrS3HnwxjcMSx0u7WGxrz+SI5OVXOnSHXnXyzXd2udwdhynecHYfOYqvHevJtELP8RNI93ann/Se9OlOvZ4tSOY33PI307rhOE3O9Dmz8ZwfZ8+p+wfS8IdQ5s
9+WLQerfZgPZ7fpOA9jReo7H+vfWvwIsDbbdif4kX3STQJ4XtV+ktc/06AXE6O5BGdxi+IZ96NhmkoqHsvcWb4qLtPDA+SEYYeTQjAYTz1vhgewHkFx+JhqMSrH4jjufOwn3z4bFwqcx8TywOMM6a62H
AvtvaI5sHzEV6LLSBgvy6eB7jIBkqjgzJszRbBdDw4b+DHkd67u2MoFx6gVj0Y2YgJpiF+sD8ZlQrmwTHp7uK6Avw0butjp7xCeYDPcBpAWmhTxk3DM+SmVygPfluhFGZV5Y0JNmWqQgYeGstVs5CHFU
n5N1WhSqUv40szVheZg3ysTLamKHyOX/BvUghvwRashUwKiikyM8EnMI63QeY2QM4KBkYGtH1zJhKsQLE0yM9UQ84K8xoWsKgGclYw0oRHQKCCkUaQa6ohZ4WICzTLk84nBCjMskUgYwyQs0JkG7fiAu
SssIhL3FHeyScAQ1+SXsikEMImWCYuKw/vnNYHE171zQrWO+QuUMVt93j4Jia4kHSrSlW4ZyrenpJQMvKcwk0yk7Bp0YTCpbRpoTyXgad84fhTCVq4X6V70iGU59ZAxbOuYyWaVBVfqb8WzCe1MNkR/b
7uwQpnLnznKo5EB2stqZ82QTz42fuxe2szftMjnves4oPY0FzOLIjm4Vv9d8Zn43ay8lAsv3ZBvfz/g+J7/MEpju9cR1fCZ3SWdi+L4iU/MvU/JRp6fZqfRfDwS5A9nmToDpGWYa7fphfEGwJqS8o7rO
jHR78CbCxdEsKb8PFvqcaB83h/Q6J1CvB/4wBeebLZPrBOzp0VcN13tgfVj5+km1Fc9ul+r8nGm9d1dos0/Vz33B84Ge7MhHsWT2B9+E9e70ZvdPjGnvJe+pxPV922v/7OVJYo8kxoH6tKW/YNhFft+G
hZChmbZO1agOgbCvz7kvbZ2ugvWbGRlgdZY8TdqupGBrnSt80VGjdQ80bjPGVYDN2JlL6DIw8FVuCKrn8ixTeJFN90rPgutFwXWHz/54mUmrt1O1r+s0Wypea7FF/5/y9Z4TxUNDmqzgAAACV0RVh0ZG
F0ZTpjcmVhdGUAMjAyMC0wMi0xMlQxNzoyMzozNCswMDowMFHJSD8AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjAtMDItMTJUMTc6MjM6MzQrMDA6MDAglPCDAAAARnRFWHRzb2Z0d2FyZQBJbWFnZU1hZ2
ljayA2LjcuOC05IDIwMTktMDItMDEgUTE2IGh0dHA6Ly93d3cuaW1hZ2VtYWdpY2sub3JnQXviyAAAABh0RVh0VGh1bWI6OkRvY3VtZW50OjpQYWdlcwAxp/+7LwAAABh0RVh0VGh1bWI6OkltYWdlOj
poZWlnaHQANTEywNBQUQAAABd0RVh0VGh1bWI6OkltYWdlOjpXaWR0aAA1MTIcfAPcAAAAGXRFWHRUaHVtYjo6TWltZXR5cGUAaW1hZ2UvcG5nP7JWTgAAABd0RVh0VGh1bWI6Ok1UaW1lADE1ODE1Mj
gyMTS8W5itAAAAE3RFWHRUaHVtYjo6U2l6ZQAxNS42S0JC58sE1gAAAFB0RVh0VGh1bWI6OlVSSQBmaWxlOi8vLi91cGxvYWRzLzU2L0k4ZHFXamEvMjE1My9yb3VuZF9yZW1vdGVfZGVza3RvcF9pY2
9uXzEzMjc4MS5wbmd3Pbe6AAAAAElFTkSuQmCC'

    $iconBytes = [Convert]::FromBase64String($iconBase64)

    $stream = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)
    return $stream


}

Function Get-ConfigValue{
    param (
        $configFile,
        $configPart
    )

    $config = ConvertFrom-Json (Get-Content -Raw -Path $configFile)
    return ($config.$configPart)
}

Function Set-DisplayBoxText {
    param (
        $displayBox,
        $text,
        $isError
    )
    $displayBox.Clear()
    $displayBox.AppendText($text)
    if ($isError) {
        Write-Error $text
        $displayBox.ForeColor = "Red"
    }
    else {
        $displayBox.ForeColor = "Black"
    }

}
function Set-ConnectedTo {
    param (
        $menuItem,
        $text
    )

    $menuItem.text = $text
}

function Enable-PsRemoting {
    param (
        $ComputerName,
        [PSCredential]$Credential
    )
    try {
        $session = New-CimSession -ComputerName $ComputerName -Credential $Credential
        Invoke-CimMethod -CimSession $session -Namespace "root/cimv2" -ClassName "Win32_Process" -MethodName "Create" -Arguments @{CommandLine = "powershell.exe -Command Enable-PSRemoting -Force -SkipNetworkProfileCheck" }
        $session | Remove-CimSession
        Start-Sleep -Seconds 5
    }
    catch {    }


}

Function Get-InstalledApp {
    param(
        [parameter(Mandatory = $false)][string]$LogText,
        [Parameter(Position = 0)]$AppName
    )
    if (!$AppName) {
        $AppName = "*"
    }

    $AppVersion = $null

    $UninstallObejct = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*
    $32BitUninstallObejct = $UninstallObejct | Select-Object  DisplayName, DisplayVersion, Publisher, @{Name = "ProductID"; Expression = { $_.PSChildName } }, UninstallString, QuietUninstallString, Type, @{Name = "Context"; Expression = { "x32" } } `
    | Where-Object { if ($AppVersion) { $_.DisplayName -like $AppName -AND $_.DisplayVersion -like $AppVersion } else { $_.DisplayName -like $AppName } }

    $UninstallObejct = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
    $64BitUninstallObejct = $UninstallObejct | Select-Object DisplayName, DisplayVersion, Publisher, @{Name = "ProductID"; Expression = { $_.PSChildName } }, UninstallString, QuietUninstallString, Type, @{Name = "Context"; Expression = { "x64" } } `
    | Where-Object { if ($AppVersion) { $_.DisplayName -like $AppName -AND $_.DisplayVersion -like $AppVersion } else { $_.DisplayName -like $AppName } }

    $UninstallObejct = Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*
    $UninstallObejctUser = $UninstallObejct  | Select-Object DisplayName, DisplayVersion, Publisher, @{Name = "ProductID"; Expression = { $_.PSChildName } }, UninstallString, QuietUninstallString, Type, @{Name = "Context"; Expression = { "User" } } `
    | Where-Object { if ($AppVersion) { $_.DisplayName -like $AppName -AND $_.DisplayVersion -like $AppVersion } else { $_.DisplayName -like $AppName } }


    if ($64BitUninstallObejct -or $32BitUninstallObejct -or $UninstallObejctUser) {


        $UninstallObejcts = (@($32BitUninstallObejct) + @($64BitUninstallObejct) + @($UninstallObejctUser))

        foreach ($object in $UninstallObejcts) {
            if ($object.QuietUninstallString) {
                $object.Type = "Quiet"
            }
            elseif ($object.UninstallString -like "msiexec*" -AND $object.ProductID -like "{*}") {
                $object.Type = "MSI"
                $object.QuietUninstallString = "/qn /x " + '"' + $object.ProductID + '"' + " /norestart"
            }
            else {
                $object.Type = "N/A"
            }


        }
        return $UninstallObejcts
    }
    else {
    }

}

function Invoke-KillProcess {
    param (
        $displayName
    )

    Invoke-Command -Session $PSSession -ScriptBlock {
        $processes = Get-Process
        $processesToStop = $processes | Where-Object { $using:displayName -like "*" + $_.ProcessName + "*" }
        $processesToStop | Stop-Process -Force
    } -ErrorAction SilentlyContinue
}

function Get-SystemInfo {

    $systemInfo = Receive-Job -name "systemInfo" -Keep
    return $systemInfo
}
function Start-SystemInfo {

    Invoke-SystemInfo
}

function Invoke-SystemInfo {

    $SystemInfo = Invoke-Command -Session $PSSession -ScriptBlock {

        $systemInfo = @{}

        $Memory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum / 1gb
        $Memory = $Memory.ToString() + " GB"
        $systemInfo.Add("Memory", $Memory)

        $CPU = (Get-CimInstance -Class Win32_Processor | Select-Object -Property Name).Name
        $systemInfo.Add("CPU", $cpu)

        $OSInfo = Get-CimInstance -Class Win32_OperatingSystem | Select-Object -Property Caption, CSName, BuildNumber, OSArchitecture
        $systemInfo.Add("OSInfo",  $OSInfo)

        $BiosInfo =  Get-CimInstance Win32_BIOS | Select-Object -Property Manufacturer, SerialNumber
        $systemInfo.Add("BiosInfo",  $BiosInfo)

        $Disk = (Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DeviceID -like "C:"} | Measure-Object -Property Size -Sum).Sum / 1gb
        $Disk = [math]::Round($disk).ToString() + " GB"
        $systemInfo.Add("Disk",  $Disk)

        $IPInfo = Get-CimInstance win32_networkadapterconfiguration | Where-Object {$null -ne $_.IPAddress} | Select-Object MACAddress, IPAddress -First 1
        $systemInfo.Add("IPInfo",  $IPInfo)

        return $systemInfo

    } -AsJob -JobName "SystemInfo"

}

Function Invoke-SilentUninstallString {
    param(
        $command,
        $progressBar,
        $type
    )
    try {
        if ($type -like "MSI") {

            $job = Invoke-Command -Session $PSSession -ScriptBlock `
            { (Start-Process -FilePath msiexec.exe -ArgumentList $using:command -Wait -Passthru -WindowStyle Hidden ) } -AsJob
        }
        elseif ($type -like "Quiet") {
            $regex = '"(.*?)"\s(.*)'
            $match = $command -split $regex

            $executable = $match[1]
            $argument = $match[2]

            $job = Invoke-Command -Session $PSSession -ScriptBlock `
            { (Start-Process -FilePath $using:executable -ArgumentList $using:argument -Wait -Passthru -WindowStyle Hidden ) } -AsJob

        }

        else {
            Remove-Job -Job $job
            return 1
        }

        $progressBarStatus = Set-ProgressBar -progressBar $progressBar -job $job
        if ($progressBarStatus -ne 124) {
            return ($job.ChildJobs[0].Output[0].ExitCode)
        }
        else {
            Remove-Job -Job $job
            return $progressBarStatus
        }
    }
    catch {

    }
}

Function New-SaveFileDialog {
    param($table)

    # Open save file dialog
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "CSV files (*.csv)|*.csv"
    $saveFileDialog.Title = "Save File"

    if ($saveFileDialog.ShowDialog() -eq 'OK') {
        $csvPath = $saveFileDialog.FileName
        # Export the data to a CSV file
        $headerRow = $table.Columns | ForEach-Object { $_.Name }
        $headerRow -join ";" | Out-File -Encoding UTF8 -FilePath $csvPath

        $rows = $table.Rows
        $rows | ForEach-Object {
            $rowData = $_.Cells | ForEach-Object { $_.Value }
            $rowData -join ";" | Out-File -Append -Encoding UTF8 -FilePath $csvPath
        }
        return $csvPath
    }

}

function Invoke-CustomCommand {
    param (
        $command,
        $progressBar,
        $type,
        $radioButtonPWSH
    )

    if ($type -like "c_command") {
        if ($radioButtonPWSH -eq $true) {
            $job = Invoke-Command  -Session $PSSession -ScriptBlock `
            { (powershell.exe -WindowStyle hidden "$using:command" 2>&1 ) } -AsJob

        }
        else {
            $job = Invoke-Command  -Session $PSSession -ScriptBlock `
            { (cmd.exe /c "$using:command" 2>&1 ) } -AsJob
        }

        $progressBarStatus = Set-ProgressBar -progressBar $progressBar -job $job

        if ($job.State -ne "Completed") {
            $errorMsg = $job.ChildJobs[0].Error
            Write-Host "Error executing command on $remoteComputer. Error: $errorMsg" -ForegroundColor Red
        }
        if ($progressBarStatus -ne 124) {
            $output = $job.ChildJobs[0].Output | Out-String

            $decodedString = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes($output))

            Remove-Job -Job $job
            return $decodedString
        }
        else {
            Remove-Job -Job $job
            return $progressBarStatus
        }
    }
    else {
        return 1
    }

}

Function Set-ProgressBar {
    param (
        $job,
        $progressBar
    )
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()

    while ($job.State -ne 'Completed') {
        $progressBar.Style = "Marquee"
        [System.Windows.Forms.Application]::DoEvents()
        if ($stopwatch.Elapsed.TotalSeconds -gt (Get-ConfigValue -configFile $configFile -configPart "Timeout")) {
            $stopwatch.Stop()
            $progressBar.Style = "Continuous"
            Get-Job | Remove-Job -Force -ErrorAction SilentlyContinue
            return 124
        }
    }

    $stopwatch.Stop()
    $progressBar.Style = "Continuous"

}

Function Get-Table {
    param( $table
    )

    if ($PSSession -and $PSSession.Availability -eq "Available") {

        $table.Rows.Clear()
        $InstalledApps = Invoke-Command -Session $PSSession -ScriptBlock ${function:Get-InstalledApp}
        Update-TableContent -tableContent  $InstalledApps -table $table

    }
}

function Set-LastEntry {
    param (
        $text,
        $lastEntries,
        $autoCompleteSource
    )


    if (-not [string]::IsNullOrWhiteSpace($text) -and (-not $lastEntries.Contains($text))) {
        $lastEntries.Add($text)


        if ($lastEntries.Count -gt 10) {
            $lastEntries.RemoveAt(0)
        }

        Update-AutoCompleteSource -autoCompleteSource $autoCompleteSource -lastEntries $lastEntries
    }

}

function Set-PWSHCommandAutoComplete {
    param (
        $autoCompleteSource,
        $pwshCommands
    )

    $filteredCommands = @();
    foreach ($item in $pwshCommands) {
        $filteredCommands += $item.Name
    }
    $autoCompleteSource.AddRange($filteredCommands)

}

function Update-AutoCompleteSource {
    param (
        $autoCompleteSource,
        $lastEntries
    )


    $autoCompleteSource.Clear()
    $autoCompleteSource.AddRange($lastEntries)

}

function Close-Form {
    param (
        $form
    )

    $form.Close()

}

function Get-CSVData {

    $openFileDialog = New-Object Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
    $result = $openFileDialog.ShowDialog()
    if ($result -eq [Windows.Forms.DialogResult]::OK) {
        $selectedFile = $openFileDialog.FileName
        if (Test-Path $selectedFile -PathType Leaf) {
            $csvData = Import-Csv -Path $selectedFile -Delimiter $config.CSVDelimiter -Header 'Hostname', 'GUID'
            if ($csvData) { return $csvData }
        }
    }
}

 <#
   .< help keyword>
   < help content>
   . . .
   #>

#region LOGGING

Set-StrictMode -Version Latest


function New-MenuStrip {
    param (
    )

    $menuStrip = New-Object System.Windows.Forms.MenuStrip
    $menuStrip.Name = "MenuStrip"
    $menuStrip.BackColor = 'AliceBlue'

    $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
    $fileMenu.Text = "File"
    $fileMenu.Name = "FileMenu"

    $connectedTo = New-Object System.Windows.Forms.ToolStripMenuItem
    #$connectedTo.Enabled = $false
    $connectedTo.Text = "connectedTo"
    $connectedTo.Name = "connectedTo"

    $connectedTo.Alignment = "Right"

    $donateButtonItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $donateButtonItem.Text = "Donate"
    $donateButtonItem.Name = "donateButton"
    $donateButtonItem.Visible = $False

    $aboutButtonItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $aboutButtonItem.Text = "About"
    $aboutButtonItem.Name = "aboutButton"
    $aboutButtonItem.Visible = $False

    $exitButtonItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exitButtonItem.Text = "Exit"
    $exitButtonItem.Name = "exitButton"

    $fileMenu.DropDownItems.Add($aboutButtonItem)
    $fileMenu.DropDownItems.Add($donateButtonItem)
    $fileMenu.DropDownItems.Add($exitButtonItem)

    $menuStrip.Items.Add($fileMenu)
    $menuStrip.Items.Add($connectedTo)

    return  @{
        menuStrip = $menuStrip
    }
}

function New-ConnectArea {
    param(
        $mainPanel
    )

    # Create the top left panel
    $l0LeftPanel = New-Object System.Windows.Forms.Panel
    $l0LeftPanel.Dock = 'Top'
    $l0LeftPanel.Name = "ConnectArea"
    $l0LeftPanel.Size = New-Object System.Drawing.Size(700, 80)
    #$l0LeftPanel.BackColor = 'Lightgray'
    $mainPanel.Controls.Add($l0LeftPanel, 0, 0)
    # Create the table layout panel
    $TableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $l0LeftPanel.Controls.Add($TableLayoutPanel)
    # Create the first label and text box
    $hostNameLabel = New-Object System.Windows.Forms.Label
    $hostNameLabel.Text = "Hostname:"
    $hostNameLabel.AutoSize = $true
    $hostNameBox = New-Object System.Windows.Forms.TextBox
    $hostNameBox.Dock = 'Fill'
    $hostNameBox.AutoCompleteMode = 'SuggestAppend' #SuggestAppend
    $hostNameBox.AutoCompleteSource = 'CustomSource'
    $hostNameBox.Size = New-Object System.Drawing.Size(200)
    # Set the autocomplete custom source
    $hostnameBoxAutoCompleteSource = New-Object System.Windows.Forms.AutoCompleteStringCollection
    $hostNameBox.AutoCompleteCustomSource = $hostnameBoxAutoCompleteSource
    # Erstellen einer SchaltflÃ¤che
    $connectButton = New-Object System.Windows.Forms.Button
    $connectButton.Text = "Connect"
    # Add the first label and text box to the table layout panel
    $TableLayoutPanel.Controls.Add($hostNameLabel, 0, 0)
    $TableLayoutPanel.Controls.Add($hostNameBox, 0, 1)
    $TableLayoutPanel.Controls.Add($connectButton, 0, 2)

    return @{
        hostNameBox   = $hostNameBox
        hostNameLabel = $hostNameLabel
        connectButton = $connectButton
    }
}

function New-OutputArea {
    param(
        $mainPanel
    )

    # Create the top panel
    $00RightPanel = New-Object System.Windows.Forms.Panel
    $00RightPanel.Dock = 'Fill'
    $00RightPanel.Name = 'OutputArea'
    #$00RightPanel.Size = New-Object System.Drawing.Size(0, 80)

   # $00RightPanel.BackColor = 'LightBlue'
    #$mainPanel.Controls.Add($l00RightPanel, 1, 0)
    $mainPanel.SetRowSpan($00RightPanel, 5)
    $mainPanel.Controls.Add($00RightPanel, 2, 0)
    # Create the table layout panel
    $TableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel

    $TableLayoutPanel.Dock = 'Fill'
    $00RightPanel.Controls.Add($TableLayoutPanel)
    # Erstellen einer Anzeigefeld
    $ouputTextBox = New-Object System.Windows.Forms.RichTextBox
    $ouputTextBox.ReadOnly = $true
    $ouputTextBox.Multiline = $true
    $ouputTextBox.Dock = 'Fill'
    $ouputTextBox.Margin = '0,0,0,15'
    $ouputTextBox.Size = New-Object System.Drawing.Size(0, 220)
    # Create a new Label control
    $ouputTextBoxLabel = New-Object System.Windows.Forms.Label
    $ouputTextBoxLabel.Text = "Output:"
    $ouputTextBoxLabel.AutoSize = $true
    # Create popOutLabel
    $popOutLabel = New-Object System.Windows.Forms.Label
    $popOutLabel.Text = "+"
    $popOutLabel.Font = New-Object System.Drawing.Font("System", 12)
    $popOutLabel.AutoSize = $true
    $popOutLabel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $popOutLabel.Dock = 'Right'

    $ouputTextBox.Controls.Add($popOutLabel)
    # Create a tooltip for the text box
    $toolTip = New-Object System.Windows.Forms.ToolTip
    $toolTip.SetToolTip($popOutLabel, "Enlarge")
    $TableLayoutPanel.Controls.Add($ouputTextBoxLabel, 0, 0)
    $TableLayoutPanel.Controls.Add($ouputTextBox, 0, 1)

    $detailPanel = New-Object System.Windows.Forms.Panel
    $detailPanel.BackColor = 'lightgray'
    $detailPanel.Dock = 'Fill'
    $TableLayoutPanel.Controls.Add($detailPanel, 0, 4)

    return @{
        ouputTextBoxLabel = $ouputTextBoxLabel
        ouputTextBox      = $ouputTextBox
        popOutLabel       = $popOutLabel
        detailPanel       = $detailPanel
    }


}

function New-TextBoxPopOutForm {
    param(
        $text
    )

    $scriptBlock = {
        param($text)
        Add-Type -AssemblyName System.Windows.Forms

        # Create a new form to show the enlarged text box
        $popOutForm = New-Object System.Windows.Forms.Form
        $popOutForm.AutoSize = $true
        $popOutForm.Name = "popOutForm"
        $popOutForm.Size = New-Object System.Drawing.Size(600, 400)
        $popOutForm.MinimumSize = New-Object System.Drawing.Size(300, 150)
        #$icon = "resources\icon.ico"
        #$popOutForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($icon)
        $popOutForm.Text = "Output"

        $enlargedTextBox = New-Object System.Windows.Forms.RichTextBox
        $enlargedTextBox.Text = $text
        $enlargedTextBox.Dock = "Fill"
        $enlargedTextBox.Multiline = $true
        $enlargedTextBox.ReadOnly = $true

        $popOutForm.Controls.Add($enlargedTextBox)

        $popOutForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $popOutForm.Add_KeyDown({
                if ($_.KeyCode -eq "Escape") {
                    $popOutForm.Close()
                }
            })
        $popOutForm.ShowDialog() | Out-Null
    }




    $newPowerShell = [PowerShell]::Create().AddScript($scriptBlock).AddArgument($text)
    $job = $newPowerShell.BeginInvoke()
    While (-Not $job.IsCompleted) {}
    $newPowerShell.EndInvoke($job)
    $newPowerShell.Dispose()

}

function New-CommandArea {
    param(
        $mainPanel
    )

    # Create the bottom panel
    $l1MiddlePanel = New-Object System.Windows.Forms.Panel
    $l1MiddlePanel.Dock = 'Fill'
    $l1MiddlePanel.Name = 'CommandArea'
    $l1MiddlePanel.Size = New-Object System.Drawing.Size(0, 100)
    #$l1MiddlePanel.BackColor = 'LightGray'
    $mainPanel.Controls.Add($l1MiddlePanel, 0, 1)
    # Create the table layout panel
    $TableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $TableLayoutPanel.Dock = 'Fill'
    # create command box
    $commandBox = New-Object System.Windows.Forms.TextBox
    $commandBox.AutoCompleteMode = 'SuggestAppend' #SuggestAppend
    $commandBox.AutoCompleteSource = 'CustomSource'
    $commandBox.ScrollBars = "Vertical"
    $commandBox.Name = "commandBox"
    $commandBox.Size = New-Object System.Drawing.Size(450, 50)
    $commandBoxAutoCompleteSource = New-Object System.Windows.Forms.AutoCompleteStringCollection
    $commandBox.AutoCompleteCustomSource = $commandBoxAutoCompleteSource
    $popOutLabel = New-Object System.Windows.Forms.Label
    $popOutLabel.Text = "+"
    $popOutLabel.Font = New-Object System.Drawing.Font("System", 12)
    $popOutLabel.AutoSize = $true
    $popOutLabel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $popOutLabel.Dock = 'Right'
    $popOutLabel.Name = 'popOutLabel'
    $commandBox.Controls.Add($popOutLabel)

    $mlCommandBox = New-Object System.Windows.Forms.TextBox
    $mlCommandBox.Multiline = $true
    $mlCommandBox.Visible = $false
    $mlCommandBox.ScrollBars = "Vertical"
    $mlCommandBox.Name = "mlCommandBox"
    $mlCommandBox.Size = New-Object System.Drawing.Size(465, 70)
    $mlPopOutLabel = New-Object System.Windows.Forms.Label
    $mlPopOutLabel.Text = "-"
    $mlPopOutLabel.Font = New-Object System.Drawing.Font("System", 13)
    $mlPopOutLabel.AutoSize = $true
    $mlPopOutLabel.Cursor = [System.Windows.Forms.Cursors]::Hand
    $mlPopOutLabel.Dock = 'Right'
    $mlPopOutLabel.Name = 'mlPopOutLabel'
    $mlCommandBox.Controls.Add($mlPopOutLabel)
    $toolTippl = New-Object System.Windows.Forms.ToolTip
    $toolTippl.SetToolTip($popOutLabel, "Enlarge")
    $toolTipmlpl = New-Object System.Windows.Forms.ToolTip
    $toolTipmlpl.SetToolTip($mlPopOutLabel, "Reduce")
    # Erzeuge ein FlowLayoutPanel
    $flowLayoutPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowLayoutPanel.Dock = "Fill"
    $flowLayoutPanel.FlowDirection = "LeftToRight"
    $flowLayoutPanel.Size = New-Object System.Drawing.Size(0, 25)
    # Create a new Label control
    $commandLabel = New-Object System.Windows.Forms.Label
    $commandLabel.Text = "Custom command:"
    $commandLabel.Anchor = "bottom"
    #$commandLabel.AutoSize = $true
    # Create the collection of radio buttons
    $radioButtonPWSH = New-Object System.Windows.Forms.RadioButton
    $radioButtonPWSH.Checked = $true
    $radioButtonPWSH.Text = "pwsh"
    $radioButtonPWSH.Size = New-Object System.Drawing.Size(50, 25)
    $radioButtonCMD = New-Object System.Windows.Forms.RadioButton
    $radioButtonCMD.Checked = $false
    $radioButtonCMD.Text = "cmd"
    $radioButtonCMD.Size = New-Object System.Drawing.Size(50, 25)
    # Erstellen einer SchaltflÃ¤che
    $invokeButton = New-Object System.Windows.Forms.Button
    $invokeButton.Text = "Invoke"
    $invokeButton.Anchor = "Right, top"
    #AddingControles
    $flowLayoutPanel.Controls.Add($commandLabel)
    $flowLayoutPanel.Controls.Add($radioButtonPWSH)
    $flowLayoutPanel.Controls.Add($radioButtonCMD)
    $TableLayoutPanel.Controls.Add($flowLayoutPanel, 0, 0)
    $TableLayoutPanel.SetColumnSpan($flowLayoutPanel, 2);
    $TableLayoutPanel.Controls.Add($commandBox, 0, 1)
    $TableLayoutPanel.Controls.Add($mlcommandBox, 0, 1)
    $TableLayoutPanel.SetColumnSpan($commandBox, 2)
    $TableLayoutPanel.SetRowSpan($commandBox, 1)
    $TableLayoutPanel.Controls.Add($invokeButton, 2, 1)

    $l1MiddlePanel.Controls.Add($TableLayoutPanel)

    return @{
        commandBox      = $commandBox
        radioButtonCMD  = $radioButtonCMD
        radioButtonPWSH = $radioButtonPWSH
        commandLabel    = $commandLabel
        invokeButton    = $invokeButton
        popOutLabel     = $popOutLabel
        mlpopOutLabel   = $mlpopOutLabel
        mlcommandBox    = $mlcommandBox
    }
}

function New-TableAction {
    param(
        $mainPanel
    )

    #Create the bottom panel
    $l2LeftPanel = New-Object System.Windows.Forms.Panel
    $l2LeftPanel.Dock = 'top'
    $l2LeftPanel.Name = 'TableAction'
    #$l2LeftPanel.BackColor = 'Lightgray'
    $l2LeftPanel.Size = New-Object System.Drawing.Size(0, 50)
    $mainPanel.Controls.Add($l2LeftPanel, 0, 2)
    $mainPanel.SetColumnSpan($l2LeftPanel, 2);
    #$tableLayoutPanel.Controls.Add($l2l1rightPanel, 0, 2)

    # Create the table layout panel
    $TableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $TableLayoutPanel.Dock = 'Fill'
    # Create a new Label control
    $filterLabel = New-Object System.Windows.Forms.Label
    $filterLabel.Text = "Search:"
    $filterLabel.AutoSize = $true
    # Create a TextBox control for filtering
    $filterTextBox = New-Object System.Windows.Forms.TextBox
    $filterTextBox.Dock = 'Fill'
    $filterTextBox.Size = New-Object System.Drawing.Size(200)




    # Button a TextBox control for filtering
    $uninstallButton = New-Object System.Windows.Forms.Button
    $uninstallButton.Text = "Uninstall"
    $uninstallButton.Anchor = "Right, top"


    $TableLayoutPanel.Controls.Add($filterLabel, 0, 0)
    $TableLayoutPanel.Controls.Add($filterTextBox, 0, 1)



    $TableLayoutPanel.Controls.Add($uninstallButton, 3, 1)

    $TableLayoutPanel.SetColumnSpan($filterTextBox, 2);
    $l2LeftPanel.Controls.Add($TableLayoutPanel)

    return   @{
        filterTextBox   = $filterTextBox
        filterLabel     = $filterLabel
        uninstallButton = $uninstallButton

    }
}

function New-Table {
    param(
        $mainPanel
    )


    # Create the bottom panel
    $l3LeftPanel = New-Object System.Windows.Forms.Panel
    $l3LeftPanel.Dock = 'Fill'
    $l3LeftPanel.Name = 'Table'
    $l3LeftPanel.MinimumSize = New-Object System.Drawing.Size(700, 230)

    $mainPanel.Controls.Add($l3LeftPanel, 0, 3)
    $mainPanel.SetColumnSpan($l3LeftPanel, 2);
    # Create the table layout panel
    $TableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $TableLayoutPanel.Dock = 'Fill'


    $l3LeftPanel.Controls.Add($TableLayoutPanel)
    # Erstellen einer Tabelle
    $table = New-Object System.Windows.Forms.DataGridView
    $table.Anchor = 'Top, Bottom, Left, Right'
    $table.SelectionMode = "FullRowSelect"
    $table.AutoSizeColumnsMode = "Fill"




    $table.Anchor = "Top, Left, Bottom, Right"
    $table.MultiSelect = $false  # Nur eine Zeile auswÃ¤hlbar
    $table.ReadOnly = $true
    $table = Add-TableContent -table $table

    $TableLayoutPanel.Controls.Add($table, 0, 0)


    return   @{
        table = $table
    }

}

function Add-TableContent {
    param (
        $table
    )
    # HinzufÃ¼gen von Spalten zur Tabelle
    $colDisplayName = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colDisplayName.HeaderText = "Name"
    $colDisplayName.Name = "Name"
    $colDisplayName.MinimumWidth = 200
    $colDisplayName.FillWeight = 200
    $table.Columns.Add($colDisplayName)  | Out-Null

    # HinzufÃ¼gen von Spalten zur Tabelle
    $colUninstallString = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colUninstallString.HeaderText = "Uninstallstring"
    $colUninstallString.Name = "Uninstallstring"
    #$column2.Width = 500
    $table.Columns.Add($colUninstallString)  | Out-Null
    $table.Columns["Uninstallstring"].Visible = $false

    # HinzufÃ¼gen von Spalten zur Tabelle
    $colVersion = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colVersion.HeaderText = "Version"
    $colVersion.Name = "Version"
    $colVersion.MinimumWidth = 150
    $colVersion.FillWeight = 100
    $table.Columns.Add($colVersion)  | Out-Null
    $table.Columns["Version"].Visible = $true

    # HinzufÃ¼gen von Spalten zur Tabelle
    $colPub = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colPub.HeaderText = "Publisher"
    $colPub.MinimumWidth = 160
    $colPub.FillWeight = 150
    $colPub.Name = "Publisher"
    $table.Columns.Add($colPub)  | Out-Null
    $table.Columns["Publisher"].Visible = $true
    $table.Columns["Publisher"].DisplayIndex = 2;


    # HinzufÃ¼gen von Spalten zur Tabelle
    $colType = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colType.HeaderText = "Type"
    $colType.MinimumWidth = 50
    $colType.FillWeight = 50
    $colType.Name = "Type"
    $table.Columns.Add($colType)  | Out-Null
    $table.Columns["Type"].Visible = $false

    # HinzufÃ¼gen von Spalten zur Tabelle
    $colContext = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $colContext.HeaderText = "Context"
    $colContext.Name = "Context"
    $colContext.MinimumWidth = 50
    $colContext.FillWeight = 50
    $table.Columns.Add($colContext)  | Out-Null
    $table.Columns["Context"].Visible = $true

    return $table
}

function Update-TableContent {
    # Parameter help description
    param(
        $tableContent,
        $table
    )
    # Datenquelle leeren
    $table.Rows.Clear()

    foreach ($item in $tableContent) {
        if ($item.Type -ne "N/A") {
            $row = New-Object System.Windows.Forms.DataGridViewRow
            $row.CreateCells($table)
            $row.Cells[0].Value = $item.DisplayName
            $row.Cells[1].Value = $item.QuietUninstallString
            $row.Cells[2].Value = $item.DisplayVersion
            $row.Cells[3].Value = $item.Publisher
            $row.Cells[4].Value = $item.Type
            $row.Cells[5].Value = $item.Context
            $table.Rows.Add($row) | Out-Null
        }

    }

    # Datenquelle nach der Spalte "Name" sortieren
    $table.Sort($table.Columns[0], [System.ComponentModel.ListSortDirection]::Ascending)

}

function New-Footer {
    param(
        $mainPanel
    )


    # Create the bottom panel
    $l4MiddlePanel = New-Object System.Windows.Forms.Panel
    $l4MiddlePanel.Dock = 'Bottom'
    $l4MiddlePanel.Name = 'Footer'

    $l4MiddlePanel.Size = New-Object System.Drawing.Size(0, 25)
    $mainPanel.Controls.Add($l4MiddlePanel, 0, 4)
    # Create the table layout panel
    $TableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $TableLayoutPanel.Dock = 'Fill'


    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Text = "Save"
    $saveButton.Anchor = "left, bottom"

    # Add Buttons
    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Text = "Exit"
    $exitButton.Anchor = "right, bottom"

    $TableLayoutPanel.Controls.Add($exitButton, 1, 0)
    $TableLayoutPanel.Controls.Add($saveButton, 0, 0)
    $TableLayoutPanel.SetColumnSpan($l4MiddlePanel, 2)
    $l4MiddlePanel.Controls.Add($TableLayoutPanel)

    return   @{
        exitButton = $exitButton
        saveButton = $saveButton
    }

}

function New-ProgressBar {
    param (

    )
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Dock = "Bottom"
    $progressBar.Name = "ProgressBar"
    $progressBar.MarqueeAnimationSpeed = 20

    return   @{
        progressBar = $progressBar
    }
}




# Show the form
 <#
   .< help keyword>
   < help content>
   . . .
   #>

#region LOGGING


Set-StrictMode -Version Latest
function New-ComputerViewForm {
    param
    (
        $systemInfo,
        $OutputArea
    )



        Add-Type -AssemblyName System.Windows.Forms

        $detailsForm = New-Object System.Windows.Forms.Form
        $detailsForm.Size = New-Object System.Drawing.Size(400, 250)
        $detailsForm.MinimumSize = $detailsForm.Size
        $detailsForm.Name = "detailsForm"


        $detailsForm.Text = "Details"
        $detailsForm.KeyPreview = $true
        $detailsForm.Dock = 'Fill'
        $detailsForm.Padding = New-Object System.Windows.Forms.Padding(10)

        $tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
        $tableLayoutPanel.Dock = "Fill"
        $tableLayoutPanel.ColumnCount = 2
        $tableLayoutPanel.RowCount = 7


        $Hostlabel = New-Object System.Windows.Forms.Label
        $Hostlabel.Text = "Hostname"
        $Hostlabel.Anchor = 'left'
        $tableLayoutPanel.Controls.Add($Hostlabel, 0, 0)

        $HostTextBox = New-Object System.Windows.Forms.TextBox
        $HostTextBox.ReadOnly = $true
        $HostTextBox.Dock = "Fill"
        $HostTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
        $HostTextBox.Text = $systemInfo.OSInfo.CSName
        $tableLayoutPanel.Controls.Add($HostTextBox, 1, 0)

        $ramLabel = New-Object System.Windows.Forms.Label
        $ramLabel.Text = "RAM"
        $ramLabel.Anchor = 'left'
        $tableLayoutPanel.Controls.Add($ramLabel, 0, 1)

        $ramTextBox = New-Object System.Windows.Forms.TextBox
        $ramTextBox.ReadOnly = $true
        $ramTextBox.Dock = "Fill"
        $ramTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
        $ramTextBox.Text = $systemInfo.Memory
        $tableLayoutPanel.Controls.Add($ramTextBox, 1, 1)

        $cpuabel = New-Object System.Windows.Forms.Label
        $cpuabel.Text = "CPU"
        $cpuabel.Anchor = 'left'
        $tableLayoutPanel.Controls.Add($cpuabel, 0, 2)

        $cpuTextBox = New-Object System.Windows.Forms.TextBox
        $cpuTextBox.ReadOnly = $true
        $cpuTextBox.Dock = "Fill"
        $cpuTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
        $cpuTextBox.Text = $systemInfo.cpu
        $tableLayoutPanel.Controls.Add($cpuTextBox, 1, 2)

        $osnamelabel = New-Object System.Windows.Forms.Label
        $osnamelabel.Text = "OS"
        $osnamelabel.Anchor = 'left'
        $tableLayoutPanel.Controls.Add($osnamelabel, 0, 3)

        $osnameTextBox = New-Object System.Windows.Forms.TextBox
        $osnameTextBox.ReadOnly = $true
        $osnameTextBox.Dock = "Fill"
        $osnameTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
        $osnameTextBox.Text = $systemInfo.OSInfo.Caption
        $tableLayoutPanel.Controls.Add($osnameTextBox, 1, 3)

        $BuildNumberlabel = New-Object System.Windows.Forms.Label
        $BuildNumberlabel.Text = "Build"
        $BuildNumberlabel.Anchor = 'left'
        $tableLayoutPanel.Controls.Add($BuildNumberlabel, 0, 4)

        $BuildNumberTextBox = New-Object System.Windows.Forms.TextBox
        $BuildNumberTextBox.ReadOnly = $true
        $BuildNumberTextBox.Dock = "Fill"
        $BuildNumberTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
        $BuildNumberTextBox.Text = $systemInfo.OSInfo.BuildNumber
        $tableLayoutPanel.Controls.Add($BuildNumberTextBox, 1, 4)

        $OSArchitectureabelabel = New-Object System.Windows.Forms.Label
        $OSArchitectureabelabel.Text = "Architecure"
        $OSArchitectureabelabel.Anchor = 'left'
        $tableLayoutPanel.Controls.Add($OSArchitectureabelabel, 0, 5)

        $OSArchitectureabeTextBox = New-Object System.Windows.Forms.TextBox
        $OSArchitectureabeTextBox.ReadOnly = $true
        $OSArchitectureabeTextBox.Dock = "Fill"
        $OSArchitectureabeTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
        $OSArchitectureabeTextBox.Text = $systemInfo.OSInfo.OSArchitecture
        $tableLayoutPanel.Controls.Add($OSArchitectureabeTextBox, 1, 5)


        foreach ($item in $OutputArea.Controls)
        {
            $OutputArea.Controls.Remove($item)
        }
        $OutputArea.Controls.Add($tableLayoutPanel)



    }


 <#
   .< help keyword>
   < help content>
   . . .
   #>

#region LOGGING


Set-StrictMode -Version Latest
function New-DetailViewForm {
    param
    (
        $table,
        $OutputArea
    )


    $selectedRow = $table.selectedRows[0]
    Add-Type -AssemblyName System.Windows.Forms





    $detailsForm = New-Object System.Windows.Forms.Form
    $detailsForm.Size = New-Object System.Drawing.Size(400, 250)
    $detailsForm.MinimumSize = $detailsForm.Size
    $detailsForm.Name = "detailsForm"

    $detailsForm.Text = "Details"
    $detailsForm.KeyPreview = $true
    $detailsForm.Dock = 'Fill'
    $detailsForm.Padding = New-Object System.Windows.Forms.Padding(10)  # Set the padding here

    $tableLayoutPanel = New-Object System.Windows.Forms.TableLayoutPanel
    $tableLayoutPanel.Dock = "Fill"
    $tableLayoutPanel.ColumnCount = 2
    $tableLayoutPanel.RowCount = 3

    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = "Name"
    $nameLabel.Anchor = 'left'
    $tableLayoutPanel.Controls.Add($nameLabel, 0, 0)

    $nameTextBox = New-Object System.Windows.Forms.TextBox
    $nameTextBox.ReadOnly = $true
    $nameTextBox.Dock = "Fill"
    $nameTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
    $nameTextBox.Text = $selectedRow.Cells["Name"].Value
    $tableLayoutPanel.Controls.Add($nameTextBox, 1, 0)

    $publisherLabel = New-Object System.Windows.Forms.Label
    $publisherLabel.Text = "Publisher"
    $publisherLabel.Anchor = 'left'
    $tableLayoutPanel.Controls.Add($publisherLabel, 0, 1)

    $publisherTextBox = New-Object System.Windows.Forms.TextBox
    $publisherTextBox.ReadOnly = $true
    $publisherTextBox.Dock = "Fill"
    $publisherTextBox.Text = $selectedRow.Cells["Publisher"].Value
    $publisherTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
    $tableLayoutPanel.Controls.Add($publisherTextBox, 1, 1)

    $versionLabel = New-Object System.Windows.Forms.Label
    $versionLabel.Text = "Version"
    $versionLabel.Anchor = 'left'
    $tableLayoutPanel.Controls.Add($versionLabel, 0, 2)

    $versionTextBox = New-Object System.Windows.Forms.TextBox
    $versionTextBox.ReadOnly = $true
    $versionTextBox.Dock = "Fill"
    $versionTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
    $versionTextBox.text = $selectedRow.Cells["Version"].Value
    $tableLayoutPanel.Controls.Add($versionTextBox, 1, 2)

    $stringLabel = New-Object System.Windows.Forms.Label
    $stringLabel.Text = "Command"
    $stringLabel.Anchor = 'left'
    $tableLayoutPanel.Controls.Add($stringLabel, 0, 3)

    $stringTextBox = New-Object System.Windows.Forms.TextBox
    $stringTextBox.ReadOnly = $true
    $stringTextBox.Dock = "Fill"
    $stringTextBox.Text = if ($selectedRow.Cells[4].Value -eq "MSI") {
        "msiexec " + $selectedRow.Cells["Uninstallstring"].Value
    }
    else { $selectedRow.Cells["Uninstallstring"].Value }
    $stringTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 50)
    $stringTextBox.Multiline = $true
    $tableLayoutPanel.Controls.Add($stringTextBox, 1, 3)

    $stringLabel = New-Object System.Windows.Forms.Label
    $stringLabel.Text = "Context"
    $tableLayoutPanel.Controls.Add($stringLabel, 0, 4)

    $stringTextBox = New-Object System.Windows.Forms.TextBox
    $stringTextBox.ReadOnly = $true
    $stringTextBox.Dock = "Fill"
    $stringTextBox.Text = $selectedRow.Cells["Context"].Value
    $stringTextBox.Size = New-Object System.Drawing.Size(($detailsForm.Size.Width - 150), 20)
    $tableLayoutPanel.Controls.Add($stringTextBox, 1, 4)

    foreach ($item in $OutputArea.Controls)
    {
        $OutputArea.Controls.Remove($item)
    }
    $OutputArea.Controls.Add($tableLayoutPanel)



}


 <#
   .< help keyword>
   < help content>
   . . .
   #>

#region LOGGING


Set-StrictMode -Version Latest
function Test-PreRequirement {
    param (
        $ouputTextBox,
        $requiredVersion,
        $requireAdminRights,
        $requiredPolicy
    )
    if ((Test-IsRequiredPSVersion -requiredVersion $requiredVersion )) {
        if ((Test-IsAdminRole -requireAdminRights $requireAdminRights)) {
            if ((Test-IsCorrectExecutionPolicy -requiredPolicy $requiredPolicy)) {
                return $true
            }
            else {
                Set-DisplayBoxText -displayBox $ouputTextBox -text "Please set execution policy to $requiredPolicy" -isError $true
                return $false
            }
        }
        else {
            Set-DisplayBoxText -displayBox $ouputTextBox -text "Please run this program as an administrator." -isError $true
            return $false
        }
    }
    else {
        Set-DisplayBoxText -displayBox $ouputTextBox -text "Please install the powershell version $requiredVersion" -isError $true
        return $false
    }
}

Function Test-IsCorrectExecutionPolicy {
    param (
        $requiredPolicy
    )
    if ($requiredPolicy) {
        if ((Get-ExecutionPolicy) -ne $requiredPolicy) {
            try {
                Set-ExecutionPolicy -ExecutionPolicy $requiredPolicy -Scope CurrentUser -Force
                return $true
            }
            catch {
                return $false
            }
        }
        else {
            return $true
        }
    }
    else {
        return $true
    }

}

function Test-IsAdminRole {
    param ($requireAdminRights)

    if ($requireAdminRights) {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    else {
        $true
    }

}

function Test-IsRequiredPSVersion {
    param (
        $requiredVersion
    )
    # Erforderliche Mindestversion von PowerShell
    $requiredVersion = New-Object System.Version($requiredVersion)

    # Aktuelle Version von PowerShell
    $currentVersion = $PSVersionTable.PSVersion

    # ÃœberprÃ¼fen, ob die aktuelle Version grÃ¶ÃŸer oder gleich der erforderlichen Version ist
    if ($currentVersion -ge $requiredVersion) {
        return $true
    }
    else {
        return $false

    }

}



Main
