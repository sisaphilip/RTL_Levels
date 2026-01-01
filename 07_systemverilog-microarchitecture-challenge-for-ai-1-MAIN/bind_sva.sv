      // Syntax: bind <target_module_name> <assertion_module_name> <instance_name> (port_map);

      bind challenge assertions_file bind_inst (
      .clk     (clk),
      .rst     (rst),
      .arg_vld (arg_vld),
      .a       (a),
      .b       (b)      
      );
