<#
SWARM is open-source software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
SWARM is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>
function Tee-ObjectNoColor {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [String]$InputObject,
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$FilePath
    )

    process {
        $Logs = $InputObject -replace '\\[\d+(;\d+)?m'
        $Logs | Out-File $FilePath -Append
        $Logs | Write-Host
    }
}

function Open-Colored([String] $Filename)
{Write-Colored($Filename)}

function Write-Colored([String] $text) {
    # split text at ESC-char
    $split = $text.Split([char] 27)
    foreach ($line in $split) {
        if ($line[0] -ne '[')
        { Write-Host $line -NoNewline }
        else {
            if (($line[1] -eq '0') -and ($line[2] -eq 'm')) { Write-Host $line.Substring(3) -NoNewline }
            elseif (($line[1] -eq '0') -and ($line[2] -eq '1')) { Write-Host $line.Substring(3) -NoNewline -ForegroundColor White }           
            elseif (($line[1] -eq '3') -and ($line[3] -eq 'm')) {
                # normal color codes
                if ($line[2] -eq '0') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor Black       }
                elseif ($line[2] -eq '1') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkRed     }
                elseif ($line[2] -eq '2') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkGreen   }
                elseif ($line[2] -eq '3') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkYellow  }
                elseif ($line[2] -eq '4') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkBlue    }
                elseif ($line[2] -eq '5') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkMagenta }
                elseif ($line[2] -eq '6') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor DarkCyan    }
                elseif ($line[2] -eq '7') { Write-Host $line.Substring(4) -NoNewline -ForegroundColor Gray        }
            }
            elseif (($line[1] -eq '3') -and ($line[3] -eq ';') -and ($line[5] -eq 'm')) {
                # bright color codes
                if ($line[2] -eq '0') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor DarkGray    }
                elseif ($line[2] -eq '1') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Red         }
                elseif ($line[2] -eq '2') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Gree        }
                elseif ($line[2] -eq '3') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Yellow      }
                elseif ($line[2] -eq '4') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Blue        }
                elseif ($line[2] -eq '5') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Magenta     }
                elseif ($line[2] -eq '6') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor Cyan        }
                elseif ($line[2] -eq '7') { Write-Host $line.Substring(6) -NoNewline -ForegroundColor White       }
            }
        }
    }
}