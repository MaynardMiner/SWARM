Using namespace System;

class filedata {
    static [hashtable] stringdata([string[]]$file) {
        $table = @{ }
        [string[]]$Data = [IO.File]::ReadAllLines($File);
        $Where = [func[string, bool]] { $args -like "*=*" };
        $Lines = [Linq.Enumerable]::Where($Data, $Where) -replace "`"", ""
        $Lines | Foreach { 
            $split = $_.split("=");
            $Name = [Linq.Enumerable]::First($split);
            $Value = [Linq.Enumerable]::Last($split);
            $table.Add($Name, $Value);
        }
        return $table
    }

    static [void] to_file([string]$filename,[hashtable]$data) {
        $file_data = @()
        $data.keys | ForEach-Object { $file_data += "$($_)=$($data.$_)" }
        [IO.File]::WriteAllLines($filename, $file_data)
    }
}