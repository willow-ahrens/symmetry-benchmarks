eval(@finch_kernel mode=:fast function syprd_finch_opt_helper(A, diag, x, y)
    y .= 0
    for j = _
        for i = _
            y[] += *(2, *(A[i, j], x[j], x[i]))
        end
        y[] += *(x[j], diag[j], x[j])
    end
    return y
end)

