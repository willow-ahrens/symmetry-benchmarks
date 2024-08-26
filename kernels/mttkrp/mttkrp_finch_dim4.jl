using Finch
import Finch.FinchNotation: and, or
using BenchmarkTools

A = Tensor(Dense(SparseList(SparseList(SparseList(Element(0.0))))))
A_nondiag = Tensor(Dense(SparseList(SparseList(SparseList(Element(0.0))))))
A_diag = Tensor(Dense(SparseList(SparseList(SparseList(Element(0.0))))))
B = Tensor(Dense(Dense(Element(0.0))))   
B_T = Tensor(Dense(Dense(Element(0.0)))) 
C = Tensor(Dense(Dense(Element(0.0))))
C_T = Tensor(Dense(Dense(Element(0.0))))

include("../../generated/mttkrp_dim4.jl")

eval(@finch_kernel mode=:fast function mttkrp_finch_ref_dim4_helper(C_T, A, B_T)
    C_T .= 0
    for m=_, l=_, k=_, i=_, j=_
        C_T[j, i] += A[i, k, l, m] * B_T[j, l] * B_T[j, k] * B_T[j, m]
    end
    return C_T
end)

function mttkrp_finch_ref_dim4(C, A, B)
    (n, r) = size(C)
    _C_T = Tensor(Dense(Dense(Element(0.0))), zeros(r, n))
    _A = Tensor(Dense(SparseList(SparseList(SparseList(Element(0.0))))), A)  
    _B_T = Tensor(Dense(Dense(Element(0.0))), B) 
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end  

    _C_T2 = [_C_T]
    _A2 = [_A]
    _B_T2 = [_B_T]
    time = @belapsed mttkrp_finch_ref_dim4_helper($_C_T2[], $_A2[], $_B_T2[])
    empty!(_C_T2)
    empty!(_A2)
    empty!(_B_T2)
    _C = Tensor(Dense(Dense(Element(0.0))), C)
    @finch begin 
        _C .= 0
        for j=_, i=_
            _C[i, j] = _C_T[j, i]
        end
    end
    
    return (;time = time, C = _C)
end

function mttkrp_finch_opt_dim4(C, A, B)
    (n, n, n) = size(A)
    (n, r) = size(C)
    _C_T_nondiag = Tensor(Dense(Dense(Element(0.0))), zeros(r, n))
    _C_T_diag = Tensor(Dense(Dense(Element(0.0))), zeros(r, n))

    nondiagA = zeros(n, n, n, n)
    diagA = zeros(n, n, n, n)
    for l=1:n, k=1:n, j=1:n, i=1:n
        if i != j && j != k && k != l && i != k && i != l && j != l
            nondiagA[i, j, k, l] = A[i, j, k, l]
        end
        if i == j || j == k || k == l || i == k || i == l || j == l
            diagA[i, j, k, l] = A[i, j, k, l]
        end
    end
    _A_nondiag = Tensor(Dense(SparseList(SparseList(SparseList(Element(0.0))))), nondiagA)
    _A_diag = Tensor(Dense(SparseList(SparseList(SparseList(Element(0.0))))), diagA)

    _B_T = Tensor(Dense(Dense(Element(0.0))), B) 
    @finch mode=:fast begin 
        _B_T .= 0
        for j=_, i=_ 
            _B_T[j, i] = B[i, j] 
        end 
    end

    _A_nondiag2 = [_A_nondiag]
    _A_diag2 = [_A_diag]
    _B_T2 = [_B_T]
    _C_T_nondiag2 = [_C_T_nondiag]
    _C_T_diag2 = [_C_T_diag]
    time_1 = @belapsed mttkrp_dim4_finch_opt_helper_base($_A_nondiag, $_B_T, $_C_T_nondiag)
    time_2 = @belapsed mttkrp_dim4_finch_opt_helper_edge($_A_diag, $_B_T, $_C_T_diag)
    empty!( _A_nondiag2)
    empty!(_A_diag2)
    empty!(_B_T2)
    empty!(_C_T_nondiag2)
    empty!(_C_T_diag2)
    C_full = Tensor(Dense(Dense(Element(0.0))), C)
    @finch mode=:fast for i=_, j=_
        C_full[i, j] = _C_T_nondiag[j, i] + _C_T_diag[j, i]
    end
    return (;time = time_1 + time_2, C = C_full, nondiag_time = time_1, diag_time = time_2)
end