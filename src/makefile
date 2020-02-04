all:
	iverilog -g2005-sv -DICARUS=1 main.v -o main.qqq 
	vvp main.qqq >> /dev/null

wave:
	gtkwave main.vcd

gtkw:
	gtkwave main.gtkw

clean:
	rm -f main.qqq
	rm -rf db incremental_db simulation timing
	rm -f *.jdi *.pof *.sld *.rpt *.summary *.sof *.done *.pin *.qws *.bak *.smsg *.qws *.vcd *.qqq *.jic *.map *.qqq
	rm -f greybox_tmp undo_redo.txt PLLJ_PLLSPE_INFO.txt c5_pin_model_dump.txt
	rm -rf .qsys_edit 

