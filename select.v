module select (
	/* output */
	g0, g1, g2, g3, R,
	/* input */
	r0, r1, r2, r3, G
);

/*
 * output
 */
output reg g0;
output reg g1;
output reg g2;
output reg g3;
output reg R;


/*
 * input
 */
input	r0;
input	r1;
input	r2;
input	r3;
input   G;


assign g0 = G && (r0);
assign g1 = G && (!r0 && r1);
assign g2 = G && (!r0 && !r1 && r2);
assign g3 = G && (!r0 && !r1 && !r2 && r3);
assign R  = r0 || r1 || r2 || r3;

endmodule
