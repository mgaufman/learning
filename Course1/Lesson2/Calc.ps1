
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
        "#+" {$Result = $Operands[0]}
        "#-" {$Result = -$Operands[0]}
        "+"  {$Result = $Operands[0]+$Operands[1]}
        "-"  {$Result = $Operands[0]-$Operands[1]}
        "*"  {$Result = $Operands[0]*$Operands[1]}
        "/"  {$Result = $Operands[0]/$Operands[1]
        }
        default: {throw ("Unknown operator encountered ($Operator) while evaluating the expression")}
    }
    return $Result
}

#***************************************

function fConvertToRpn {
    param (
        [Parameter(Mandatory=$true)] [string]$Expr,
        [Parameter(Mandatory=$false)][int]$StackLength = 1024
    )
    [string]$RpnExpr = ""
    #STUB Shunting-yard algorithm should go here
    $RpnExpr = $Expr
    #STUB
    return $RpnExpr
}

#***************************************

function fCalculateRpnExpression {
    param (
        [Parameter(Mandatory=$true)] [string]$RpnExpr,
        [Parameter(Mandatory=$true)] [object]$Operators,
        [Parameter(Mandatory=$false)][int]$StackLength = 1024
    )
    $Stack = fInitializeStack -Length $StackLength
    $Tokens = $RpnExpr.Split(" ")
    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        if ($Tokens[$i].Length -eq 0) {     # Skipping mutiple spaces in the input string
            continue
        }
        if ($Operators.Keys -contains $Tokens[$i]) {
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

while ($Expression.Length -eq 0) {
    $Expression = Read-Host -Prompt "Please enter the expression you want me to calculate ('exit' to quit)"
    if ($Expression.ToLower() -eq "exit") {
        Write-Host "Sorry to hear you have changed your mind. Bye!"
        exit
    }
}

$RpnExpression = fConvertToRpn -Expr $Expression

Write-Host "The same expression in the RPN notation: $RpnExpression"

$CalculationResult = fCalculateRpnExpression -RpnExpr $RpnExpression -Operators $Operators

Write-Host "This expression evaluates to $CalculationResult"
