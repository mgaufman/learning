
param(
    [Parameter(Mandatory=$false)] [string]$Expression = ""
)

#***************************************

function fInitializeStack {
    param (
        [Parameter(Mandatory=$true)] [int]$Length
    )
    $StackInstance = @{
        "Data" = @($null)*$Length;
        "IndexOfNext" = [int]0}
    return $StackInstance
}

function fPushToStack {
    param(
        [Parameter(Mandatory=$true)] [object]$StackInstance,
        [Parameter(Mandatory=$true)] $Value
    )
    if ($StackInstance["IndexOfNext"] -eq $StackInstance["Data"].Count) {
        throw ("Stack overflow (an attempt was made to push a value to a full stack)")
    }
    $StackInstance["Data"][$StackInstance["IndexOfNext"]] = $Value
    $StackInstance["IndexOfNext"]++
    return $Value
}

function fPopFromStack {
    param(
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    if ($StackInstance["IndexOfNext"] -eq 0) {
        throw ("An attempt was made to pop a value from an empty stack")
    }
    $StackInstance["IndexOfNext"]--
    $Value = $StackInstance["Data"][$StackInstance["IndexOfNext"]]
    return $Value
}

#***************************************

function fInitializeQueue {
    param (
        [Parameter(Mandatory=$true)] [int]$Length
    )
    $QueueInstance = @{
        "Data" = @($null)*$Length;
        "IndexOfFirst"  = [int]0;
        "CurrentLength" = [int]0
    }
    return $QueueInstance
}

function fPushToQueue {
    param(
        [Parameter(Mandatory=$true)] [object]$QueueInstance,
        [Parameter(Mandatory=$true)] $Value
    )
    if ($QueueInstance["CurrentLength"] -eq $QueueInstance["Data"].Count) {
        throw ("An attempt was made to push a value to a full queue")
    }
    [int]$IndexOfNext = $QueueInstance["IndexOfFirst"] + $QueueInstance["CurrentLength"]
    if ($IndexOfNext -ge $QueueInstance["Data"].Count) {
        $IndexOfNext = $IndexOfNext - $QueueInstance["Data"].Count
    }
    $QueueInstance["Data"][$IndexOfNext] = $Value
    $QueueInstance["CurrentLength"]++
    return $Value
}

function fPullFromQueue {
    param(
        [Parameter(Mandatory=$true)] [object]$QueueInstance
    )
    if ($QueueInstance["CurrentLength"] -eq 0) {
        throw ("An attempt was made to pull a value from an empty queue")
    }
    $Value = $QueueInstance["Data"][$QueueInstance["IndexOfFirst"]]
    $QueueInstance["IndexOfFirst"]++
    if ($QueueInstance["IndexOfFirst"] -ge $QueueInstance["Data"].Count) {
        $QueueInstance["IndexOfFirst"] = $QueueInstance["IndexOfFirst"] - $QueueInstance["Data"].Count
    }
    $QueueInstance["CurrentLength"]--
    return $Value
}

#***************************************

$Operators = @{
    "#+" = [int]1; # unary plus operstor
    "#-" = [int]1; # unary minus operator
    "+"  = [int]2;
    "-"  = [int]2;
    "*"  = [int]2;
    "/"  = [int]2;
}

function fCalculateOperator {
    param (
        [Parameter(Mandatory=$true)] [string]$Operator,
        [Parameter(Mandatory=$true)] [decimal[]]$Operands
    )
    switch ($Operator) {
        "#+" {$Result = $Operands[0]; break}
        "#-" {$Result = -$Operands[0]; break}
        "+"  {$Result = $Operands[0]+$Operands[1]; break}
        "-"  {$Result = $Operands[0]-$Operands[1]; break}
        "*"  {$Result = $Operands[0]*$Operands[1]; break}
        "/"  {$Result = $Operands[0]/$Operands[1]; break}
        default: {throw ("Unknown operator encountered ($Operator) while evaluating the expression")}
    }
    return $Result
}

#***************************************

function fTokenizeExpression {
    param (
        [Parameter(Mandatory=$true)] [AllowEmptyString()] [string]$Expr,
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )

    $LocalExpr = $Expr.TrimEnd()
    if ($LocalExpr.Length -eq 0) {
        return
    }

    [string[]]$Operators = @("+", "-", "*", "/", "(", ")") # REFACTOR TO DYNAMICALLY CREATE A LIST OF SUPPORTED OPERATORS
    [string[]]$Decimals = @(".", "1", "2", "3", "4", "5", "6", "7", "8", "9")

    $Char = $LocalExpr.Substring($LocalExpr.Length-1, 1)
    if ($Char -in $Operators) {
        fPushToStack -StackInstance $StackInstance -Value $Char | Out-Null     # Out-Null prevents the function output to be passed through as return (PowerShell specifics)
        $NewExpr = $LocalExpr.Substring(0, $LocalExpr.Length-1)
    }
    elseif ($Char -in $Decimals) {
        [string]$NumericalToken = ""
        for ($i = $LocalExpr.Length - 1; $i -ge 0; $i--) {
            $Char = $LocalExpr.Substring($i, 1)
            if ($Char -in $Decimals) {
                $NumericalToken = $Char + $NumericalToken
            }
            else {
                break
            }
        }
        if ($NumericalToken.IndexOf(".") -ne $NumericalToken.LastIndexOf(".")) {
            throw ("Number $NumericalToken is incorrect (contains more than one decimal separator)")
        }
        if ($NumericalToken.Substring(0 ,1) -eq ".") {
            $NumericalToken = "0" + $NumericalToken
        }
        fPushToStack -StackInstance $StackInstance -Value $NumericalToken | Out-Null     # Out-Null prevents the function output to be passed through as return (PowerShell specifics)
        $NewExpr = $LocalExpr.Substring(0, $LocalExpr.Length-$NumericalToken.Length)
    }
    else {
        throw ("Unexpected character ($Char) encountered at position " + [string]$Expr.Length)
    }
    fTokenizeExpression -Expr $NewExpr -StackInstance $StackInstance
}

function fConvertToRpn {
    param (
        [Parameter(Mandatory=$true)] [string]$Expr,
        [Parameter(Mandatory=$true)] [int]$StackLength,
        [Parameter(Mandatory=$true)] [int]$QueueLength
    )
    [string]$RpnExpr = ""
    #STUB - REMOVE WHEN IMPLEMENTED
    $RpnExpr = $Expr
    #STUB - REMOVE WHEN IMPLEMENTED
    return $RpnExpr
}

#***************************************

function fCalculateRpnExpression {
    param (
        [Parameter(Mandatory=$true)] [string]$RpnExpr,
        [Parameter(Mandatory=$true)] [object]$Operators,
        [Parameter(Mandatory=$true)] [int]$StackLength
    )
    $Stack = fInitializeStack -Length $StackLength
    $Tokens = $RpnExpr.Split(" ")
    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        if ($Tokens[$i].Length -eq 0) {     # Skipping multiple spaces in the input string
            continue
        }
        if ($Tokens[$i] -in $Operators.Keys) {
            $Arguments = [decimal[]]@(0)*$Operators[$Tokens[$i]]
            for ($ArgNumber = $Operators[$Tokens[$i]]-1; $ArgNumber -ge 0; $ArgNumber--) {
                $Arguments[$ArgNumber] = [decimal](fPopFromStack -StackInstance $Stack)
            }
            fPushToStack -StackInstance $Stack -Value (fCalculateOperator -Operator $Tokens[$i] -Operands $Arguments) | Out-Null     # Out-Null prevents the function output to be passed through as return (PowerShell specifics)
        }
        else {
            fPushToStack -StackInstance $Stack -Value $Tokens[$i] | Out-Null     # Out-Null prevents the function output to be passed through as return (PowerShell specifics)
        }
    }
    return (fPopFromStack -StackInstance $Stack)
}

#***************************************

$ErrorActionPreference="Stop"

$MaxNumberOfTokens = 1024

while ($Expression.Length -eq 0) {
    $Expression = Read-Host -Prompt "Please enter the expression you want me to calculate ('exit' to quit)"
    if ($Expression.ToLower() -eq "exit") {
        Write-Host "Sorry to hear you have changed your mind. Bye!"
        exit
    }
}

$RpnExpression = fConvertToRpn -Expr $Expression -StackLength $MaxNumberOfTokens -QueueLength $MaxNumberOfTokens

Write-Host "The same expression in the RPN notation: $RpnExpression"

$CalculationResult = fCalculateRpnExpression -RpnExpr $RpnExpression -Operators $Operators -StackLength $MaxNumberOfTokens

Write-Host "This expression evaluates to $CalculationResult"
