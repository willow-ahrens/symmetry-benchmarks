using Random
using SparseArrays
using MatrixMarket

# Function to generate a sparse 10x10x10 tensor with a given density of non-zero elements
function generate_sparse_tensor(dims::NTuple{3, Int}, density::Float64)
    tensor = zeros(dims...)
    num_elements = prod(dims)
    num_non_zeros = round(Int, density * num_elements)
    
    for _ in 1:num_non_zeros
        i = rand(1:dims[1])
        j = rand(1:dims[2])
        k = rand(1:dims[3])
        tensor[i, j, k] = rand()
    end
    
    return tensor
end

dims = (10, 10, 10)
density = 0.05  # 5% density of non-zero elements
t = generate_sparse_tensor(dims, density)

MatrixMarket.mmwrite("tensor.mtx", t)

