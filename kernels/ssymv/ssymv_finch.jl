using Finch
using BenchmarkTools

A = Tensor(Dense(SparseList(Element(0.0))))
x = Tensor(Dense(Element(0.0)))
y = Tensor(Dense(Element(0.0)))
diag = Tensor(Dense(Element(0.0)))
temp = Scalar(0.0)

include("../../generated/ssymv.jl")

eval(@finch_kernel mode=:fast function ssymv_finch_ref_helper(y, A, x)
    y .= 0
    for j = _, i = _
        y[i] += A[i, j] * x[j]
    end
    return y
end)

function ssymv_finch_opt(y, A, x) 
    _y = Tensor(Dense(Element(0.0)), y)
    _x = Tensor(Dense(Element(0.0)), x)
    temp = Scalar(0.0)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _d = Tensor(Dense(Element(0.0)))
    @finch mode=:fast begin
        _A .= 0
        _d .= 0
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
    time = @belapsed $y2[] = ssymv_finch_opt_helper($_A2[], $_d2[], $temp2[], $_x2[], $_y2[]).y
    y = y2[]
    empty!(_A2)
    empty!(_d2)
    empty!(temp2)
    empty!(_x2)
    empty!(_y2)
    empty!(y2)

    return (;time = time, y = y)
end

function ssymv_finch_ref(y, A, x) 
    _y = Tensor(Dense(Element(0.0)), y)
    _A = Tensor(Dense(SparseList(Element(0.0))), A)
    _x = Tensor(Dense(Element(0.0)), x)

    _y2 = [_y]
    _A2 = [_A]
    _x2 = [_x]
    y2 = [_y]
    time = @belapsed $y2[] = ssymv_finch_ref_helper($_y2[], $_A2[], $_x2[]).y
    y = y2[]
    empty!(_y2)
    empty!(_A2)
    empty!(_x2)
    empty!(y2)

    return (;time = time, y = y)
end