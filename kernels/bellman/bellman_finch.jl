using Finch
using BenchmarkTools

A = Tensor(Dense(SparseList(Element(Inf))))
x = Tensor(Dense(Element(Inf)))
y = Tensor(Dense(Element(Inf)))
diag = Tensor(Dense(Element(Inf)))
temp = Scalar(Inf)

include("../../generated/bellman.jl")

eval(@finch_kernel mode=:fast function bellman_finch_ref_helper(y, A, x)
    y .= Inf
    for j = _, i = _
        y[i] <<min>>= A[i, j] + x[j]
    end
    return y
end)

function bellman_finch_opt(y, A, x) 
    _y = Tensor(Dense(Element(Inf)), y)
    _x = Tensor(Dense(Element(Inf)), x)
    temp = Scalar(Inf)
    _A = Tensor(Dense(SparseList(Element(Inf))), A)
    _d = Tensor(Dense(Element(Inf)))
    @finch mode=:fast begin
        _A .= Inf
        _d .= Inf
        for j = _, i = _
            if i < j
                _A[i, j] = A[i, j]
            end
            if i == j
                _d[i] = A[i, j]
            end
        end
    end
    
    _A2 = [_A]
    _d2 = [_d]
    temp2 = [temp]
    _x2 = [_x]
    _y2 = [_y]
    y2 = [_y]
    time = @belapsed $y2[] = bellman_finch_opt_helper($_A2[], $_d2[], $temp2[], $_x2[], $_y2[]).y
    y = y2[]
    empty!(_A2)
    empty!(_d2)
    empty!(temp2)
    empty!(_x2)
    empty!(_y2)
    empty!(y2)

    return (;time = time, y = y)
end

function bellman_finch_ref(y, A, x) 
    _y = Tensor(Dense(Element(Inf)), y)
    _A = Tensor(Dense(SparseList(Element(Inf))), A)
    _x = Tensor(Dense(Element(Inf)), x)

    _y2 = [_y]
    _A2 = [_A]
    _x2 = [_x]
    y2 = [_y]
    time = @belapsed $y2[] = bellman_finch_ref_helper($_y2[], $_A2[], $_x2[]).y
    y = y2[]
    empty!(_y2)
    empty!(_A2)
    empty!(_x2)
    empty!(y2)

    return (;time = time, y = y)
end