create_project -force Sequential_MAC_RegFile . -part xc7a35tcpg236-1
add_files -fileset sources_1 [file normalize "mac_seq_b.v"]
add_files -fileset sim_1 [file normalize "tb_mac_seq_b.v"]
set_property top mac_seq_b [get_filesets sources_1]
set_property top tb_mac_seq_b [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim
close_project
exit

