
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
        "Pointer" = [int]0}
    return $StackInstance
}

function fPushToStack {
    param(
        [Parameter(Mandatory=$true)] [object]$StackInstance,
        [Parameter(Mandatory=$true)] $Value
    )
    if ($StackInstance["Pointer"] -eq $StackInstance["Data"].Count) {
        throw ("Stack overflow (an attempt was made to push a value to a full stack)")
    }
    $StackInstance["Data"][$StackInstance["Pointer"]] = $Value
    $StackInstance["Pointer"]++
    return $Value
}

function fPopFromStack {
    param(
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    if ($StackInstance["Pointer"] -eq 0) {
        throw ("An attempt was made to pop a value from an empty stack")
    }
    $StackInstance["Pointer"]--
    $Value = $StackInstance["Data"][$StackInstance["Pointer"]]
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
        [Parameter(Mandatory=$true)] [float[]]$Operands
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
        if ($Operators.Keys -contains $Tokens[$i]) {
            $Arguments = [float[]]@(0)*$Operators[$Tokens[$i]]
            for ($ArgNumber = $Operators[$Tokens[$i]]-1; $ArgNumber -ge 0; $ArgNumber--) {
                $Arguments[$ArgNumber] = [float](fPopFromStack -StackInstance $Stack)
            }
            $Dummy = fPushToStack -StackInstance $Stack -Value (fCalculateOperator -Operator $Tokens[$i] -Operands $Arguments) # $Dummy prevents the function output to be passed through as return (PowerShell specifics)
        }
        else {
            $Dummy = fPushToStack -StackInstance $Stack -Value $Tokens[$i]                                                 # $Dummy prevents the function output to be passed through as return (PowerShell specifics)
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
