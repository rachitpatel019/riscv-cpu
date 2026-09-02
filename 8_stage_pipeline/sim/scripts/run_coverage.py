#!/usr/bin/env python3
import os
import subprocess
import shutil
import sys

def main():
    # 1. Paths setup
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Workspace root is 3 levels up from 8_stage_pipeline/sim/scripts
    pipeline_dir = os.path.abspath(os.path.join(script_dir, "..", ".."))
    
    # All files created by scripts in sim/scripts/ should be located in sim/logs only
    logs_dir = os.path.join(pipeline_dir, "sim", "logs")
    cov_work_dir = os.path.join(logs_dir, "coverage_run")
    
    # Check if verilator is installed
    if shutil.which("verilator") is None:
        print("Error: 'verilator' command not found in WSL. Please install Verilator.", file=sys.stderr)
        sys.exit(1)
        
    # Check if verilator_coverage is installed
    if shutil.which("verilator_coverage") is None:
        print("Error: 'verilator_coverage' command not found in WSL. Please install Verilator coverage tool.", file=sys.stderr)
        sys.exit(1)
        
    # Recreate the coverage work dir to have a clean start
    if os.path.exists(cov_work_dir):
        shutil.rmtree(cov_work_dir)
    os.makedirs(cov_work_dir, exist_ok=True)
    
    # Copy program.hex to cov_work_dir (needed by memory / core testbenches)
    program_hex_src = os.path.join(pipeline_dir, "sim", "scripts", "program.hex")
    program_hex_dst = os.path.join(cov_work_dir, "program.hex")
    if os.path.exists(program_hex_src):
        shutil.copy2(program_hex_src, program_hex_dst)
    else:
        print(f"Warning: program.hex not found at {program_hex_src}", file=sys.stderr)
        
    # Define testbenches and their relative sources from pipeline_dir
    testbenches = {
        "tb_pc_update": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/1_fetch/pc_update.sv",
            "tb/tb_pc_update.sv"
        ],
        "tb_instr_mem": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/2_imem/instr_mem.sv",
            "tb/tb_instr_mem.sv"
        ],
        "tb_control": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/3_decode/control.sv",
            "tb/tb_control.sv"
        ],
        "tb_imm_gen": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/3_decode/imm_gen.sv",
            "tb/tb_imm_gen.sv"
        ],
        "tb_decode": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/3_decode/imm_gen.sv",
            "rtl/core/3_decode/control.sv",
            "rtl/core/3_decode/decode.sv",
            "tb/tb_decode.sv"
        ],
        "tb_regfile": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/4_reg_read/regfile.sv",
            "tb/tb_regfile.sv"
        ],
        "tb_bht": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/4_reg_read/bht.sv",
            "tb/tb_bht.sv"
        ],
        "tb_branch_predictor": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/4_reg_read/bht.sv",
            "rtl/core/4_reg_read/branch_predictor.sv",
            "tb/tb_branch_predictor.sv"
        ],
        "tb_data_sel": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/5_ex1/data_sel.sv",
            "tb/tb_data_sel.sv"
        ],
        "tb_alu": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/6_ex2/alu.sv",
            "tb/tb_alu.sv"
        ],
        "tb_branch_eval": [
            "rtl/core/6_ex2/branch_eval.sv",
            "tb/tb_branch_eval.sv"
        ],
        "tb_pc_target_calc": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/7_ex3_mem/pc_target_calc.sv",
            "tb/tb_pc_target_calc.sv"
        ],
        "tb_fwd_sel": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/7_ex3_mem/fwd_sel.sv",
            "tb/tb_fwd_sel.sv"
        ],
        "tb_data_mem": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/7_ex3_mem/data_mem.sv",
            "tb/tb_data_mem.sv"
        ],
        "tb_writeback": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/8_wb/writeback.sv",
            "tb/tb_writeback.sv"
        ],
        "tb_pipeline_control_unit": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/hazard_control/pipeline_control_unit.sv",
            "tb/tb_pipeline_control_unit.sv"
        ],
        "tb_forwarding_unit": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/hazard_control/forwarding_unit.sv",
            "tb/tb_forwarding_unit.sv"
        ],
        "tb_core": [
            "packages/alu_pkg.sv",
            "packages/decoder_pkg.sv",
            "rtl/core/1_fetch/pc_update.sv",
            "rtl/core/2_imem/instr_mem.sv",
            "rtl/core/3_decode/IF_ID.sv",
            "rtl/core/3_decode/control.sv",
            "rtl/core/3_decode/decode.sv",
            "rtl/core/3_decode/imm_gen.sv",
            "rtl/core/3_decode/ID_RR.sv",
            "rtl/core/4_reg_read/regfile.sv",
            "rtl/core/4_reg_read/bht.sv",
            "rtl/core/4_reg_read/branch_predictor.sv",
            "rtl/core/4_reg_read/RR_EX1.sv",
            "rtl/core/5_ex1/data_sel.sv",
            "rtl/core/5_ex1/EX1_EX2.sv",
            "rtl/core/6_ex2/alu.sv",
            "rtl/core/6_ex2/branch_eval.sv",
            "rtl/core/6_ex2/EX2_EX3.sv",
            "rtl/core/7_ex3_mem/pc_target_calc.sv",
            "rtl/core/7_ex3_mem/fwd_sel.sv",
            "rtl/core/7_ex3_mem/MEM_WB.sv",
            "rtl/core/7_ex3_mem/data_mem.sv",
            "rtl/core/7_ex3_mem/mmio.sv",
            "rtl/core/7_ex3_mem/memory.sv",
            "rtl/core/8_wb/writeback.sv",
            "rtl/core/hazard_control/forwarding_unit.sv",
            "rtl/core/hazard_control/pipeline_control_unit.sv",
            "rtl/core/core.sv",
            "tb/tb_core.sv"
        ]
    }
    
    failures = []
    
    # 2. Run Verilator compile & simulate for each testbench
    for tb_name, sources in testbenches.items():
        print(f"\n==========================================")
        print(f"Running Verilator functional coverage for {tb_name}")
        print(f"==========================================")
        
        # Absolute source paths
        abs_srcs = [os.path.join(pipeline_dir, src) for src in sources]
        
        # Verify inputs exist
        missing_srcs = [src for src in abs_srcs if not os.path.exists(src)]
        if missing_srcs:
            print(f"Error: Missing source files for {tb_name}: {missing_srcs}", file=sys.stderr)
            failures.append((tb_name, "Missing source files"))
            continue
            
        # Run compilation
        build_dir = f"obj_dir_{tb_name}"
        compile_cmd = [
            "timeout", "60s",
            "verilator",
            "--binary",
            "--coverage",
            "-Wno-fatal",
            "-j", "4",
            "--Mdir", build_dir,
            "-o", tb_name
        ] + abs_srcs
        
        print(f"Compiling {tb_name}...")
        comp_res = subprocess.run(compile_cmd, cwd=cov_work_dir, capture_output=True, text=True)
        if comp_res.returncode != 0:
            print(f"Error: Compilation failed for {tb_name} with code {comp_res.returncode}", file=sys.stderr)
            print(comp_res.stdout, file=sys.stderr)
            print(comp_res.stderr, file=sys.stderr)
            failures.append((tb_name, f"Compilation failed (code {comp_res.returncode})"))
            continue
            
        # Run simulation
        cov_file = f"coverage_{tb_name}.dat"
        run_cmd = [
            "timeout", "30s",
            f"./{build_dir}/{tb_name}",
            f"+verilator+coverage+file+{cov_file}"
        ]
        
        print(f"Simulating {tb_name}...")
        sim_res = subprocess.run(run_cmd, cwd=cov_work_dir, capture_output=True, text=True)
        if sim_res.returncode != 0:
            print(f"Error: Simulation failed for {tb_name} with code {sim_res.returncode}", file=sys.stderr)
            print(sim_res.stdout, file=sys.stderr)
            print(sim_res.stderr, file=sys.stderr)
            failures.append((tb_name, f"Simulation failed (code {sim_res.returncode})"))
            continue
            
        print(sim_res.stdout.strip())
        print(f"SUCCESS: {tb_name} completed.")
        
    # 3. Merge coverage data files
    print("\n==========================================")
    print("Post-processing coverage data...")
    print("==========================================")
    
    cov_files = [os.path.join(cov_work_dir, f"coverage_{tb_name}.dat") 
                 for tb_name in testbenches.keys() 
                 if os.path.exists(os.path.join(cov_work_dir, f"coverage_{tb_name}.dat"))]
                 
    if not cov_files:
        print("Error: No coverage data files were generated!", file=sys.stderr)
        sys.exit(1)
        
    merged_dat = os.path.join(cov_work_dir, "merged.dat")
    merge_cmd = ["verilator_coverage", "-write", merged_dat] + cov_files
    
    merge_res = subprocess.run(merge_cmd, capture_output=True, text=True)
    if merge_res.returncode != 0:
        print(f"Error: Failed to merge coverage files: {merge_res.stderr}", file=sys.stderr)
        sys.exit(1)
        
    # Write lcov info file
    info_file = os.path.join(logs_dir, "coverage.info")
    info_cmd = ["verilator_coverage", "-write-info", info_file, merged_dat]
    
    info_res = subprocess.run(info_cmd, capture_output=True, text=True)
    if info_res.returncode != 0:
        print(f"Error: Failed to write lcov info: {info_res.stderr}", file=sys.stderr)
        sys.exit(1)
        
    # 4. Parse the lcov info file and calculate percentage
    if not os.path.exists(info_file):
        print(f"Error: info file not found at {info_file}", file=sys.stderr)
        sys.exit(1)
        
    line_cov, branch_cov, tot_lines, hit_lines, tot_branches, hit_branches = parse_lcov_info(info_file)
    
    print("\n==========================================")
    print("REGRESSION COVERAGE SUMMARY REPORT")
    print("==========================================")
    print(f"Total Testbenches Run: {len(testbenches)}")
    print(f"Failing/Skipped Testbenches: {len(failures)}")
    for fail_tb, reason in failures:
        print(f"  - {fail_tb}: {reason}")
    print("------------------------------------------")
    print(f"Line Coverage:   {line_cov:.2f}% ({hit_lines}/{tot_lines} lines)")
    print(f"Branch Coverage: {branch_cov:.2f}% ({hit_branches}/{tot_branches} branches)")
    overall_cov = ((hit_lines + hit_branches) / (tot_lines + tot_branches) * 100.0) if (tot_lines + tot_branches) > 0 else 0.0
    print(f"Overall functional/code coverage: {overall_cov:.2f}%")
    print("------------------------------------------")
    print(f"Coverage LCOV file written to: {info_file}")
    
    # 5. Clean up build directories to save space
    shutil.rmtree(cov_work_dir, ignore_errors=True)
    
    if failures:
        sys.exit(1)
    sys.exit(0)

def parse_lcov_info(filename):
    total_lines = 0
    hit_lines = 0
    total_branches = 0
    hit_branches = 0
    
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('DA:'):
                parts = line[3:].split(',')
                if len(parts) >= 2:
                    count = int(parts[1])
                    total_lines += 1
                    if count > 0:
                        hit_lines += 1
            elif line.startswith('BRDA:'):
                parts = line[5:].split(',')
                if len(parts) >= 4:
                    count_str = parts[3]
                    if count_str == '-':
                        count = 0
                    else:
                        count = int(count_str)
                    total_branches += 1
                    if count > 0:
                        hit_branches += 1
                        
    line_cov = (hit_lines / total_lines * 100) if total_lines > 0 else 0.0
    branch_cov = (hit_branches / total_branches * 100) if total_branches > 0 else 0.0
    return line_cov, branch_cov, total_lines, hit_lines, total_branches, hit_branches

if __name__ == "__main__":
    main()
