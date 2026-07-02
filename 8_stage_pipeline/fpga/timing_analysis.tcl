# 8-Stage Pipeline Timing Analysis Script (Balanced)
# This script calculates the propagation delay (data delay) for each stage of the 8-stage pipeline.
# It should be run AFTER a full compilation in Quartus.
# Usage: quartus_sta -t timing_analysis.tcl

package require ::quartus::project
package require ::quartus::sta

# Change directory to the script's directory so it can be run from the repository root
set script_dir [file normalize [file dirname [info script]]]
cd $script_dir

# Configuration
set project_name "cpu"

# Verify project files exist
if {![file exists "${project_name}.qpf"] || ![file exists "${project_name}.qsf"]} {
    puts "Error: Quartus project file(s) ${project_name}.qpf or ${project_name}.qsf not found."
    exit 1
}

# Open the project and build timing netlist
puts "Opening project and loading timing netlist..."
if {[catch {
    project_open $project_name
    create_timing_netlist
    read_sdc
    update_timing_netlist
} err]} {
    puts "Error: Failed to initialize timing netlist: $err"
    puts "Ensure that the project has been fully compiled before running timing analysis."
    catch { project_close }
    exit 1
}
puts "Timing netlist updated."

# Define the pipeline stages {Display Name, Source Pattern, Destination Pattern}
set stages {
    {"Stage 1: Fetch Logic"         ""                          "*stage2_imem*address_reg*"}
    {"Stage 2: I-Mem Read"          "*stage2_imem*address_reg*" "*stage3_if_id_reg*instruction_out*"}
    {"Stage 3: Decode & Hazard"     "*stage3_if_id_reg*instruction_out*"  "*stage3_id_rr_reg|*out*"}
    {"Stage 4: Register Read"       "*stage3_id_rr_reg|*out*"   "*stage4_rr_ex1_reg|*out*"}
    {"Stage 5: EX1 (Op Sel)"        "*stage4_rr_ex1_reg|*out*"  "*stage5_ex1_ex2_reg|*out*"}
    {"Stage 6: EX2 (ALU)"           "*stage5_ex1_ex2_reg|*out*" "*stage6_ex2_ex3_reg|*out*"}
    {"Stage 7: EX3 & MEM Addr"      "*stage6_ex2_ex3_reg|*out*" "*stage7_mem_wb_reg|*out*"}
    {"Stage 8: WB Logic"            "*stage7_mem_wb_reg|*out*"  "*stage4_regfile|*"}
}

# Helper to print to stdout and flush
proc log {msg} {
    puts $msg
    flush stdout
}

log "------------------------------------------------------------"
log "  8-Stage Balanced Pipeline Propagation Delays"
log "------------------------------------------------------------"
log [format "%-30s | %-12s" "Pipeline Stage" "Delay (ns)"]
log "------------------------------------------------------------"

foreach stage $stages {
    set name [lindex $stage 0]
    set from_pat [lindex $stage 1]
    set to_pat [lindex $stage 2]
    
    set delay "N/A"
    
    set to_regs [get_registers $to_pat]
    if {[get_collection_size $to_regs] == 0} {
        log [format "%-30s | %-12s" $name "Not Found"]
        continue
    }

    if {$from_pat == ""} {
        set paths [get_timing_paths -to $to_regs -npaths 1 -setup]
    } else {
        set from_regs [get_registers $from_pat]
        if {[get_collection_size $from_regs] == 0} {
            log [format "%-30s | %-12s" $name "Src Not Found"]
            continue
        }
        set paths [get_timing_paths -from $from_regs -to $to_regs -npaths 1 -setup]
    }
    
    if {[get_collection_size $paths] > 0} {
        foreach_in_collection path $paths {
            set delay [get_path_info $path -data_delay]
            log [format "%-30s | %-12s" $name "${delay} ns"]
            break
        }
    } else {
        log [format "%-30s | %-12s" $name "No Path"]
    }
}

log "\n------------------------------------------------------------"
log "  Top 10 Most Critical Paths (Worst Slack)"
log "------------------------------------------------------------"
log [format "%-7s | %-10s | %-50s" "Slack" "Data Dly" "Destination Node"]
log "------------------------------------------------------------"

set critical_paths [get_timing_paths -npaths 10 -setup]
foreach_in_collection path $critical_paths {
    set slack [get_path_info $path -slack]
    set delay [get_path_info $path -data_delay]
    set to_node [get_node_info -name [get_path_info $path -to]]
    
    log [format "%-7s | %-10s | %-50s" "${slack}ns" "${delay}ns" $to_node]
}

log "------------------------------------------------------------"

puts "\nTiming analysis complete."

# Clean up
delete_timing_netlist
project_close
