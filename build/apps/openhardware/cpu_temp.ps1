using namespace OpenHardwareMonitor.Hardware;

Class CPU_Temp {
    static [int[]] Get() {
        $temp_array = @();
        [Computer]$computer = [Computer]::New();
        $computer.CPUEnabled = $true;
        $computer.Open();
        foreach($hardware in $computer.Hardware) {
            $hardware.Update();
        }    
        $data = $hardware.Sensors | Where name -eq "CPU Package" | Where SensorType -eq "Temperature"
        foreach($temp in $data) {
            $temp_array += $temp.Value;
        }
        $computer.Close();
        return $temp_array;
    }
}