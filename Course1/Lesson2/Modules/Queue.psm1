#******************************************************************************
#
#     Function fInitializeQueue: creates an empty queue of a given length
#
#******************************************************************************

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

#******************************************************************************
#
#     Function fPushToQueue: pushes a new entry to the queue
#
#******************************************************************************

function fPushToQueue {
    param (
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

#******************************************************************************
#
#     Function fPullFromQueue: removes an entry from the queue and return it to the caller
#
#******************************************************************************

function fPullFromQueue {
    param (
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

#******************************************************************************
#
#     Function fGetQueueCurrentLength: returns the current number of entries in the queue
#
#******************************************************************************

function fGetQueueCurrentLength {
    param (
        [Parameter(Mandatory=$true)] [object]$QueueInstance
    )
    return $QueueInstance["CurrentLength"]
}

#******************************************************************************

Export-ModuleMember -Function fInitializeQueue
Export-ModuleMember -Function fPushToQueue
Export-ModuleMember -Function fPullFromQueue
Export-ModuleMember -Function fGetQueueCurrentLength