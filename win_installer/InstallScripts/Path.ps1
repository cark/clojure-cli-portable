param([String]$Action="add",[String]$InstallPath="c:\bleh")

function Add {
  $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
  try {
    $path = $key.GetValue('Path',$null,'DoNotExpandEnvironmentNames')  
    if ( $path -notlike "*$InstallPath*" ) {
      $key.SetValue('Path', $path + ";$InstallPath", 'ExpandString')
    }
  }
  finally {
    $key.Dispose()
  }
}

function Remove {
  $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
  try {
    $path = $key.GetValue('Path',$null,'DoNotExpandEnvironmentNames')
    $path = ($path.split(';') | Where-Object { $_ -ne $InstallPath}) -join ';'
    $key.SetValue('Path', $path, 'ExpandString')
  }
  finally {
    $key.Dispose()
  }
}

if ( $Action -eq "add" ) {
  Add
} ElseIf ( $Action -eq "remove" ) {
  Remove
}