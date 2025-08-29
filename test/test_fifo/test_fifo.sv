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
    rand logic operation;
    logic wr;
    logic rd;
    logic [7:0] data_in;
    logic [7:0] data_out;
    logic full;
    logic empty;
    logic clk;
    logic rst;
    
    constraint operation_control 
    {
        operation dist {1 :/ 50, 0 :/ 50};
    }

    /* print data test */
    function void print_data();
        $display("[TR] operation = %0d", operation);
    endfunction

    /* deep copy object transaction */
    function transaction clone();
        transaction clone_obj = new();
        clone_obj.operation = this.operation;
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
        for(int index = 0; index < 15; index ++) begin
            $display("------------------------");
            $display("[GEN] generated data[%0d]", index);
            this.trans.randomize();
            this.trans.print_data();
            this.mb_gen_drv.put(trans.clone());
            this.mb_gen_sco.put(trans.clone());
            @(gen_and_sco_evt);
            $display("[GEN] receive [SCO] event, continue generate testing data");
        end
        ->gen_to_env_evt;
        $display("[GEN] complete generate data test, end test");
    endtask
endclass

class driver;
    /* class in-use */
    transaction tr;

    /* DUT interface */
    virtual fifo_if vif;

    /* mailbox gen - drv class */
    mailbox #(transaction) mb_gen_drv;
  
    /* memory allocation */
    function new(mailbox #(transaction) mb_gen_drv, virtual fifo_if vif);
      this.vif        = vif;
      this.mb_gen_drv = mb_gen_drv;
    endfunction
  
    /* reset DUT task */
    task reset();
        this.vif.rst <= 1;
        for(int index = 0; index < 5; index ++) begin
          @(posedge this.vif.clock);
        end
        this.vif.rst <= 0;
        $display("[DRV] reset done");
    endtask

    task write();
        @(posedge this.vif.clock);
        this.vif.wr <= 1;
        this.vif.rd <= 0;
        this.vif.data_in <= $urandom_range(1, 10);
        @(posedge this.vif.clock);
        $display("[DRV] Write data = %0d", this.vif.data_in);
        this.vif.wr <= 0;
        @(posedge this.vif.clock);
    endtask

    task read();
        $display("[DRV] Read data");
        @(posedge this.vif.clock);
        this.vif.wr <= 0;
        this.vif.rd <= 1;
        @(posedge this.vif.clock);
        this.vif.rd <= 0;
        @(posedge this.vif.clock);
    endtask

    /* main task */
    task run();
      forever begin
          this.tr = new();
          this.mb_gen_drv.get(tr);
          if(tr.operation == 1) begin
              this.write();
          end else begin
              this.read();
          end 
      end
    endtask

endclass

class monitor;
    /* class in-use */
    transaction tr;
    
    /* DUT interface */
    virtual fifo_if vif;

    /* mailbox mon - sco class */
    mailbox #(transaction) mb_mon_sco;

    /* memory allocation */
    function new(mailbox #(transaction) mb_mon_sco, virtual fifo_if vif);
      this.mb_mon_sco = mb_mon_sco;
      this.vif        = vif;
    endfunction

    /* main task */
    task run();
      forever begin
          this.tr = new();
          @(posedge this.vif.clock);
          @(posedge this.vif.clock);
          this.tr.data_in  = this.vif.data_in;
          this.tr.rd       = this.vif.rd;
          this.tr.wr       = this.vif.wr;
          this.tr.full     = this.vif.full;
          this.tr.empty    = this.vif.empty;
          @(posedge this.vif.clock);
          this.tr.data_out = this.vif.data_out;
          this.mb_mon_sco.put(tr);
          $display("[MON] empty = %d, full = %d wr = %d rd = %d data_in = %d data_out = %0d", tr.empty, tr.full, tr.wr, tr.rd, tr.data_in, tr.data_out); 
      end
    endtask
endclass

class scoreboard;    
    /* class in-use */
    transaction tr_gen;
    transaction tr_ref;

    /* data write to FIFO */
    logic [7:0] data[$];
    logic [7:0] temp_1;
    logic [7:0] temp_2;

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

          if(tr_gen.operation == 1) begin
              $display("[SCO] PUSH sample data");
              data.push_back(tr_ref.data_in);
          end

          if(tr_gen.operation == 0) begin
              if(tr_ref.empty == 0) begin
                  temp_1 = tr_ref.data_out;
                  temp_2 = data.pop_front();
                  if(temp_1 == temp_2) begin
                      $display("[SCO] PASS");
                  end else begin
                      $display("[SCO] FAIL");
                  end
              end
          end

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
    virtual fifo_if vif;

    /* memory allocation */
    function new(virtual fifo_if vif);
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

module test_fifo();
    /* enviroment */
    enviroment env;

    /* connect test bench module to DUT */
    fifo_if if_dut();
    FIFO dut(if_dut);

    /* init clock */
    initial begin
      if_dut.clock <= 0;
    end

    /* generate clk f = 50kHz */
    always begin 
      #10;
      if_dut.clock <= ~if_dut.clock;
    end

    /* start test */
    initial begin
      env = new(if_dut);
      env.run();
    end
endmodule



