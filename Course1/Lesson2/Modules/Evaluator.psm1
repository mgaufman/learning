
function fGetNumericChars {
    return [string[]]@(".", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
}

function fTokenizeExpression {
    param (
        [Parameter(Mandatory=$true)] [AllowEmptyString()] [string]$Expr,
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    $Controls = fGetSupportedOperators -Purpose "Controls"
    $Numerics = fGetNumericChars

    $LocalExpr = $Expr.TrimEnd()     # The purpose of NOT doing TrimStart is to maintain character positions exactly the same as in the initial expression - to report the position of a wrong character correctly if required
    while ($LocalExpr.Length -ne 0) {
        $Char = $LocalExpr.Substring($LocalExpr.Length-1, 1)
        if ($Char -in $Controls) {
            $NewExpr = ($LocalExpr.Substring(0, $LocalExpr.Length-1)).TrimEnd()     # TrimEnd is important here for subsequent distinguishing of binary vs unary plus and minus operators
            $Token = $Char
    #       Distinguishing binary vs unary plus and minus operators
            if ($Char -in @("+", "-")) {
                if (($NewExpr.Length -eq 0) -or ($NewExpr.Substring($NewExpr.Length-1, 1) -eq "(") -or ($NewExpr.Substring($NewExpr.Length-1, 1) -in $Operators.Keys)) {
                    if ($Char -eq "+") {
                        $Token = "#"
                    }
                    if ($Char -eq "-") {
                        $Token = "~"
                    }
                }
            }
            fPushToStack -StackInstance $StackInstance -Value $Token | Out-Null     # Out-Null prevents the function output to be passed through as return (PowerShell specifics)
        }
        elseif ($Char -in $Numerics) {
            [string]$NumericalToken = ""
            for ($i = $LocalExpr.Length - 1; $i -ge 0; $i--) {
                $Char = $LocalExpr.Substring($i, 1)
                if ($Char -in $Numerics) {
                    $NumericalToken = $Char + $NumericalToken
                }
                else {
                    break
                }
            }
            $NewExpr = ($LocalExpr.Substring(0, $LocalExpr.Length-$NumericalToken.Length))     # It is important to calculate $NewExpr fisrt since we modify $NumericalToken further in the function
            if ($NumericalToken.IndexOf(".") -ne $NumericalToken.LastIndexOf(".")) {
                throw ("Number $NumericalToken is incorrect (contains more than one decimal separator)")
            }
            if ($NumericalToken.Substring(0, 1) -eq ".") {
                $NumericalToken = "0" + $NumericalToken
            }
            if ($NumericalToken.Substring($NumericalToken.Length-1, 1) -eq ".") {
                $NumericalToken = $NumericalToken + "0"
            }
            fPushToStack -StackInstance $StackInstance -Value $NumericalToken | Out-Null
        }
        else {
            throw ("Unexpected character '$Char' encountered at position " + [string]$LocalExpr.Length)
        }
        $LocalExpr = $NewExpr.TrimEnd()
    }
}

function fConvertToRpn {     # This function uses the shunting-yard algorithm by Edsger Dijkstra
    param (
        [Parameter(Mandatory=$true)] [string]$Expr,
        [Parameter(Mandatory=$true)] [int]$StackLength,
        [Parameter(Mandatory=$true)] [int]$QueueLength
    )

    $ServiceStack = fInitializeStack -Length $StackLength
    $OutputQueue = fInitializeQueue -Length $QueueLength
    $Operators = fGetSupportedOperators -Purpose "Operators"
    $Numerics = fGetNumericChars

    $TokenStack = fInitializeStack -Length $StackLength
    fTokenizeExpression -Expr $Expr -StackInstance $TokenStack
    while ((fGetStackCurrentLength -StackInstance $TokenStack) -ne 0) {
        $Token = fPopFromStack -StackInstance $TokenStack
        if ($Token.Substring(0, 1) -in $Numerics) {
            fPushToQueue -QueueInstance $OutputQueue -Value $Token | Out-Null
            continue
        }
        if ($Token -in $Operators.Keys) {
            while ((fGetStackCurrentLength -StackInstance $ServiceStack) -ne 0) {
                $TopStackValue = fPeekFromStack -StackInstance $ServiceStack
                if (($TopStackValue -in $Operators.Keys) -and ($Operators[$TopStackValue]["Precedence"] -ge $Operators[$Token]["Precedence"])) {
                    $TopStackValue = fPopFromStack -StackInstance $ServiceStack
                    fPushToQueue -QueueInstance $OutputQueue -Value $TopStackValue | Out-Null
                }
                else {
                    break
                }
            }
            fPushToStack -StackInstance $ServiceStack -Value $Token | Out-Null
            continue
        }
        if ($Token -eq "(") {
            fPushToStack -StackInstance $ServiceStack -Value $Token | Out-Null
            continue
        }
        if ($Token -eq ")") {
            [bool]$OpeningBracketFound = $false
            while (((fGetStackCurrentLength -StackInstance $ServiceStack) -ne 0) -and (-not $OpeningBracketFound)) {
                $TopStackValue = fPopFromStack -StackInstance $ServiceStack
                if ($TopStackValue -ne "(") {
                    fPushToQueue -QueueInstance $OutputQueue -Value $TopStackValue | Out-Null
                }
                else {
                    $OpeningBracketFound = $true
                }
            }
            if (-not $OpeningBracketFound) {
                throw ("A closing bracket encountered without a matching opening one")
            }
            continue
        }
    }
    while ((fGetStackCurrentLength -StackInstance $ServiceStack) -ne 0) {
        $TopStackValue = fPopFromStack -StackInstance $ServiceStack
        if ($TopStackValue -eq "(") {
            throw ("An opening bracket encountered without a matching closing one")
        }
        fPushToQueue -QueueInstance $OutputQueue -Value $TopStackValue | Out-Null
    }
    [string]$RpnExpr = ""
    for ($i = (fGetQueueCurrentLength -QueueInstance $OutputQueue)-1; $i -ge 0; $i--) {
        $RpnExpr = $RpnExpr + [string](fPullFromQueue -QueueInstance $OutputQueue)
        if ($i -ne 0) {
            $RpnExpr = $RpnExpr + " "
        }
    }
    return $RpnExpr
}

function fCalculateRpnExpression {
    param (
        [Parameter(Mandatory=$true)] [string]$RpnExpr,
        [Parameter(Mandatory=$true)] [int]$StackLength
    )
    $Stack = fInitializeStack -Length $StackLength
    $Operators = fGetSupportedOperators -Purpose "Operators"

    $Tokens = $RpnExpr.Split(" ")
    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        if ($Tokens[$i].Length -eq 0) {     # Skipping multiple spaces in the input string
            continue
        }
        if ($Tokens[$i] -in $Operators.Keys) {
            $Arguments = [decimal[]]@(0)*$Operators[$Tokens[$i]]["Operands"]
            for ($ArgNumber = $Operators[$Tokens[$i]]["Operands"]-1; $ArgNumber -ge 0; $ArgNumber--) {
                $Arguments[$ArgNumber] = [decimal](fPopFromStack -StackInstance $Stack)
            }
            fPushToStack -StackInstance $Stack -Value (fCalculateOperator -Operator $Tokens[$i] -Operands $Arguments) | Out-Null
        }
        else {
            fPushToStack -StackInstance $Stack -Value $Tokens[$i] | Out-Null
        }
    }
    return (fPopFromStack -StackInstance $Stack)
}

Export-ModuleMember -Function fGetNumericChars
Export-ModuleMember -Function fTokenizeExpression
Export-ModuleMember -Function fConvertToRpn
Export-ModuleMember -Function fCalculateRpnExpression