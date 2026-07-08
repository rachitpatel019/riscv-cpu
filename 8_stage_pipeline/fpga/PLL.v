// megafunction wizard: %ALTPLL%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altpll 

// ============================================================
// File Name: PLL.v
// Megafunction Name(s):
// 			altpll
// ============================================================

`timescale 1 ns / 1 ps
module PLL (
	input  wire  inclk0,
	output wire  c0,
	output wire  locked
);

	wire [4:0] sub_wire0;
	wire [0:0] sub_wire4 = 1'b0;
	wire [0:0] sub_wire1 = inclk0;
	wire [1:0] sub_wire2 = {sub_wire4, sub_wire1};
	wire  c0_out = sub_wire0[0];
	assign c0 = c0_out;

	altpll #(
		.bandwidth_type("AUTO"),
		.clk0_divide_by(2),
		.clk0_duty_cycle(50),
		.clk0_multiply_by(5),
		.clk0_phase_shift("0"),
		.compensate_clock("CLK0"),
		.inclk0_input_frequency(20000), // 20000 ps = 50 MHz input
		.intended_device_family("MAX 10"),
		.lpm_type("altpll"),
		.operation_mode("NORMAL"),
		.pll_type("AUTO"),
		.port_activeclock("PORT_UNUSED"),
		.port_areset("PORT_UNUSED"),
		.port_clkbad0("PORT_UNUSED"),
		.port_clkbad1("PORT_UNUSED"),
		.port_clkloss("PORT_UNUSED"),
		.port_clk0("PORT_USED"),
		.port_clk1("PORT_UNUSED"),
		.port_clk2("PORT_UNUSED"),
		.port_clk3("PORT_UNUSED"),
		.port_clk4("PORT_UNUSED"),
		.port_clk5("PORT_UNUSED"),
		.port_clkena0("PORT_UNUSED"),
		.port_clkena1("PORT_UNUSED"),
		.port_clkena2("PORT_UNUSED"),
		.port_clkena3("PORT_UNUSED"),
		.port_clkena4("PORT_UNUSED"),
		.port_clkena5("PORT_UNUSED"),
		.port_extclk0("PORT_UNUSED"),
		.port_extclk1("PORT_UNUSED"),
		.port_extclk2("PORT_UNUSED"),
		.port_extclk3("PORT_UNUSED"),
		.port_extdata0("PORT_UNUSED"),
		.port_extdata1("PORT_UNUSED"),
		.port_fbin("PORT_UNUSED"),
		.port_inclk0("PORT_USED"),
		.port_inclk1("PORT_UNUSED"),
		.port_locked("PORT_USED"),
		.port_pfdena("PORT_UNUSED"),
		.port_phasecounterselect("PORT_UNUSED"),
		.port_phasedone("PORT_UNUSED"),
		.port_phasestep("PORT_UNUSED"),
		.port_phaseupdown("PORT_UNUSED"),
		.port_pllena("PORT_UNUSED"),
		.port_scanaclr("PORT_UNUSED"),
		.port_scanclk("PORT_UNUSED"),
		.port_scanclkena("PORT_UNUSED"),
		.port_scandata("PORT_UNUSED"),
		.port_scandataout("PORT_UNUSED"),
		.port_scandone("PORT_UNUSED"),
		.port_scanread("PORT_UNUSED"),
		.port_scanwrite("PORT_UNUSED"),
		.port_vcooverrange("PORT_UNUSED"),
		.port_vcounderrange("PORT_UNUSED"),
		.width_clock(5)
	) altpll_component (
		.inclk (sub_wire2),
		.clk (sub_wire0),
		.locked (locked),
		.activeclock (),
		.areset (1'b0),
		.clkbad (),
		.clkena (),
		.clkloss (),
		.enable0 (),
		.enable1 (),
		.extclk (),
		.extclkena (),
		.fbin (),
		.fbmimicbidir (),
		.fbout (),
		.configupdate (1'b0),
		.pfdena (1'b1),
		.phasecounterselect (4'd0),
		.phasedone (),
		.phasestep (1'b0),
		.phaseupdown (1'b0),
		.pllena (1'b1),
		.scanaclr (1'b0),
		.scanclk (1'b0),
		.scanclkena (1'b1),
		.scandata (1'b0),
		.scandataout (),
		.scandone (),
		.scanread (1'b0),
		.scanwrite (1'b0),
		.vcooverrange (),
		.vcounderrange ()
	);

endmodule
