
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
}

function fPopFromStack {
    param(
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    if ($StackInstance["IndexOfNext"] -eq 0) {
        throw ("An attempt was made to pop a value from an empty stack")
    }
    $StackInstance["IndexOfNext"]--
    return $StackInstance["Data"][$StackInstance["IndexOfNext"]]
}

function fPeekFromStack {
    param(
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    if ($StackInstance["IndexOfNext"] -eq 0) {
        throw ("An attempt was made to peek a value from an empty stack")
    }
    return $StackInstance["Data"][$StackInstance["IndexOfNext"]-1]
}

function fGetStackCurrentLength {
    param(
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    return $StackInstance["IndexOfNext"]
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

function fGetQueueCurrentLength {
    param(
        [Parameter(Mandatory=$true)] [object]$QueueInstance
    )
    return $QueueInstance["CurrentLength"]
}

#***************************************

$Operators = @{
    "#" = @{"Operands" = [int]1; "Precedence" =[int]9}; # unary plus operstor
    "~" = @{"Operands" = [int]1; "Precedence" =[int]9}; # unary minus operator
    "+" = @{"Operands" = [int]2; "Precedence" =[int]3};
    "-" = @{"Operands" = [int]2; "Precedence" =[int]3};
    "*" = @{"Operands" = [int]2; "Precedence" =[int]6};
    "/" = @{"Operands" = [int]2; "Precedence" =[int]6};
}
[string[]]$Controls = @("(", ")") + $Operators.Keys

function fCalculateOperator {
    param (
        [Parameter(Mandatory=$true)] [string]$Operator,
        [Parameter(Mandatory=$true)] [decimal[]]$Operands
    )
    switch ($Operator) {
        "#" {$Result = $Operands[0]; break}
        "~" {$Result = -$Operands[0]; break}
        "+" {$Result = $Operands[0]+$Operands[1]; break}
        "-" {$Result = $Operands[0]-$Operands[1]; break}
        "*" {$Result = $Operands[0]*$Operands[1]; break}
        "/" {$Result = $Operands[0]/$Operands[1]; break}
        default: {throw ("Unknown operator encountered ($Operator) while evaluating the expression")}
    }
    return $Result
}

#***************************************

[string[]]$Decimals = @(".", "1", "2", "3", "4", "5", "6", "7", "8", "9")

function fTokenizeExpression {
    param (
        [Parameter(Mandatory=$true)] [AllowEmptyString()] [string]$Expr,
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )

    $LocalExpr = $Expr.TrimEnd()     # The purpose of NOT doing TrimStart is to maintain character positions exactly the same as in the initial expression - to report the position of a wrong character correctly if required
    if ($LocalExpr.Length -eq 0) {
        return
    }

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
        fPushToStack -StackInstance $StackInstance -Value $NumericalToken | Out-Null     # Out-Null prevents the function output to be passed through as return (PowerShell specifics)
    }
    else {
        throw ("Unexpected character ($Char) encountered at position " + [string]$Expr.Length)
    }
#   Calling the same function recursively after the last token has been peeled off from the expression to the stack
    fTokenizeExpression -Expr $NewExpr -StackInstance $StackInstance
}

function fConvertToRpn {
    param (
        [Parameter(Mandatory=$true)] [string]$Expr,
        [Parameter(Mandatory=$true)] [int]$StackLength,
        [Parameter(Mandatory=$true)] [int]$QueueLength
    )

    $ServiceStack = fInitializeStack -Length $StackLength
    $OutputQueue = fInitializeQueue -Length $QueueLength

    $TokenStack = fInitializeStack -Length $StackLength
    fTokenizeExpression -Expr $Expr -StackInstance $TokenStack
    while ((fGetStackCurrentLength -StackInstance $TokenStack) -ne 0) {
        $Token = fPopFromStack -StackInstance $TokenStack
        if ($Token.Substring(0, 1) -in $Decimals) {
            fPushToQueue -QueueInstance $OutputQueue -Value $Token | Out-Null
            continue
        }
        if ($Token -in $Operators.Keys) {
            while ((fGetStackCurrentLength -StackInstance $ServiceStack) -ne 0) {
                $TopStackValue = fPeekFromStack -StackInstance $ServiceStack
                if (($TopStackValue -in $Operators.Keys) -and ($Operators[$TopStackValue]["Precedence"] -ge $Operators[$TopStackValue]["Precedence"])) {
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
            while ((fGetStackCurrentLength -StackInstance $ServiceStack) -ne 0) {
                $TopStackValue = fPeekFromStack -StackInstance $ServiceStack
                if ($TopStackValue -ne "(") {
                    $TopStackValue = fPopFromStack -StackInstance $ServiceStack
                    fPushToQueue -QueueInstance $OutputQueue -Value $TopStackValue | Out-Null
                }
                else {
                    $TopStackValue = fPopFromStack -StackInstance $ServiceStack
                    break
# ДОБАВИТЬ ОБРАБОТКУ: Если стек закончился до того, как был встречен токен открывающая скобка, то в выражении пропущена скобка.
                }
            }
            continue
        }
    }
    while ((fGetStackCurrentLength -StackInstance $ServiceStack) -ne 0) {
        $TopStackValue = fPopFromStack -StackInstance $ServiceStack
# ДОБАВИТЬ ОБРАБОТКУ: Если токен оператор на вершине стека — открывающая скобка, то в выражении пропущена скобка
        fPushToQueue -QueueInstance $OutputQueue -Value $TopStackValue | Out-Null
    }
    #STUB - REMOVE WHEN IMPLEMENTED
    $RpnExpr = $Expr
    #STUB - REMOVE WHEN IMPLEMENTED
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

while ($Expression.Trim().Length -eq 0) {
    $Expression = Read-Host -Prompt "Please enter the expression you want me to calculate ('exit' to quit)"
    if ($Expression.ToLower() -eq "exit") {
        Write-Host "Sorry to hear you have changed your mind. Bye!"
        exit
    }
}

$RpnExpression = fConvertToRpn -Expr $Expression -StackLength $MaxNumberOfTokens -QueueLength $MaxNumberOfTokens

Write-Host "The same expression in the RPN notation: $RpnExpression"

$CalculationResult = fCalculateRpnExpression -RpnExpr $RpnExpression -StackLength $MaxNumberOfTokens

Write-Host "This expression evaluates to $CalculationResult"
