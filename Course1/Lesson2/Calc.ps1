
param (
    [Parameter(Mandatory=$false)] [string]$Expression = "",
    [Parameter(Mandatory=$false)] [int]$MaxNumberOfTokens = 1024,     # maximum number of tokens (numbers, operators, parentheses) allowed in the expression
    [Parameter(Mandatory=$false)] [switch]$ConciseOutput = $false     # if $true the script will output the calculation result only (useful for automated testing)
)

# Initializing
$ErrorActionPreference="Stop"
Import-Module -Name "./Modules/Stack.psm1" -DisableNameChecking
Import-Module -Name "./Modules/Queue.psm1" -DisableNameChecking
Import-Module -Name "./Modules/Operators.psm1" -DisableNameChecking
Import-Module -Name "./Modules/Evaluator.psm1" -DisableNameChecking

# Introduction
if (-not $ConciseOutput) {
    Write-Host "`n*** Sample calculator (expression evaluator) program ***"
    Write-Host ("*** Supported operators: "+(fGetSupportedOperators -Purpose "Help")+" ***")
    Write-Host "*** Parentheses are supported ***`n"
}

# Reading input if no expression is provided in the command line
while ($Expression.Trim().Length -eq 0) {
    $Expression = Read-Host -Prompt "Please enter the expression you want me to calculate (use dot as a decimal separator; type 'exit' to quit)"
    if ($Expression.ToLower() -eq "exit") {
        Write-Host "`nSorry to hear you have changed your mind. Bye!`n"
        exit
    }
}
if (-not $ConciseOutput) {
    Write-Host "Original expression: $Expression"
}

# Converting to RPN and displaying the result
try {
    $RpnExpression = fConvertToRpn -Expr $Expression -MaxNumberOfTokens $MaxNumberOfTokens
    if (-not $ConciseOutput) {
        Write-Host "The same expression in the RPN notation ('#' stands for unary '+', '~' stands for unary '-'): $RpnExpression"
    }
}
catch {
    Write-Host -ForegroundColor Red "Error while parsing the expression: $_"
    Write-Verbose ("*** Stack Trace ***`n" + $_.ScriptStackTrace)
    exit 1
}

# Evaluating the expression
try {
    $CalculationResult = fCalculateRpnExpression -RpnExpr $RpnExpression -MaxNumberOfTokens $MaxNumberOfTokens
    if (-not $ConciseOutput) {
        Write-Host "This expression evaluates to $CalculationResult`n"
    }
    else {
        Write-Output $CalculationResult
    }
}
catch {
    Write-Host -ForegroundColor Red "Error while calculating the expression: $_"
    Write-Verbose ("*** Stack Trace ***`n" + $_.ScriptStackTrace)
    exit 2
}