
# NOTE: This module depends on the following modules: Operators.psm1, Queue.psm1, Stack.psm1

#******************************************************************************
#
#     Function fGetNumericChars: returns auxilliary information for parsing and processing expressions
#
#******************************************************************************

function fGetNumericChars {
    param (
        [Parameter(Mandatory=$false)][ValidateSet("All", "Separator")] [string]$Scope = "All"
    )
    $Separator = "."
    switch ($Scope.ToLower()) {
        "all"       {return [string[]]@($Separator, "0", "1", "2", "3", "4", "5", "6", "7", "8", "9")}
        "separator" {return $Separator}
    }
}

#******************************************************************************
#
#     Function fTokenizeAndValidateExpression: splits an expression into tokens (numbers, operators, parentheses) and validates the expression (assuming it uses the infix notation)
#
#******************************************************************************

function fTokenizeAndValidateExpression {
    param (
        [Parameter(Mandatory=$true)] [AllowEmptyString()] [string]$Expr,
        [Parameter(Mandatory=$true)] [int]$MaxNumberOfTokens
    )
    $TokenStack = fInitializeStack -Length $MaxNumberOfTokens
    $Operators = fGetSupportedOperators -Purpose "Operators"
    $Numerics = fGetNumericChars -Scope "All"
    $Separator = fGetNumericChars -Scope "Separator"

#   Parsing the expression into a stack of tokens (NOTE: we are parsing from the end of the expression)
    while (($Expr = $Expr.TrimEnd()).Length -ne 0) {     # The purpose of doing TrimEnd only (and not full Trim) is to maintain character positions exactly the same as in the initial expression - to report the position of a wrong character correctly if required
        $Char = $Expr.Substring($Expr.Length-1, 1)
        if (($Char -in $Operators.Keys) -or ($Char -in @("(", ")"))) {
            fPushToStack -StackInstance $TokenStack -Value $Char | Out-Null
            $Expr = ($Expr.Substring(0, $Expr.Length-1))
            continue
        }
        if ($Char -in $Numerics) {
            [string]$NumericalToken = ""
            for ($i = $Expr.Length - 1; $i -ge 0; $i--) {
                $Char = $Expr.Substring($i, 1)
                if ($Char -in $Numerics) {
                    $NumericalToken = $Char + $NumericalToken
                }
                else {
                    break
                }
            }
            fPushToStack -StackInstance $TokenStack -Value $NumericalToken | Out-Null
            $Expr = ($Expr.Substring(0, $Expr.Length-$NumericalToken.Length))
            continue
        }
        throw ("Unexpected character '$Char' encountered at position " + $Expr.Length)
    }

#   Tokens transformation & validation
    $UnaryOps = $Operators.Keys | Where-Object {$Operators[$_]["Operands"] -eq 1}
    $BinaryOps = $Operators.Keys | Where-Object {$Operators[$_]["Operands"] -eq 2}
    # Copying the tokens stack to an array
    $Tokens = @($null)*$(fGetStackCurrentLength -StackInstance $TokenStack)
    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        $Tokens[$i] = fPopFromStack -StackInstance $TokenStack
    }
    # Transforming tokens when required
    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        # Detecting unary '+' and '-' (those found either in the beginning of the expression or right after '(', '*' or '/') and replacing them with '#' and '~'
        if ($Tokens[$i] -in @("+", "-")) {
            if (($i -eq 0) -or ($Tokens[$i-1] -in @("(", "*", "/"))) {
                if ($Tokens[$i] -eq "+") {
                    $Tokens[$i] = "#"
                }
                if ($Tokens[$i] -eq "-") {
                    $Tokens[$i] = "~"
                }
            }
            continue
        }
        # Checking and modifying numeric tokens (adding leading zero for those starting with the decimal separator, and trailing zero for those ending with it)
        if ($Tokens[$i].Substring(0, 1) -in $Numerics) {
            if ($Tokens[$i].IndexOf($Separator) -ne $Tokens[$i].LastIndexOf($Separator)) {     # More than one decimal separator found in a numeric token
                throw ("Number " + $Tokens[$i] + " is incorrect (contains more than one decimal separator)")
            }
            if ($Tokens[$i].Substring(0, 1) -eq $Separator) {
                $Tokens[$i] = "0" + $Tokens[$i]
            }
            if ($Tokens[$i].Substring($Tokens[$i].Length-1, 1) -eq $Separator) {
                $Tokens[$i] = $Tokens[$i] + "0"
            }
            continue
        }
    }
    # Validation Check: An expression cannot start with a closing parenthesis or a binary operator
    if ($Tokens[0] -eq ")" -or ($Tokens[0] -in $BinaryOps)) {
        throw ("An expression cannot start with a closing parenthesis or a binary operator")
    }
    # Validation Check: An expression cannot end with an opening parenthesis or an operator
    if ($Tokens[-1] -eq "(" -or ($Tokens[-1] -in $Operators.Keys)) {
        throw ("An expression cannot end with an opening parenthesis or an operator")
    }
    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        # Validation Check: Adjacent binacy operators are not allowed
        if (($i -ne 0) -and ($Tokens[$i-1] -in $BinaryOps) -and ($Tokens[$i] -in $BinaryOps)) {
            throw ("Two binary operators cannot be adjacent to each other (a parenthesis or an operand may be missing)")
        }
        # Validation Check: Adjacent numbers are not allowed
        if (($i -ne 0) -and ($Tokens[$i-1].Substring(0, 1) -in $Numerics) -and ($Tokens[$i].Substring(0, 1) -in $Numerics)) {
            throw ("Two numbers cannot be adjacent to each other (an operator may be missing)")
        }
        # Validation Check: Not allowed positions for an opening parenthesis
        if ($Tokens[$i] -eq "(") {
            if (($i -ne $Tokens.Count-1) -and (($Tokens[$i+1] -eq ")") -or ($Tokens[$i+1] -in $BinaryOps))) {
                throw ("An opening parenthesis cannot be followed by a closing parenthesis or a binary operator")
            }
            if (($i -ne 0) -and (($Tokens[$i-1] -eq ")") -or ($Tokens[$i-1].Substring(0, 1) -in $Numerics))) {
                throw ("An opening parenthesis cannot be preceeded by a closing parenthesis or a number (an operator may be missing)")
            }
        }
        # Validation Check: Not allowed positions for a closing parenthesis
        if ($Tokens[$i] -eq ")") {
            if (($i -ne $Tokens.Count-1) -and (($Tokens[$i+1] -eq "(") -or ($Tokens[$i+1] -in $UnaryOps) -or ($Tokens[$i+1].Substring(0, 1) -in $Numerics))) {
                throw ("A closing parenthesis cannot be followed by an opening parenthesis, an unary operator or a number")
            }
            if (($i -ne 0) -and (($Tokens[$i-1] -eq "(") -or ($Tokens[$i-1] -in $Operators.Keys))) {
                throw ("A closing parenthesis cannot be preceeded by an opening parenthesis or an operator")
            }
        }
    }
#   Creating the output stack (backward copying from the array)
    for ($i = $Tokens.Count-1; $i -ge 0; $i--) {
        fPushToStack -StackInstance $TokenStack -Value $Tokens[$i] | Out-Null
    }
    return $TokenStack
}

#******************************************************************************
#
#     Function fConvertToRpn: converts an expression from the infix notation to the reverse Polish notation (RPN)
#     NOTES:
#         This function leverages the shunting-yard algorithm by Edsger Dijkstra (https://en.wikipedia.org/wiki/Shunting-yard_algorithm)
#         This function relies on the fTokenizeAndValidateExpression function to perform expression and tokens validation
#
#******************************************************************************

function fConvertToRpn {
    param (
        [Parameter(Mandatory=$true)] [string]$Expr,
        [Parameter(Mandatory=$true)] [int]$MaxNumberOfTokens
    )
    $ServiceStack = fInitializeStack -Length $MaxNumberOfTokens
    $OutputQueue = fInitializeQueue -Length $MaxNumberOfTokens
    $Operators = fGetSupportedOperators -Purpose "Operators"
    $Numerics = fGetNumericChars

#   Parsing and validating the input expression
    $TokenStack = fTokenizeAndValidateExpression -Expr $Expr -MaxNumberOfTokens $MaxNumberOfTokens
#   Processing tokens in the expression
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
            [bool]$OpeningParenthesisFound = $false
            while (((fGetStackCurrentLength -StackInstance $ServiceStack) -ne 0) -and (-not $OpeningParenthesisFound)) {
                $TopStackValue = fPopFromStack -StackInstance $ServiceStack
                if ($TopStackValue -ne "(") {
                    fPushToQueue -QueueInstance $OutputQueue -Value $TopStackValue | Out-Null
                }
                else {
                    $OpeningParenthesisFound = $true
                }
            }
            if (-not $OpeningParenthesisFound) {
                throw ("A closing parenthesis encountered without a matching opening one")
            }
            continue
        }
    }
#   Processing remaining tokens in the stack
    while ((fGetStackCurrentLength -StackInstance $ServiceStack) -ne 0) {
        $TopStackValue = fPopFromStack -StackInstance $ServiceStack
        if ($TopStackValue -eq "(") {
            throw ("An opening parenthesis encountered without a matching closing one")
        }
        fPushToQueue -QueueInstance $OutputQueue -Value $TopStackValue | Out-Null
    }
#   Building the resulting RPN string from the output queue (tokens get separated by spaces)
    [string]$RpnExpr = ""
    for ($i = (fGetQueueCurrentLength -QueueInstance $OutputQueue)-1; $i -ge 0; $i--) {
        $RpnExpr = $RpnExpr + [string](fPullFromQueue -QueueInstance $OutputQueue)
        if ($i -ne 0) {
            $RpnExpr = $RpnExpr + " "
        }
    }
    return $RpnExpr
}

#******************************************************************************
#
#     Function fCalculateRpnExpression: performs stack-based evaluation of an expression in the reverse Polish notation
#     NOTES:
#         Input expression must consist of tokens separated by spaces (all extra spaces are discarded)
#         This function does not perform expression and tokens validation (should be done prior to calling it)
#
#******************************************************************************

function fCalculateRpnExpression {
    param (
        [Parameter(Mandatory=$true)] [string]$RpnExpr,
        [Parameter(Mandatory=$true)] [int]$MaxNumberOfTokens
    )
    $Stack = fInitializeStack -Length $MaxNumberOfTokens
    $Operators = fGetSupportedOperators -Purpose "Operators"

    $Tokens = $RpnExpr.Split(" ")
    for ($i = 0; $i -lt $Tokens.Count; $i++) {
        if ($Tokens[$i].Length -eq 0) {     # Skipping multiple spaces in the input string
            continue
        }
        if ($Tokens[$i] -in $Operators.Keys) {
            $Arguments = [decimal[]]@(0)*$Operators[$Tokens[$i]]["Operands"]
            for ($ArgNumber = $Operators[$Tokens[$i]]["Operands"]-1; $ArgNumber -ge 0; $ArgNumber--) {
                try {
                    $Arguments[$ArgNumber] = [decimal](fPopFromStack -StackInstance $Stack)
                }
                catch {
                    throw ("Insufficient number of arguments provided for the operator '" + $Tokens[$i] + "'")
                }
            }
            fPushToStack -StackInstance $Stack -Value (fCalculateOperator -Operator $Tokens[$i] -Operands $Arguments) | Out-Null
        }
        else {
            fPushToStack -StackInstance $Stack -Value $Tokens[$i] | Out-Null
        }
    }
    return (fPopFromStack -StackInstance $Stack)
}

#******************************************************************************

Export-ModuleMember -Function fTokenizeAndValidateExpression
Export-ModuleMember -Function fConvertToRpn
Export-ModuleMember -Function fCalculateRpnExpression