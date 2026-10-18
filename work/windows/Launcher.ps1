# Windows launcher. Original game data remains in the user's installation.
param([switch]$ValidateOnly)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$homePath=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'sodacore studios\Zero Hour'
$profile=Join-Path $homePath 'Command and Conquer Generals Zero Hour Data'
$settingsFile=Join-Path $homePath 'Launcher.json'
New-Item -ItemType Directory -Force $profile | Out-Null
function Get-ServiceEndpoint([string]$address) {
    if ([string]::IsNullOrWhiteSpace($address)) {return 'http://127.0.0.1:9/env/prod/contract/1'}
    $u=$null
    if (![Uri]::TryCreate($address,[UriKind]::Absolute,[ref]$u) -or $u.Scheme -ne 'https' -or $u.UserInfo -or $u.Query -or $u.Fragment -or $address -match '[\s\\]') {throw 'Enter an HTTPS server address without credentials, query or fragment.'}
    $base=$address.TrimEnd('/')
    if (!$base.EndsWith('/env/prod/contract/1')) {$base+='/env/prod/contract/1'}
    return $base
}
function Set-GameOptions([string]$path,[hashtable]$values) {
    $lines=if(Test-Path $path){@(Get-Content $path)}else{@()}
    $output=New-Object 'System.Collections.Generic.List[string]'
    foreach($line in $lines){$key=($line -split '=',2)[0].Trim();if(!$values.ContainsKey($key)){$output.Add($line)}}
    foreach($key in ($values.Keys | Sort-Object)){$output.Add("$key = $($values[$key])")}
    [IO.File]::WriteAllLines($path,$output,[Text.Encoding]::ASCII)
}
if($ValidateOnly){
    if((Get-ServiceEndpoint 'https://game.example.org/') -ne 'https://game.example.org/env/prod/contract/1'){throw 'Endpoint regression'}
    foreach($bad in @('http://game.example.org','https://user:secret@game.example.org','https://game.example.org/?secret=1')){
        $rejected=$false;try{Get-ServiceEndpoint $bad | Out-Null}catch{$rejected=$true};if(!$rejected){throw 'Unsafe endpoint accepted'}
    }
    Write-Output 'PASS: launcher endpoint validation';return
}
$form=New-Object Windows.Forms.Form
$form.Text='Zero Hour - sodacore studios';$form.Size=New-Object Drawing.Size(670,490);$form.StartPosition='CenterScreen'
$fields=@{}
$labels=@('Zero Hour folder','Generals base folder','Player name','Private server (HTTPS)','Invitation','TURN relay (host:port)','Resolution')
$defaults=@('', '', 'Player', '', '', '', '1920 1080')
$saved=if(Test-Path $settingsFile){Get-Content $settingsFile -Raw | ConvertFrom-Json}else{$null}
for($i=0;$i -lt $labels.Count;$i++){
    $label=New-Object Windows.Forms.Label;$label.Text=$labels[$i];$label.SetBounds(15,20+$i*42,190,25);$form.Controls.Add($label)
    $box=New-Object Windows.Forms.TextBox;$box.SetBounds(210,17+$i*42,425,25);$box.Text=$defaults[$i]
    if($saved -and $saved.PSObject.Properties[$labels[$i]]){$box.Text=$saved.($labels[$i])}
    if($i -eq 4){$box.UseSystemPasswordChar=$true}
    $fields[$labels[$i]]=$box;$form.Controls.Add($box)
}
if(!$fields['Zero Hour folder'].Text){
    $ea=Join-Path ${env:ProgramFiles(x86)} 'EA Games'
    $zh=Join-Path $ea 'Command & Conquer Generals Zero Hour';$base=Join-Path $ea 'Command and Conquer Generals'
    if(Test-Path $zh){$fields['Zero Hour folder'].Text=$zh};if(Test-Path $base){$fields['Generals base folder'].Text=$base}
}
$wasd=New-Object Windows.Forms.CheckBox;$wasd.Text='WASD camera';$wasd.Checked=$true;$wasd.SetBounds(15,320,170,25);$form.Controls.Add($wasd)
$right=New-Object Windows.Forms.CheckBox;$right.Text='Right-click move / attack';$right.Checked=$true;$right.SetBounds(210,320,250,25);$form.Controls.Add($right)
$windowed=New-Object Windows.Forms.CheckBox;$windowed.Text='Windowed';$windowed.Checked=$true;$windowed.SetBounds(480,320,150,25);$form.Controls.Add($windowed)
foreach($pair in @(@('WASD',$wasd),@('RightClick',$right),@('Windowed',$windowed))){if($saved -and $saved.PSObject.Properties[$pair[0]]){$pair[1].Checked=[bool]$saved.($pair[0])}}
$status=New-Object Windows.Forms.Label;$status.SetBounds(15,400,620,45);$status.Text='Original Generals and Zero Hour files are required.';$form.Controls.Add($status)
$play=New-Object Windows.Forms.Button;$play.Text='Play';$play.SetBounds(15,360,150,30);$form.Controls.Add($play)
$play.Add_Click({
 try {
    $zh=$fields['Zero Hour folder'].Text.Trim();$base=$fields['Generals base folder'].Text.Trim()
    if(!(Test-Path (Join-Path $zh 'INIZH.big')) -or !(Test-Path (Join-Path $base 'INI.big'))){throw 'Choose the installed Zero Hour and Generals folders.'}
    $endpoint=Get-ServiceEndpoint $fields['Private server (HTTPS)'].Text.Trim()
    $name=$fields['Player name'].Text.Trim();if($name -notmatch '^[\p{L}\p{N} _.-]{2,24}$'){throw 'Player name must contain 2-24 letters, numbers, spaces, periods, hyphens or underscores.'}
    $resolution=$fields['Resolution'].Text.Trim();if($resolution -notmatch '^(\d{3,4}) (\d{3,4})$' -or [int]$Matches[1] -lt 800 -or [int]$Matches[1] -gt 7680 -or [int]$Matches[2] -lt 600 -or [int]$Matches[2] -gt 4320){throw 'Resolution must be width height, for example 1920 1080 (800x600 to 7680x4320).'}
    $relay=$fields['TURN relay (host:port)'].Text.Trim()
    if(!$relay -and $endpoint.StartsWith('https://')){$relay=([Uri]$endpoint).Host+':3478'}
    if($relay){$u=$null;if(![Uri]::TryCreate('turn://'+$relay,[UriKind]::Absolute,[ref]$u) -or !$u.Host -or $u.Port -lt 1 -or $u.Port -gt 65535 -or $u.UserInfo -or $u.Query -or $u.Fragment -or $u.AbsolutePath -notin @('','/') -or $relay -match '[\s\\]'){throw 'Relay must be host:port.'}}
    $settings=@{};foreach($key in $fields.Keys){if($key -ne 'Invitation'){$settings[$key]=$fields[$key].Text}}
    $settings.WASD=$wasd.Checked;$settings.RightClick=$right.Checked;$settings.Windowed=$windowed.Checked
    $settings | ConvertTo-Json | Set-Content $settingsFile -Encoding UTF8
    $opts=@{Resolution=$resolution;WASDMapScroll=$(if($wasd.Checked){'yes'}else{'no'});UseAlternateMouse=$(if($right.Checked){'yes'}else{'no'});UseRightMouseScrollWithAlternateMouse='no';ShowHotKeyLabels='yes'}
    Set-GameOptions (Join-Path $profile 'Options.ini') $opts
    $engine=Join-Path $PSScriptRoot 'bin\GeneralsOnlineZH.exe';if(!(Test-Path $engine)){throw 'Engine is missing from the package.'}
    $start=New-Object Diagnostics.ProcessStartInfo;$start.FileName=$engine;$start.WorkingDirectory=$zh;$start.UseShellExecute=$false
    $start.Arguments=if($windowed.Checked){'-win'}else{'-fullscreen'}
    $start.EnvironmentVariables['ZERO_HOUR_GAME_PATH']=$zh
    $start.EnvironmentVariables['GENERALS_BASE_INSTALL_PATH']=$base
    $start.EnvironmentVariables['GENERALS_USER_DATA_ROOT']=$homePath
    $start.EnvironmentVariables['ZERO_HOUR_PRIVATE_SERVICE']='1'
    $start.EnvironmentVariables['ZERO_HOUR_SERVICE_URL']=$endpoint
    $start.EnvironmentVariables['ZERO_HOUR_PLAYER_NAME']=$name
    $start.EnvironmentVariables['ZERO_HOUR_INVITATION']=$fields['Invitation'].Text
    $start.EnvironmentVariables['ZERO_HOUR_TURN_SERVERS']=$relay
    $start.EnvironmentVariables['ZERO_HOUR_STUN_SERVERS']=''
    $script:game=[Diagnostics.Process]::Start($start);$play.Enabled=$false;$status.Text='Game running. Close the game before switching versions.'
 } catch {[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Zero Hour') | Out-Null}
})
$timer=New-Object Windows.Forms.Timer;$timer.Interval=1000
$timer.Add_Tick({
    if($script:game -and $script:game.HasExited){
        $play.Enabled=$true
        $status.Text=switch($script:game.ExitCode){
            0 {'Game closed.'}
            -1073741515 {'A required DLL is missing. Extract the complete release ZIP and check the original game installation.'}
            -1073741701 {'A DLL has the wrong architecture. Extract a clean copy of the Windows x86 release.'}
            default {"Game exited ($($script:game.ExitCode)). See the troubleshooting guide."}
        }
        $script:game.Dispose();$script:game=$null
    }
});$timer.Start()
[void]$form.ShowDialog();$timer.Dispose()
