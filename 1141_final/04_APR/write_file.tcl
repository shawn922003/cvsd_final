setAnalysisMode -analysisType bcwc
write_sdf  -max_view av_func_mode_max -min_view av_func_mode_min -edges noedge -splitsetuphold -remashold -splitrecrem -min_period_edges none Netlist/bch_apr.sdf

setStreamOutMode -specifyViaName default -SEvianames false -virtualConnection false -uniquifyCellNamesPrefix false -snapToMGrid false -textSize 1 -version 3 
streamOut bch.gds  -mapFile /home/raid7_4/raid1_1/PnR/SOCE_Lab/streamOut.map  -merge { /home/raid7_4/raid1_1/PnR/SOCE_Lab/library/gds/tsmc13gfsg_fram.gds /home/raid7_4/raid1_1/PnR/SOCE_Lab/library/gds/tpz013g3_v1.1.gds }  -stripes 1  -units 1000  -mode ALL 