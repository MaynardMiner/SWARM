Using namespace System;

class Logging {

    ## Simply write
    [void] screen ([string[]]$text) {
        $text | ForEach-Object {
            [Console]::WriteLine($_);
        }
    }

    ## Write with color
    [void] screen ([string[]]$text, [string]$option) {

        [ConsoleColor]$Default = [Console]::ForegroundColor;
        if ($option -ne "nonewline") { 
            [Console]::ForegroundColor = $option 
            $text | ForEach-Object {
                [Console]::WriteLine($_);
            }
        }
        else {
            $text | ForEach-Object {
                [Console]::Write($_);
            }
        }
        [Console]::ForegroundColor = $Default
    }

    ## Write with color no new line
    [void] screen ([string]$text, [string]$color, [string]$NoNewLine) {
        [ConsoleColor]$Default = [Console]::ForegroundColor;
        [Console]::ForegroundColor = $color;
        [Console]::Write($text);
        [Console]::ForegroundColor = $Default
    }
}