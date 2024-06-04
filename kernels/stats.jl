using JSON

function calc_speedup(slow_method, fast_method)
    spmv_results_text = read("ttm/cgo_ttm_results.json", String)
    spmv_results = JSON.parse(spmv_results_text)

    kernel_times = Dict()
    for result in spmv_results
        kernel = result["matrix"]
        method = result["method"]
        time = result["time"]

        times = get(kernel_times, kernel, Dict())
        times[method] = time
        kernel_times[kernel] = times
    end

    count = 0
    speedup = 0
    for (kernel, times) in kernel_times
        try
            # if times[slow_method] > times[fast_method]
                speedup += times[slow_method] / times[fast_method]
                count += 1
            # end
        catch e
            println("Insufficient results for ", kernel)
        end
    end

    return speedup / count
end