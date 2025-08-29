`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2025 08:33:46 PM
// Design Name: 
// Module Name: test_flip_flop
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


class transaction;
    /* data test */
    rand logic din;
    logic dout;
    logic clk;
    logic rst;

    /* print data test */
    function void print_data();
        $display("[TR] din = %0d", din);
    endfunction

    /* deep copy object transaction */
    function transaction clone();
        transaction clone_obj = new();
        clone_obj.din = this.din;
        return clone_obj;
    endfunction
endclass

class generator;
    /* class in-use */
    transaction trans;

    /* mailbox gen - drv class */
    mailbox #(transaction) mb_gen_drv;
    /* mailbox gen - sco class */
    mailbox #(transaction) mb_gen_sco;

    /* event gen - sco class */
    event gen_and_sco_evt;
    /* event gen - env class */
    event gen_to_env_evt;

    /* memory allocation */
    function new(mailbox #(transaction) mb_gen_drv, mailbox #(transaction) mb_gen_sco, event gen_and_sco_evt, event gen_to_env_evt);
        this.mb_gen_drv      = mb_gen_drv;
        this.mb_gen_sco      = mb_gen_sco;
        this.trans           = new();
        this.gen_and_sco_evt = gen_and_sco_evt;
        this.gen_to_env_evt  = gen_to_env_evt;
    endfunction

    /* main task */
    task run();
        for(int index = 0; index < 10; index ++) begin
            $display("------------------------");
            $display("[GEN] generated data[%0d]", index);
            this.trans.randomize();
            this.trans.print_data();
            this.mb_gen_drv.put(trans.clone());
            this.mb_gen_sco.put(trans.clone());
            @(gen_and_sco_evt);
            $display("[GEN] receive SCO event, continue generate testing data");
        end
        ->gen_to_env_evt;
        $display("[GEN] complete generate data test, end test");
    endtask
endclass

class driver;
    /* class in-use */
    transaction tr;

    /* DUT interface */
    virtual dff_if vif;

    /* mailbox gen - drv class */
    mailbox #(transaction) mb_gen_drv;
  
    /* memory allocation */
    function new(mailbox #(transaction) mb_gen_drv, virtual dff_if vif);
      this.vif        = vif;
      this.mb_gen_drv = mb_gen_drv;
    endfunction
  
    /* reset DUT task */
    task reset();
        this.vif.rst <= 1;
        for(int index = 0; index < 5; index ++) begin
          @(posedge this.vif.clk);
        end
        this.vif.rst <= 0;
        $display("[DRV] reset done");
    endtask

    /* main task */
    task run();
      forever begin
          this.tr = new();
          this.mb_gen_drv.get(tr);
          this.vif.din <= tr.din;
          @(posedge vif.clk);
      end
    endtask

endclass

class monitor;
    /* class in-use */
    transaction tr;
    
    /* DUT interface */
    virtual dff_if vif;

    /* mailbox mon - sco class */
    mailbox #(transaction) mb_mon_sco;

    /* memory allocation */
    function new(mailbox #(transaction) mb_mon_sco, virtual dff_if vif);
      this.mb_mon_sco = mb_mon_sco;
      this.vif        = vif;
    endfunction

    /* main task */
    task run();
      forever begin
          this.tr = new();
          @(posedge this.vif.clk);
          @(posedge this.vif.clk);
          this.tr.dout = this.vif.dout;
          this.mb_mon_sco.put(tr);
          $display("[MON] dout = %0d", tr.dout);
      end
    endtask
endclass

class scoreboard;    
    /* class in-use */
    transaction tr_gen;
    transaction tr_ref;

    /* mailbox gen - sco class */
    mailbox #(transaction) mb_gen_sco;
    /* mailbox mon - sco class */
    mailbox #(transaction) mb_mon_sco;

    /* event gen - sco class */
    event gen_and_sco_evt;

    /* memory allocation */
    function new(mailbox #(transaction) mb_gen_sco, mailbox #(transaction) mb_mon_sco, event gen_and_sco_evt);
      this.tr_gen = new();
      this.tr_ref = new();
      this.mb_gen_sco      = mb_gen_sco;
      this.mb_mon_sco      = mb_mon_sco;
      this.gen_and_sco_evt = gen_and_sco_evt;
    endfunction

    /* main task */
    task run();
      forever begin
          this.mb_gen_sco.get(tr_gen);
          this.mb_mon_sco.get(tr_ref);
          if(this.tr_gen.din == this.tr_ref.dout)
            $display("[SCO] PASS");
          else
            $display("[SCO] FAIL");
          /* notice to gen class that sco class complete job */  
          ->this.gen_and_sco_evt;
          $display("[SCO] complete sco job, sent event to gen class");
      end
    endtask
endclass

class enviroment;
    /* class in-use */
    generator  gen;
    driver     drv;
    monitor    mon;
    scoreboard sco;

    /* mailbox gen - drv class */
    mailbox #(transaction) mb_gen_drv;
    /* mailbox mon - sco class */
    mailbox #(transaction) mb_mon_sco;
    /* mailbox gen - sco class */
    mailbox #(transaction) mb_gen_sco;

    /* event sco - gen class */
    event sco_to_gen_evt;
    /* event gen - env class */
    event gen_to_env_evt;

    /* DUT interface */
    virtual dff_if vif;

    /* memory allocation */
    function new(virtual dff_if vif);
        this.vif = vif;
        this.mb_gen_drv = new();
        this.mb_mon_sco = new();
        this.mb_gen_sco = new();
        this.gen   = new(this.mb_gen_drv, this.mb_gen_sco, this.sco_to_gen_evt, this.gen_to_env_evt);
        this.drv   = new(this.mb_gen_drv, this.vif);
        this.mon   = new(this.mb_mon_sco, this.vif);
        this.sco   = new(this.mb_gen_sco, this.mb_mon_sco, this.sco_to_gen_evt);
    endfunction

    /* pre test */
    task pre_test();
        drv.reset();
    endtask

    /* main test */
    task test();
        fork
            this.gen.run();
            this.drv.run();
            this.mon.run();
            this.sco.run();
        join_any
    endtask

    /* post test */
    task post_test();
        wait(this.gen.gen_to_env_evt.triggered);
        $display("[ENV] end test");
        $finish();
    endtask

    /* run all test phase */
    task run();
        pre_test();
        test();
        post_test();
    endtask
endclass

module test_flip_flop();
    /* enviroment */
    enviroment env;

    /* connect test bench module to DUT */
    dff_if if_dut();
    dff dut(if_dut);

    /* init clock */
    initial begin
      if_dut.clk <= 0;
    end

    /* generate clk f = 50kHz */
    always begin 
      #10;
      if_dut.clk <= ~if_dut.clk;
    end

    /* start test */
    initial begin
      env = new(if_dut);
      env.run();
    end
endmodule



