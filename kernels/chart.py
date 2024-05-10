import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import json
import math
from collections import defaultdict
import re

CHARTS_DIRECTORY = "charts/"
FORMAT_ORDER = {
    "finch_sym": -1,
    "finch_unsym": -2,
    "finch_unsym_row_maj": -3,
    "finch_vbl": -4,
    "finch_vbl_unsym": -5,
    "finch_vbl_unsym_row_maj": -6,
    "finch_band": -7,
    "finch_band_unsym": -8,
    "finch_band_unsym_row_maj": -9,
    "finch_pattern": -10,
    "finch_pattern_unsym": -11,
    "finch_pattern_unsym_row_maj": -12,
    "finch_point": -13,
    "finch_point_row_maj": -14,
    "finch_point_pattern": -15,
    "finch_point_pattern_row_maj": -16,
    "finch_blocked": -17,
}
FORMAT_LABELS = {
    "ssymv_opt": "SSYMV (symmetrized)",
    "ssyrk_opt": "SSYRK (symmetrized)",
    "ttm_opt": "TTM (symmetrized)",
    "mttkrp_opt": "MTTKRP (symmetrized)",
    "ssymm_opt": "SSYMM (symmetrized)",
    "syprd_opt": "SYPRD (symmetrized)"
}

def all_formats_chart(ordered_by_format=False):
    results = json.load(open(RESULTS_FILE_PATH, 'r'))
    data = defaultdict(lambda: defaultdict(int))
    finch_formats = get_best_finch_format()

    for result in results:
        mtx = result["matrix"]
        method = result["method"]
        time = result["time"]

        if method == "finch_unsym":
            # finch_baseline_time = data[mtx]["finch_baseline"]
            # data[mtx]["finch_baseline"] = time if finch_baseline_time == 0 else min(time, finch_baseline_time)
            data[mtx]["finch_baseline"] = time
        if "finch" in method and finch_formats[mtx] != method:
            continue
        method = "finch" if "finch" in method else method
        data[mtx][method] = time

    for mtx, times in data.items():
        ref_time = times["taco"]
        for method, time in times.items():
            times[method] = ref_time / time

    if ordered_by_format:
        #ordered_data = sorted(data.items(), key = lambda mtx_results: (mtx_results[1]["finch"] > 1, FORMAT_ORDER[finch_formats[mtx_results[0]]], mtx_results[1]["finch"]), reverse=True)
        ordered_data = sorted(data.items(), key = lambda mtx_results: (FORMAT_ORDER[finch_formats[mtx_results[0]]], mtx_results[1]["finch"]), reverse=True)
    else:
        ordered_data = sorted(data.items(), key = lambda mtx_results: mtx_results[1]["finch"], reverse=True)

    all_data = defaultdict(list)
    for i, (mtx, times) in enumerate(ordered_data):
        for method, time in times.items():
            all_data[method].append(time)

    ordered_mtxs = [mtx for mtx, _ in ordered_data]
    labels = [FORMAT_LABELS[finch_formats[mtx]] for mtx, _ in ordered_data]
    methods = ["finch", "finch_baseline", "julia_stdlib"]#, "suite_sparse"]
    legend_labels = ["Finch (Best)", "Finch (Baseline)", "Julia Stdlib"]#, "SuiteSparse"]
    colors = {"finch": "tab:green", "finch_baseline": "tab:gray", "julia_stdlib": "tab:blue"}#, "suite_sparse": "tab:green"}
    short_mtxs = [mtx.rsplit('/',1)[-1] for mtx in ordered_mtxs]
    new_mtxs = {
        "toeplitz_large_band": "large_band",
        "toeplitz_medium_band": "medium_band",
        "toeplitz_small_band": "small_band",
        #"TSOPF_RS_b678_c1": "*RS_b678_c1",
    }
    short_mtxs = [new_mtxs.get(mtx, mtx) for mtx in short_mtxs]

    make_grouped_bar_chart(methods, short_mtxs, all_data, colors=colors, labeled_groups=["finch"], bar_labels_dict={"finch": labels[:]}, title="SpMV Performance (Speedup Over Taco) labeled")
    make_grouped_bar_chart(methods, short_mtxs, all_data, colors=colors, title="SpMV Performance (Speedup Over Taco)")

    # for mtx in mtxs:
        # all_formats_for_matrix_chart(mtx)


def get_best_finch_format():
    results = json.load(open(RESULTS_FILE_PATH, 'r'))
    formats = defaultdict(list)
    for result in results:
        if "finch" not in result["method"]:
            continue
        formats[result["matrix"]].append((result["method"], result["time"]))

    best_formats = defaultdict(list)
    for matrix, format_times in formats.items():
        best_format, _ = min(format_times, key=lambda x: x[1])
        best_formats[matrix] = best_format
    
    return best_formats


def get_method_results(method, mtxs=[]):
    results = json.load(open(RESULTS_FILE_PATH, 'r'))
    mtx_times = {}
    for result in results:
        if "sparsity" in result and "size" in result and result["method"] == method:
            n = result["size"]
            s = result["sparsity"]
            r = result["rank"]
            nnz = n * n * n * s 
            # mtx_name = f"n = {n}, sp = {s} / {nnz}"
            mtx_name = f"{r}"
            mtx_times[mtx_name] = result["time"]
            continue
        if result["method"] == method and (mtxs == [] or result["matrix"] in mtxs):
            mtx_times[result["matrix"]] = result["time"]
    return mtx_times


def get_speedups(faster_results, slower_results):
    speedups = {}
    for mtx, slow_time in slower_results.items():
        if mtx in faster_results:
            speedups[mtx] = slow_time / faster_results[mtx]
    return speedups


def order_speedups(speedups):
    ordered = [(mtx, time) for mtx, time in speedups.items()]
    return sorted(ordered, key=lambda x: x[1], reverse=True)


def method_to_ref_comparison_chart(method, ref, title=""):
    method_results = get_method_results(method)
    ref_results = get_method_results(ref)
    speedups = get_speedups(method_results, ref_results)
    speedups = order_speedups(speedups)

    x_axis = []
    data = defaultdict(list)
    for (matrix, speedup) in speedups:
        x_axis.append(matrix)
        data[method].append(speedup)
        data[ref].append(1)

    make_grouped_bar_chart([method], x_axis, data, title=title, legend_labels=[FORMAT_LABELS[method]])

def time_percentage_chart(method, title=""):
    results = json.load(open(RESULTS_FILE_PATH, 'r'))
    mtxs = []
    diag_percentages = []
    nondiag_percentages = []
    for result in results:
        if not result["diag_time"]: 
            continue
        else:
            r = result["rank"]
            s = result["sparsity"]
            mtx_name = f"{s}"
            mtxs.append(mtx_name)
            percentage = result["diag_time"] / result["time"]
            diag_percentages.append(percentage)
            # percentage = result["nondiag_time"] / result["time"]
            nondiag_percentages.append(1.0)

    make_grouped_bar_chart_2(["Non-Diagonals", "Diagonals"], mtxs, {"Non-Diagonals": nondiag_percentages, "Diagonals": diag_percentages}, title=title, ref_line = False, colors = {"Non-Diagonals": "green", "Diagonals": "orange"})

def make_grouped_bar_chart_2(labels, x_axis, data, colors = None, labeled_groups = [], title = "", y_label = "", bar_labels_dict={}, legend_labels=None, reference_label = "", ref_line = True):
    horizontal_scale = 1
    fontfamily = "serif"

    x = np.arange(0, len(data[labels[0]]) * horizontal_scale, horizontal_scale)
    width = 0.6
    max_height = 0
    multiplier = 0
    
    fig, ax = plt.subplots(figsize=(4, 3))
    for label in labels:
        label_data = data[label]
        max_height = max(max_height, max(label_data))
        offset = width * multiplier
        if colors:
            rects = ax.bar(x + width/2, label_data, width, label=label, color=colors[label])
        else:
            rects = ax.bar(x + width/2, label_data, width, label=label, color="green")
        bar_labels = bar_labels_dict[label] if (label in bar_labels_dict) else [round(float(val), 2) if label in labeled_groups else "" for val in label_data]
        ax.bar_label(rects, padding=0, labels=bar_labels, fontsize=4, rotation=90)
        # multiplier += 1

    ax.set_ylabel("Proportion of Execution Time")
    ax.set_title(title, fontsize=12, fontfamily=fontfamily)
    ax.set_xlabel(X_LABEL)
    ax.set_xticks(x + width * (len(labels) - 1)/2, x_axis)
    ax.tick_params(axis='x', which='major', labelsize=7.5, labelrotation=60, labelfontfamily=fontfamily)
    ax.tick_params(axis='y', labelfontfamily=fontfamily)
    if legend_labels:
        ax.legend(legend_labels, loc='upper right', ncols=1, fontsize='small')
    else:
        ax.legend(loc='upper right', ncols=1)
    ax.set_ylim(0, 1.0)

        # Adjusting x-axis limits to make bars go to the edges
    ax.set_xlim(-0.5, (len(x_axis) - 0.5 + width * len(labels)) * horizontal_scale)

    if ref_line:
        plt.plot([-1, len(x_axis)], [1, 1], linestyle='--', color="tab:red", linewidth=1.25, label=reference_label)

    fig_file = title.lower().replace(" ", "_") + ".png"
    plt.savefig(CHARTS_DIRECTORY + fig_file, dpi=200, bbox_inches="tight")
    plt.close()


def make_grouped_bar_chart(labels, x_axis, data, colors = None, labeled_groups = [], title = "", y_label = "", bar_labels_dict={}, legend_labels=None, reference_label = "", ref_line = True):
    horizontal_scale = 0.5
    fontfamily = "serif"

    x = np.arange(0, len(data[labels[0]]) * horizontal_scale, horizontal_scale)
    width = 0.3
    max_height = 0
    
    fig, ax = plt.subplots(figsize=(12, 3))
    for label in labels:
        label_data = data[label]
        max_height = max(max_height, max(label_data))
        if colors:
            rects = ax.bar(x, label_data, width, label=label, color=colors[label])
        else:
            rects = ax.bar(x, label_data, width, label=label)
        bar_labels = bar_labels_dict[label] if (label in bar_labels_dict) else [round(float(val), 2) if label in labeled_groups else "" for val in label_data]
        ax.bar_label(rects, padding=0, labels=bar_labels, fontsize=4, rotation=90)

    ax.set_ylabel("Speedup Relative to Naive Kernel")
    ax.set_title(title, fontsize=11, fontfamily=fontfamily)
    ax.set_xlabel("Matrix")
    ax.set_xticks(x + width * (len(labels) - 1)/2, x_axis)
    ax.tick_params(axis='x', which='major', labelsize=7, labelrotation=75, labelfontfamily=fontfamily)
    ax.tick_params(axis='y', labelfontfamily=fontfamily)
    # if legend_labels:
    #     ax.legend(legend_labels, loc='upper left', ncols=2, fontsize='small')
    # else:
    #     ax.legend(loc='upper left', ncols=2)
    ax.set_ylim(0, max_height + 0.25)

        # Adjusting x-axis limits to make bars go to the edges
    ax.set_xlim(-0.5, (len(x_axis) - 0.5 + width * len(labels)) * horizontal_scale)

    if ref_line:
        plt.plot([-1, len(x_axis)], [1, 1], linestyle='--', color="tab:red", linewidth=1.25, label=reference_label)

    fig_file = title.lower().replace(" ", "_") + ".png"
    plt.savefig(CHARTS_DIRECTORY + fig_file, dpi=200, bbox_inches="tight")
    plt.close()
    

X_LABEL = "Sparsity"

# RESULTS_FILE_PATH = "ssymv/ssymv_results.json"
# RESULTS_FILE_PATH = "ttm/ttm_finch_separate_diagonals_sparsities.json"
# RESULTS_FILE_PATH = "mttkrp/mttkrp_dim4_final_sparsity.json"
# RESULTS_FILE_PATH = "mttkrp/mttkrp_dim4_final_rank.json"
# RESULTS_FILE_PATH = "mttkrp/mttkrp_final_rank.json"
# RESULTS_FILE_PATH = "mttkrp/mttkrp_final_sparsity.json"
RESULTS_FILE_PATH = "ssymm/ssymm_results.json"
# RESULTS_FILE_PATH = "ssyrk/ssyrk_results.json"
# RESULTS_FILE_PATH = "syprd/syprd_results.json"


# method_to_ref_comparison_chart("ssymv_opt", "ssymv_ref", "Optimized vs. Naive SSYMV Performance")
# method_to_ref_comparison_chart("ttm_opt", "ttm_ref", "Optimized vs. Naive TTM Performance")
# method_to_ref_comparison_chart("mttkrp_opt", "mttkrp_ref", "Optimized vs. Naive 4D MTTKRP Performance Varying Rank")
# method_to_ref_comparison_chart("mttkrp_opt", "mttkrp_ref", "4D MTTKRP Performance")
method_to_ref_comparison_chart("ssymm_opt", "ssymm_ref", "Optimized vs. Naive SSYMM Performance")
# method_to_ref_comparison_chart("ssyrk_opt", "ssyrk_ref", "Optimized vs. Naive SSYRK Performance")
# time_percentage_chart("mttkrp_opt", "Optimized MTTKRP Time Distribution Varying Sparsity")
# time_percentage_chart("mttkrp_opt", "Optimized 4D MTTKRP Time Distribution Varying Sparsity")
# method_to_ref_comparison_chart("syprd_opt", "syprd_ref", "Optimized vs. Naive SYPRD Performance")
