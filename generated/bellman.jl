eval(@finch_kernel mode=:fast function bellman_finch_opt_helper(A, diag, temp, x, y)
    y .= Inf
    for j = _
        temp .= Inf
        for i = _
            let A_ij = A[i, j]
                y[i] <<min>>= +(A_ij, x[j])
                temp[] <<min>>= +(A_ij, x[i])
            end
        end
        y[j] <<min>>= +(diag[j], x[j])
        y[j] <<min>>= temp[]
    end
    return y
end)

