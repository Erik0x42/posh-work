spps -Name Teams -ErrorAction SilentlyContinue; gci $env:AppData\Microsoft\Teams -Directory | ? { $_ -in ('Cache','databases','blob_storage','IndexedDB','GPUcache', 'Local Storage', 'tmp') } | % { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue}