module adder32_tb;
logic [31:0] a, b;
logic cin;
logic [31:0] sum;
logic cout;


logic [32:0] expected;
int pass = 0, fail = 0;


adder32 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));


task check;
expected = a + b + cin;
if ({cout, sum} === expected) begin
pass++;
$display("PASS: a=%h b=%h cin=%b sum=%h", a, b, cin, sum);
end else begin
fail++;
$display("FAIL: a=%h b=%h cin=%b exp=%h got=%h", a, b, cin, expected, {cout,sum});
end
endtask


initial begin

a=0; b=0; cin=0; #1; check();
a=32'hFFFFFFFF; b=32'hFFFFFFFF; cin=0; #1; check();
a=32'hFFFFFFFF; b=1; cin=0; #1; check();



repeat (100) begin
a = $random;
b = $random;
cin = $random;
#1; check();
end


$display("Adder Test Summary: PASS=%0d FAIL=%0d", pass, fail);
$finish;
end
endmodule
