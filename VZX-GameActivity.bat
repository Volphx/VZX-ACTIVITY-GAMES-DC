@echo off
setlocal
set "VZX_BAT_FILE=%~f0"
set "VZX_BAT_MODE=%~1"
title VZX-GameActivity
if "%~1"=="" start "" "https://www.youtube.com/@VzxCheats"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$text=[IO.File]::ReadAllText($env:VZX_BAT_FILE); $marker='### VZX_EMBEDDED_SCRIPT ###'; & ([scriptblock]::Create($text.Substring($text.LastIndexOf($marker))))"
set "VZX_RESULT=%ERRORLEVEL%"
if /i "%~1"=="--self-test" exit /b %VZX_RESULT%
if /i "%~1"=="--catalog-test" exit /b %VZX_RESULT%
if /i "%~1"=="--console-preview" exit /b %VZX_RESULT%
echo.
pause
exit /b %VZX_RESULT%
### VZX_EMBEDDED_SCRIPT ###
$ErrorActionPreference='Stop'

[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$script:VzxInner=70
function Write-VzxEdge($kind) {
    if($kind-eq 'top'){$left=[char]0x256D;$right=[char]0x256E}elseif($kind-eq 'bottom'){$left=[char]0x2570;$right=[char]0x256F}else{$left=[char]0x251C;$right=[char]0x2524}
    Write-Host ('  '+$left+(([string][char]0x2500)*($script:VzxInner+2))+$right) -ForegroundColor DarkGray
}
function Write-VzxLine([string]$text,[ConsoleColor]$color=[ConsoleColor]::Gray) {
    if($text.Length-gt $script:VzxInner){$text=$text.Substring(0,$script:VzxInner-3)+'...'}
    Write-Host -NoNewline ('  '+[char]0x2502+' ') -ForegroundColor DarkGray
    Write-Host -NoNewline $text.PadRight($script:VzxInner) -ForegroundColor $color
    Write-Host (' '+[char]0x2502) -ForegroundColor DarkGray
}
function Show-VzxHeader {
    if(![Console]::IsOutputRedirected){try{$host.UI.RawUI.BackgroundColor='Black';$host.UI.RawUI.ForegroundColor='Gray';$host.UI.RawUI.WindowTitle='VZX-GameActivity';Clear-Host}catch{}}
    Write-Host ''
    Write-VzxEdge 'top';Write-VzxLine ''
    Write-VzxLine '                         V Z X   C H E A T S' White
    Write-VzxLine '                   500 JOGOS  /  LISTA FIXA  /  OFFLINE' Gray
    Write-VzxLine '';Write-VzxEdge 'middle'
    Write-VzxLine '  YOUTUBE   https://www.youtube.com/@VzxCheats' Gray
    Write-VzxLine '  DISCORD   https://discord.gg/fXAC29XEyG' Gray
    Write-VzxEdge 'bottom';Write-Host ''
}
function Show-VzxInfo {
    Write-VzxEdge 'top';Write-VzxLine '  HORAS ACUMULADAS - CALCULO TEORICO' White;Write-VzxEdge 'middle'
    Write-VzxLine '  META: 5K = 5.000 horas.'
    Write-VzxLine '  209 jogos por 24h = 5.016 horas teoricas.'
    Write-VzxLine '  Com 500 jogos: 5.000h em 10 horas teoricas.'
    Write-VzxLine '  Soma teorica; contabilizacao pelo Discord nao confirmada.' DarkGray
    Write-VzxEdge 'middle'
    Write-VzxLine '  Insignia: confira apos 24h; prazo exato nao confirmado.' Gray
    Write-VzxEdge 'bottom';Write-Host ''
}
function Format-VzxTime([long]$seconds) {
    $span=[TimeSpan]::FromSeconds($seconds)
    return ('{0:00}:{1:00}:{2:00}'-f [long][Math]::Floor($span.TotalHours),$span.Minutes,$span.Seconds)
}
function Get-VzxAccumulatedSeconds($entries) {
    $sum=0.0;$now=[DateTime]::UtcNow
    foreach($entry in $entries){
        if($null-ne $entry.CompletedSeconds){$sum+=[double]$entry.CompletedSeconds;continue}
        if($entry.Process.HasExited){$end=$entry.Process.ExitTime.ToUniversalTime();$entry.CompletedSeconds=[Math]::Max(0.0,($end-$entry.StartedUtc).TotalSeconds);$sum+=$entry.CompletedSeconds}
        else{$sum+=[Math]::Max(0.0,($now-$entry.StartedUtc).TotalSeconds)}
    }
    return $sum
}
function Get-VzxMemoryMb($items) {
    $bytes=0.0
    foreach($item in $items){try{$item.Refresh();if(!$item.HasExited){$bytes+=$item.WorkingSet64}}catch{}}
    return ($bytes/1MB)
}
function Show-VzxDashboard([int]$active,[int]$total,[long]$elapsed,[long]$limit,[string]$state,[double]$generatedSeconds=0) {
    $duration=Format-VzxTime $elapsed
    $target=if($limit-eq 0){'SEM LIMITE'}else{Format-VzxTime $limit}
    Write-VzxEdge 'top';Write-VzxLine ('  '+$state) White;Write-VzxEdge 'middle'
    Write-VzxLine ('  JOGOS ATIVOS       {0} / {1}'-f $active,$total) White
    Write-VzxLine ('  TEMPO DECORRIDO    '+$duration) White
    Write-VzxLine ('  TEMPO DEFINIDO     '+$target) Gray
    Write-VzxLine ('  HORAS ACUMULADAS (TEORICAS)  '+($generatedSeconds/3600).ToString('N3')+' h') White
    Write-VzxLine ('  RAM DOS PROCESSOS  {0:N1} MB' -f (Get-VzxMemoryMb $processes)) White
    Write-VzxLine ('  RAM ESTIMADA       {0:N1} MB / {1} jogos' -f $script:VzxEstimatedMb,$total) Gray
    Write-VzxLine ''
    if($limit-gt 0){$ratio=[Math]::Min(1.0,$elapsed/[double]$limit);$filled=[int][Math]::Floor($ratio*42);$bar=('#'*$filled)+('-'*(42-$filled));Write-VzxLine ('  ['+$bar+']  '+[int]($ratio*100)+'%') DarkCyan}
    else{Write-VzxLine '  Sessao continua' Gray}
    Write-VzxEdge 'middle';Write-VzxLine '  CTRL+C  Encerrar a sessao' DarkGray;Write-VzxLine '  Insignia: confira apos 24h; prazo nao confirmado.' DarkGray;Write-VzxEdge 'bottom'
}
function Read-Number($label,[long]$minimum,[long]$maximum) {
    while($true){$raw=Read-Host $label;$number=0L;if([long]::TryParse($raw,[ref]$number)-and $number-ge $minimum-and $number-le $maximum){return $number};Write-Host 'Numero invalido.' -ForegroundColor Red}
}
function Test-RelativeExe([string]$name) {
    if([string]::IsNullOrWhiteSpace($name)-or $name.Length-gt 240-or [IO.Path]::IsPathRooted($name)-or $name-match '[:<>"|?*\r\n]' -or $name-notmatch '(?i)\.exe$'){return $false}
    foreach($part in ($name-replace '\\','/').Split('/')){
        if(!$part-or $part-eq '.'-or $part-eq '..'-or $part-match '[ .]$'-or $part-match '^(?i:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)'){return $false}
    };return $true
}
function Get-FixedGames {
    $payload='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'
    $input=[IO.MemoryStream]::new([Convert]::FromBase64String($payload))
    $zip=[IO.Compression.GZipStream]::new($input,[IO.Compression.CompressionMode]::Decompress)
    $output=[IO.MemoryStream]::new()
    try{$zip.CopyTo($output);$json=[Text.Encoding]::UTF8.GetString($output.ToArray())}finally{$zip.Dispose();$input.Dispose();$output.Dispose()}
    $games=ConvertFrom-Json $json;if($games-isnot [array]){$games=@($games)}
    if($games.Count-ne 500){throw 'A lista fixa precisa conter exatamente 500 jogos.'}
    $seen=[Collections.Generic.HashSet[string]]::new()
    foreach($game in $games){if([string]$game.id-notmatch '^\d+$'-or !$seen.Add([string]$game.id)-or !(Test-RelativeExe ([string]$game.exe))){throw 'A lista fixa contem uma entrada invalida.'}}
    return $games
}
$workerSource=@"
using System;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;
public static class VZXWorker {
    [StructLayout(LayoutKind.Sequential)] struct POINT { public int x,y; }
    [StructLayout(LayoutKind.Sequential)] struct MSG { public IntPtr hwnd;public uint message;public UIntPtr wParam;public IntPtr lParam;public uint time;public POINT pt;public uint reserved; }
    [DllImport("user32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateWindowEx(uint ex,string cls,string title,uint style,int x,int y,int width,int height,IntPtr parent,IntPtr menu,IntPtr instance,IntPtr param);
    [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h,int command);
    [DllImport("user32.dll")] static extern bool IsWindow(IntPtr h);
    [DllImport("user32.dll")] static extern bool DestroyWindow(IntPtr h);
    [DllImport("user32.dll")] static extern bool PeekMessage(out MSG msg,IntPtr h,uint first,uint last,uint remove);
    [DllImport("user32.dll")] static extern bool TranslateMessage(ref MSG msg);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern IntPtr DispatchMessage(ref MSG msg);
    [STAThread] public static int Main(string[] args) {
        try {
            long seconds=long.Parse(args[0]);if(seconds<0)return 2;
            string name=Encoding.UTF8.GetString(Convert.FromBase64String(args[1]));
            IntPtr window=CreateWindowEx(0x80,"STATIC",name,0x00CF0000,unchecked((int)0x80000000),unchecked((int)0x80000000),320,180,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero);
            if(window==IntPtr.Zero)return 3;
            ShowWindow(window,7);var watch=Stopwatch.StartNew();
            while(IsWindow(window)&&(seconds==0||watch.Elapsed.TotalSeconds<seconds)){
                MSG message;while(PeekMessage(out message,IntPtr.Zero,0,0,1)){TranslateMessage(ref message);DispatchMessage(ref message);}Thread.Sleep(100);
            }
            if(IsWindow(window))DestroyWindow(window);return 0;
        } catch {return 4;}
    }
}
"@
$script:VzxEstimatedMb=0.0;$runtime=$null;$processes=[Collections.Generic.List[Diagnostics.Process]]::new();$accounting=[Collections.Generic.List[object]]::new();$generatedSeconds=0.0;$exitCode=0
try {
    if($env:VZX_BAT_MODE-eq '--console-preview'){Show-VzxHeader;Show-VzxInfo;Show-VzxDashboard 6 6 83 1200 'SESSAO EM ANDAMENTO' 498;exit 0}
    $test=$env:VZX_BAT_MODE-eq '--self-test'
    if($test){
        if(!(Test-RelativeExe 'bin/Game.exe')-or (Test-RelativeExe '../escape.exe')-or (Test-RelativeExe 'C:\escape.exe')-or (Test-RelativeExe 'nul/Game.exe')){throw 'Falha na validacao de caminhos.'}
        $count=2;$seconds=2L
        if(@(Get-FixedGames).Count-ne 500){throw 'Lista fixa incompleta.'};$games=@(Get-FixedGames | Select-Object -First 2)
    }elseif($env:VZX_BAT_MODE-eq '--catalog-test'){
        $games=@(Get-FixedGames);Write-Host ('PASS: lista fixa offline; '+$games.Count+' jogos compativeis.');exit 0
    }else{
        Show-VzxHeader
        Show-VzxInfo
        Write-Host '  CONFIGURAR SESSAO' -ForegroundColor White
        Write-Host ''
        $count=Read-Number '  Jogos simultaneos [1-500]' 1 500
        $minutes=Read-Number '  Duracao em minutos [0 = continuo]' 0 52560000
        $seconds=$minutes*60L;$games=@(Get-FixedGames)
        if($count-gt $games.Count){throw ('Disponiveis: '+$games.Count+' jogos. Execute novamente com uma quantidade menor.')}
    }
    $runtime=Join-Path ([IO.Path]::GetTempPath()) ('VZX-Standalone-'+[Guid]::NewGuid().ToString('N'))
    $null=New-Item -ItemType Directory -Path $runtime
    $worker=Join-Path $runtime 'VZXWorker.exe'
    Add-Type -TypeDefinition $workerSource -OutputAssembly $worker -OutputType WindowsApplication -ErrorAction Stop
    Write-Host '  Medindo memoria para estimar o consumo...' -ForegroundColor DarkGray
    $probe=$null
    try{
        $probe=Start-Process -FilePath $worker -ArgumentList @('0',[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('VZX - Calibracao'))) -PassThru
        Start-Sleep -Milliseconds 1000
        if($probe.HasExited){throw 'Nao foi possivel medir a memoria do processo de teste.'}
        $perGame=Get-VzxMemoryMb @($probe)
        $script:VzxEstimatedMb=$perGame*$count
        Write-Host ('  Estimativa para {0} jogos: {1:N1} MB de RAM (~{2:N1} MB/jogo).' -f $count,$script:VzxEstimatedMb,$perGame) -ForegroundColor White
        Write-Host '  Valor aproximado; varia durante a sessao. Apenas processos simulados.' -ForegroundColor DarkGray
    }finally{
        if($null-ne $probe){try{if(!$probe.HasExited){$probe.Kill();$probe.WaitForExit()}}finally{$probe.Dispose()}}
    }
    Write-Host '  Preparando sessao...' -ForegroundColor DarkGray
    for($i=0;$i-lt $count;$i++){
        $game=$games[$i];if(!(Test-RelativeExe $game.exe)){throw 'Executavel invalido no catalogo.'}
        $folder=Join-Path $runtime $game.id;$exe=Join-Path $folder ($game.exe-replace '/','\')
        $null=New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($exe)) -Force
        Copy-Item -LiteralPath $worker -Destination $exe
        $encoded=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($game.name))
        $process=Start-Process -FilePath $exe -ArgumentList @([string]$seconds,$encoded) -PassThru
        $processes.Add($process)
        try{$started=$process.StartTime.ToUniversalTime()}catch{$started=[DateTime]::UtcNow};$accounting.Add([pscustomobject]@{Process=$process;StartedUtc=$started;CompletedSeconds=$null})
    }
    if($test-and @($processes|Where-Object {!$_.HasExited}).Count-ne 2){throw 'Falha ao iniciar os dois processos.'}
    $canDraw=!$test-and ![Console]::IsOutputRedirected
    $dashboardTop=0
    if($canDraw){Show-VzxHeader;try{$dashboardTop=[Console]::CursorTop;Show-VzxDashboard $count $count 0 $seconds 'SESSAO EM ANDAMENTO';[Console]::CursorVisible=$false}catch{$canDraw=$false}}
    else{Write-Host ($count.ToString()+' jogos iniciados. Ctrl+C para parar.')}
    $clock=[Diagnostics.Stopwatch]::StartNew();$last=-1L
    while($true){
        $generatedSeconds=Get-VzxAccumulatedSeconds $accounting
        $active=@($processes|Where-Object {!$_.HasExited}).Count
        if($active-eq 0){break}
        $elapsed=[long][Math]::Floor($clock.Elapsed.TotalSeconds)
        if($elapsed-ne $last){$last=$elapsed
            if($canDraw){try{[Console]::SetCursorPosition(0,$dashboardTop);Show-VzxDashboard $active $count $elapsed $seconds 'SESSAO EM ANDAMENTO' $generatedSeconds}catch{$canDraw=$false}}
            if(!$canDraw){Write-Host -NoNewline ("`rAtivos: {0} | Tempo: {1} | Horas teoricas: {2:N3} h | RAM: {3:N1} MB   "-f $active,(Format-VzxTime $elapsed),($generatedSeconds/3600),(Get-VzxMemoryMb $processes))}
        }
        Start-Sleep -Milliseconds 150
    }
    foreach($process in $processes){$process.WaitForExit();if($process.ExitCode-ne 0){throw ('Um processo encerrou com erro: '+$process.ExitCode)}}
    if($test-and ($generatedSeconds-lt 3.8-or $generatedSeconds-gt 60)){throw 'Falha no acumulador de horas por processo.'}
    if($test){Write-Host "`nPASS: horas acumuladas por processo; 500 jogos fixos, dois jogos da lista iniciados simultaneamente, janelas minimizadas, tempo e caminhos validos."}else{
        if($canDraw){try{[Console]::SetCursorPosition(0,$dashboardTop);Show-VzxDashboard 0 $count ([long][Math]::Floor($clock.Elapsed.TotalSeconds)) $seconds 'SESSAO CONCLUIDA' $generatedSeconds}catch{Write-Host "`nConcluido."}}
        else{Write-Host "`nConcluido."}
    }
}catch{
    Write-Host ("`nErro: "+$_.Exception.Message);$exitCode=1
}finally{
    try{[Console]::CursorVisible=$true}catch{}
    foreach($process in $processes){try{if(!$process.HasExited){$process.Kill();$process.WaitForExit(3000)|Out-Null}}catch{}}
    if($accounting.Count-gt 0){try{$generatedSeconds=Get-VzxAccumulatedSeconds $accounting;if(!$test){Write-Host ("`n  Total teorico acumulado: {0:N3} horas"-f ($generatedSeconds/3600)) -ForegroundColor White}}catch{}}
    foreach($process in $processes){try{$process.Dispose()}catch{}}
    if($runtime-and (Test-Path -LiteralPath $runtime)){
        $full=[IO.Path]::GetFullPath($runtime);$tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
        if($full.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)-and [IO.Path]::GetFileName($full)-match '^VZX-Standalone-[a-f0-9]{32}$'){
            try{Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop}catch{Write-Host 'Os arquivos temporarios permanecem na pasta Temp.'}
        }
    }
}
exit $exitCode


