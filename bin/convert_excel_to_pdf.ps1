if($Args.Length -ne 2){
  echo 'require 2 args. file_path_excel & file_path_pdf'
  return
}
$file_path_excel = $Args[0]
$file_path_pdf = $Args[1]

$xl = New-Object -ComObject Excel.Application
$xl.Visible = $false
$xl.DisplayAlerts = $false

$book = $xl.Workbooks.Open($file_path_excel, 0, $true)
$book.ExportAsFixedFormat(0, $file_path_pdf)

if($book -ne $null){
    $book.Close($false)
}
if($xl -ne $null){
    $xl.Quit()
}
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($book) > $null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($xl) > $null
