function ConvertTo-IPv4MaskString {
  <#
  .SYNOPSIS
  Converts a number of bits (0-32) to an IPv4 network mask string (e.g., "255.255.255.0").

  .DESCRIPTION
  Converts a number of bits (0-32) to an IPv4 network mask string (e.g., "255.255.255.0").

  .PARAMETER MaskBits
  Specifies the number of bits in the mask.
  #>
  param(
    [parameter(Mandatory=$true)]
    [ValidateRange(0,32)]
    [Int] $MaskBits
  )
  $mask = ([Math]::Pow(2, $MaskBits) - 1) * [Math]::Pow(2, (32 - $MaskBits))
  $bytes = [BitConverter]::GetBytes([UInt32] $mask)
  (($bytes.Count - 1)..0 | ForEach-Object { [String] $bytes[$_] }) -join "."
}
