#******************************************************************************
#
#     Function fInitializeStack: creates an empty stack of a given length
#
#******************************************************************************

function fInitializeStack {
    param (
        [Parameter(Mandatory=$true)] [int]$Length
    )
    $StackInstance = @{
        "Data" = @($null)*$Length;
        "IndexOfNext" = [int]0}
    return $StackInstance
}

#******************************************************************************
#
#     Function fPushToStack: pushes a new entry to the stack
#
#******************************************************************************
function fPushToStack {
    param (
        [Parameter(Mandatory=$true)] [object]$StackInstance,
        [Parameter(Mandatory=$true)] $Value
    )
    if ($StackInstance["IndexOfNext"] -eq $StackInstance["Data"].Count) {
        throw ("Stack overflow (an attempt was made to push a value to a full stack)")
    }
    $StackInstance["Data"][$StackInstance["IndexOfNext"]] = $Value
    $StackInstance["IndexOfNext"]++
}

#******************************************************************************
#
#     Function fPopFromStack: removes an entry from the stack and return it to the caller
#
#******************************************************************************

function fPopFromStack {
    param (
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    if ($StackInstance["IndexOfNext"] -eq 0) {
        throw ("An attempt was made to pop a value from an empty stack")
    }
    $StackInstance["IndexOfNext"]--
    return $StackInstance["Data"][$StackInstance["IndexOfNext"]]
}

#******************************************************************************
#
#     Function fPeekFromStack: returns the top entry of the stack but does not remove it
#
#******************************************************************************

function fPeekFromStack {
    param (
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    if ($StackInstance["IndexOfNext"] -eq 0) {
        throw ("An attempt was made to peek a value from an empty stack")
    }
    return $StackInstance["Data"][$StackInstance["IndexOfNext"]-1]
}

#******************************************************************************
#
#     Function fGetStackCurrentLength: returns the current number of entries in the stack
#
#******************************************************************************

function fGetStackCurrentLength {
    param (
        [Parameter(Mandatory=$true)] [object]$StackInstance
    )
    return $StackInstance["IndexOfNext"]
}

#******************************************************************************

Export-ModuleMember -Function fInitializeStack
Export-ModuleMember -Function fPushToStack
Export-ModuleMember -Function fPopFromStack
Export-ModuleMember -Function fPeekFromStack
Export-ModuleMember -Function fGetStackCurrentLength