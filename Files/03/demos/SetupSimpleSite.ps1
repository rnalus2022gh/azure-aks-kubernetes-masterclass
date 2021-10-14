Install-WindowsFeature -Name Web-Server
$sitePath = "c:\example-site"
$output = "$sitePath\index.html"
$url = "https://assetswe.blob.core.windows.net/public/index.html"
New-Item -ItemType Directory $sitePath -Force
Invoke-WebRequest -Uri $url -OutFile $output
Remove-Website -Name 'Default Web Site'; `
New-Website -Name 'example-site' `
         -Port 80 -PhysicalPath $sitePath
echo 'Finished'