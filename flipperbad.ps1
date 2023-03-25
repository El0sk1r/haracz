Add-Type -AssemblyName System.Windows.Forms

# Klawisze do wyłączenia
$keys = [Windows.Forms.Keys[]] @('W', 'K', 'L', 'Space', 'Back')

# Klawisz skrótu do włączania i wyłączania
$hotkey = [Windows.Forms.Keys]::O
$modifiers = [Windows.Forms.Keys]::Control, [Windows.Forms.Keys]::Alt

# Tworzenie filtra wiadomości
class EventMessageFilter : System.Windows.Forms.IMessageFilter {
    [Windows.Forms.Keys[]] $keys
    EventMessageFilter([Windows.Forms.Keys[]] $keys) {
        $this.keys = $keys
    }
    [bool] ShouldProcessMessage([System.Windows.Forms.Message] $msg) {
        if ($msg.Msg -eq 256) { # WM_KEYDOWN
            $key = [Windows.Forms.Keys]::None
            try {
                $key = [Windows.Forms.Control]::ModifierKeys
                $key += $msg.WParam.ToInt32()
                if ($this.keys -contains $key) {
                    return $true
                }
            } catch {
                Write-Error "Error checking key press: $_"
            }
        }
        return $false
    }
}
$eventFilter = New-Object EventMessageFilter $keys

# Rejestracja klawisza skrótu
$hotkeyConverter = New-Object System.Windows.Forms.KeysConverter
$hotkeyCode = $hotkeyConverter.ConvertFrom($hotkey)
$hotkeyRegisterMethod = [Windows.Forms.Control]::GetType().GetMethod("RegisterHotKey", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Static)
$hotkeyRegisterMethod.Invoke($null, @([System.IntPtr]::Zero, 0, $modifiers[0] -bor $modifiers[1], $hotkeyCode))

# Dodanie filtra do aplikacji
Add-Type -AssemblyName Microsoft.VisualBasic
[Microsoft.VisualBasic.Interaction]::AppActivate((Get-Process -id $pid).MainWindowTitle)
$application = [System.Windows.Forms.Application]::OpenForms[0]
$application.AddMessageFilter($eventFilter)

# Wyświetlenie informacji o uruchomieniu
Write-Host "Hotkey registered to disable keys: $($keys -join ', ')"
Write-Host "Press $($modifiers -join '+')+$hotkey to toggle key disabling"

# Pętla aplikacji
while ($true) {
    $application.DoEvents()
    Start-Sleep -Milliseconds 10
}
