
open System

let rec fCalcOneOp (rpnList : list<string>) =
    match rpnList with
    | "" :: rest -> rest // removing empty strings resulted from Split(" ") applied to multiple consequent spaces
    | x :: "#" :: rest -> x :: rest
    | x :: "~" :: rest -> (string (- decimal x)) :: rest
    | x :: y :: "+" :: rest -> (string (decimal x + decimal y)) :: rest
    | x :: y :: "-" :: rest -> (string (decimal x - decimal y)) :: rest
    | x :: y :: "*" :: rest -> (string (decimal x * decimal y)) :: rest
    | x :: y :: "/" :: rest -> (string (decimal x / decimal y)) :: rest
    | head :: tail -> head :: fCalcOneOp tail
    | [] -> []

let rec fCalcFullExpr (rpnList : list<string>) =
    match rpnList.Length with
    | 0 -> ["0"]
    | 1 -> rpnList
    | _ -> 
        let calcOneOpResult = fCalcOneOp rpnList
        if rpnList.Length = calcOneOpResult.Length then failwith "Either wrong tokens encountered or wrong operators/operands order." // infinite recursion (means the expression does not converge to a single element)
        fCalcFullExpr (calcOneOpResult)

[<EntryPoint>]
let main argv =
    Console.WriteLine "\n*** Sample RPN expression evaluator program ***"
    Console.WriteLine ("Supported operators:\n    # (unary plus) \n    ~ (unary minus)\n    + (binary plus)\n    - (binary minus)\n    * (multiplication)\n    / (division)")
    Console.Write ("Please enter the RPN expression you want me to calculate (use space to separate tokens): ")
    let rpnExpr : string = Console.ReadLine()
    let rpnList = rpnExpr.Split(" ") |> Array.toList
    try
        Console.WriteLine ("Calculation result: {0}", (decimal (fCalcFullExpr rpnList |> List.head)))
        0
    with
       | ex ->
            Console.WriteLine ("Error while evaluating the expression: {0}", (ex.Message))
            1
