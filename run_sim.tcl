open_project [file normalize "Sequential_MAC_RegFile.xpr"]
set_property top mac_seq_b [get_filesets sources_1]
set_property top tb_mac_seq_b [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim
close_project
exit
