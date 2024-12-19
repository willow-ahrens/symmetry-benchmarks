eval(@finch_kernel mode=:fast function ssyrk_finch_opt_helper(A, _C1)
    _C1 .= 0
    for k = _, j = _, i = _
        if (i <= j)
            _C1[i, j] += *(A[i, k], A[j, k])
        end
    end
    return _C1
end)

