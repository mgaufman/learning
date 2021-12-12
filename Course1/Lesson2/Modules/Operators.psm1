
# NOTE: When adding, MODIFYING, or removing an operator make sure the changes are reflected in all functions (3 places as of 12.12.2021)

function fGetSupportedOperators {
    param (
        [Parameter(Mandatory=$false)][ValidateSet("Operators", "Help")] [string]$Purpose = "Operators"
    )
    $Operators = @{
        "#" = @{"Operands" = [int]1; "Precedence" =[int]9};     # unary plus operstor
        "~" = @{"Operands" = [int]1; "Precedence" =[int]9};     # unary minus operator
        "+" = @{"Operands" = [int]2; "Precedence" =[int]3};
        "-" = @{"Operands" = [int]2; "Precedence" =[int]3};
        "*" = @{"Operands" = [int]2; "Precedence" =[int]6};
        "/" = @{"Operands" = [int]2; "Precedence" =[int]6};
    }
    switch ($Purpose.ToLower()) {
        "operators" {return $Operators}
        "help"      {return ("'+' (unary and binary), '-' (unary and binary), '*' and '/'")}
    }
}

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

Export-ModuleMember -Function fGetSupportedOperators
Export-ModuleMember -Function fCalculateOperator