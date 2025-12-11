------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_array_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
entity clock_measure_vivado_wrp is
	generic
	(
		-- Component Parameters
		NumOfClocks_g				: positive	:= 4;
		AxiClkFreq_g				: positive 	:= 125_000_000;
		MaxClkFreq_g				: positive	:= 500_000_000
	);
	port
	(
		-- Data Ports
		Clocks					: in std_logic_vector(NumOfClocks_g-1 downto 0);
		
		-----------------------------------------------------------------------------
		-- Axi Slave Bus Interface
		-----------------------------------------------------------------------------
		-- System
		s00_axi_aclk                : in    std_logic;                                             -- Global Clock Signal
		s00_axi_aresetn             : in    std_logic;                                             -- Global Reset Signal. This signal is low active.
		-- Read address channel
		s00_axi_araddr              : in    std_logic_vector(7 downto 0);                          -- Read address. This signal indicates the initial address of a read burst transaction.
		s00_axi_arvalid             : in    std_logic;                                             -- Write address valid. This signal indicates that the channel is signaling valid read address and control information.
		s00_axi_arready             : out   std_logic;                                             -- Read address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
		-- Read data channel
		s00_axi_rdata               : out   std_logic_vector(31 downto 0);                         -- Read Data
		s00_axi_rresp               : out   std_logic_vector(1 downto 0);                          -- Read response. This signal indicates the status of the read transfer.
		s00_axi_rvalid              : out   std_logic;                                             -- Read valid. This signal indicates that the channel is signaling the required read data.
		s00_axi_rready              : in    std_logic;                                             -- Read ready. This signal indicates that the master can accept the read data and response information.
		-- Write address channel
		s00_axi_awaddr              : in    std_logic_vector(7 downto 0);                          -- Write address
		s00_axi_awvalid             : in    std_logic;                                             -- Write address valid. This signal indicates that the channel is signaling valid write address and control information.
		s00_axi_awready             : out   std_logic;                                             -- Write address ready. This signal indicates that the slave is ready to accept an address and associated control signals.
		-- Write data channel
		s00_axi_wdata               : in    std_logic_vector(31    downto 0);                      -- Write Data
		s00_axi_wstrb               : in    std_logic_vector(3 downto 0);                          -- Write strobes. This signal indicates which byte lanes hold valid data. There is one write strobe bit for each eight bits of the write data bus.
		s00_axi_wvalid              : in    std_logic;                                             -- Write valid. This signal indicates that valid write data and strobes are available.
		s00_axi_wready              : out   std_logic;                                             -- Write ready. This signal indicates that the slave can accept the write data.
		-- Write response channel
		s00_axi_bresp               : out   std_logic_vector(1 downto 0);                          -- Write response. This signal indicates the status of the write transaction.
		s00_axi_bvalid              : out   std_logic;                                             -- Write response valid. This signal indicates that the channel is signaling a valid write response.
		s00_axi_bready              : in    std_logic                                              -- Response ready. This signal indicates that the master can accept a write response.		
	);

end entity clock_measure_vivado_wrp;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of clock_measure_vivado_wrp is 

	-- Array of desired number of chip enables for each address range
	constant USER_SLV_NUM_REG               : integer              := 32; 
	
	-- IP Interconnect (IPIC) signal declarations
	signal reg_rd                    		: std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	signal reg_rdata                 		: t_aslv32(0 to USER_SLV_NUM_REG-1) := (others => (others => '0'));
	signal reg_wr                    		: std_logic_vector(USER_SLV_NUM_REG-1 downto  0);
	signal reg_wdata                 		: t_aslv32(0 to USER_SLV_NUM_REG-1);	
	
	-- Ohter Signals 
	signal AxiRst							: std_logic;
	

begin

	AxiRst <= not s00_axi_aresetn;

   -----------------------------------------------------------------------------
   -- AXI decode instance
   -----------------------------------------------------------------------------
   axi_slave_reg_inst : entity work.psi_common_axilite_slave_ipif
   generic map
   (
      -- Users parameters
      NumReg_g                    => USER_SLV_NUM_REG,
	  UseMem_g                    => false,
      -- Parameters of Axi Slave Bus Interface
      AxiAddrWidth_g              => 8
   )
   port map
   (
      --------------------------------------------------------------------------
      -- Axi Slave Bus Interface
      --------------------------------------------------------------------------
      -- System
      s_axilite_aclk              => s00_axi_aclk,
      s_axilite_aresetn           => s00_axi_aresetn,
      -- Read address channel
      s_axilite_araddr            => s00_axi_araddr,
      s_axilite_arvalid           => s00_axi_arvalid,
      s_axilite_arready           => s00_axi_arready,
      -- Read data channel
      s_axilite_rdata             => s00_axi_rdata,
      s_axilite_rresp             => s00_axi_rresp,
      s_axilite_rvalid            => s00_axi_rvalid,
      s_axilite_rready            => s00_axi_rready,
      -- Write address channel
      s_axilite_awaddr            => s00_axi_awaddr,
      s_axilite_awvalid           => s00_axi_awvalid,
      s_axilite_awready           => s00_axi_awready,
      -- Write data channel
      s_axilite_wdata             => s00_axi_wdata,
      s_axilite_wstrb             => s00_axi_wstrb,
      s_axilite_wvalid            => s00_axi_wvalid,
      s_axilite_wready            => s00_axi_wready,
      -- Write response channel
      s_axilite_bresp             => s00_axi_bresp,
      s_axilite_bvalid            => s00_axi_bvalid,
      s_axilite_bready            => s00_axi_bready,
      --------------------------------------------------------------------------
      -- Register Interface
      --------------------------------------------------------------------------
      o_reg_rd                    => reg_rd,
      i_reg_rdata                 => reg_rdata,
      o_reg_wr                    => reg_wr,
      o_reg_wdata                 => reg_wdata
   );
   
	-----------------------------------------------------------------------------
	-- Clock Measurements
	-----------------------------------------------------------------------------  	
	g_meas : for idx in 0 to NumOfClocks_g-1 generate
		i_meas : entity work.single_clock_measurement
			generic map (
				MasterFrequency_g	=> AxiClkFreq_g,
				MaxMeasFrequency_g	=> MaxClkFreq_g
			)
			port map (
				ClkMaster		=> s00_axi_aclk,
				Rst				=> AxiRst,
				FrequencyHz		=> reg_rdata(idx),
				ClkTest			=> Clocks(idx)
			);
	end generate;
   
	
  
end rtl;
