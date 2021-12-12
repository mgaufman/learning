
$Tests = @{
	"1+2" = [decimal]3;
	"1 + 2*3" = [decimal]7;
	"45.1 *2 - 1.20" = [decimal]89;
	"10 /3*3" = [decimal]10;
	"-((3+(10-7)*(-4)))" = [decimal]9;
}

foreach ($Expr in $Tests.Keys) {
	Write-Host "Testing the expression $Expr"
	$Result =(./Calc.ps1 -Expression $Expr -ConciseOutput)
	if ($Result -eq $Tests[$Expr]) {
		Write-Host -ForegroundColor Green ("    Result: $Result. Test passed.")
	}
	else {
		Write-Host -ForegroundColor Red ("    Result: $Result. Test failed (expected result: "+$Tests[$Expr]+").")
	}
}