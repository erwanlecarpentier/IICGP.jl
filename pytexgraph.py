#!/usr/bin/python

import sys
import os
import subprocess
import math
import yaml
import cv2
import random
from tqdm import tqdm
import operator
from pdf2image import convert_from_path

# COMMANDS
ONLYENCO = False
ONLYCONT = False
SHOWGRAPHS = False # Show separate graphs
DOFRAMES = True
SHOWFRAMES = True # Show canvas
DOVIDEO = False

PRINTPDFLATEXOUT = False

# Meta parameters
SEED = 0
MAX_FRAME = 1 # None implies finding max_frame
DIR_PATH = os.path.dirname(os.path.realpath(__file__))
HOME_DIR = os.path.expanduser("~")
ICGPRES_DIR = HOME_DIR + "/Documents/git/ICGP-results"
IMG_EXT = ".png"
TOPNG = True # convert pdf canvas to png
DELETE_GRAPHS = True
DELETE_CANVAS_PDF = True
FPSS = [15, 60]

# Graph layout
GRAPHBACK = True
BUFFERCLIP = True
PRINTBUFFER = True
COLOR_ACTIVE = "red"
COLOR_INACTIVE = "black"
COLOR_INACTIVE_EDGE = "black!50"
COLOR_BACKGROUND = "white"
HALOEDGELABELS = False
BACKGROUNDEDGELABELS = True
ENABLE_MANUAL_POS = True


"""
Exp 1:
Simple:
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-01T17:44:01.968_boxing
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-03T18:18:35.090_freeway

Simple + acceleration:
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-23T18:31:09.813_asteroids

Complex with an interesting double dilatation:
/home/opaweynch/Documents/git/ICGP-results/results/2021-10-01T18:23:26.293_space_invaders

Complex:
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-23T18:31:09.829_breakout
/home/opaweynch/Documents/git/ICGP-results/results/2021-10-01T18:22:33.340_riverraid
/home/opaweynch/Documents/git/ICGP-results/results/2021-09-07T17:17:40.579_gravitar
"""

"""
Instructions on positioning:

Position by nodename prevails on position "by type", which prevails on random positioning (default).
	nodename > type > random

Position "by type" apply to either all inputs or all outputs. Here are examples:
	{"type": "singlenode", "pos": (0, 0)}
	{"type": "column", "pos": (10, 0), "span": 1}
	{"type": "squares", "pos": (0, 0)} # Only valid for controller input
"""
POS = {
	"2021-09-03T18:18:35.090_freeway" : {
		"encoder": {
			"1": (0,0),
			"2": (2,0),
			"8": (4,1), "11": (6,1), "out11": (8,1),
			"17": (4,-1), "out17": (8,-1),
			"backgroundnode": {"pos": (-1, 0), "width": (1.7, 6, 1.5), "height": 4},
			"customedges": {(2, 11): "bend right=20"},
			"labelsinclination": 45
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"68": (5,-0.5), "79": (7,-0.5),
			"sticky": (10, 2),
			"backgroundnode": {"pos": (-2.7, 0), "width": (5.2, 5.8, 2.1), "height": 13},
			"labelsinclination": 45
		},
		"canvas": {
			"rgbpos": (0.03, 0.5), "hrgbpos": (0.1, 1.12), "scorepos": (0.1, 0.52),
			"epos": (0, -0.15), "hepos": (0.1, 0.41),
			"cpos": (1.1, -0.05), "hcpos": (1.2, 1.13)
		}
	},
	"2021-10-01T18:23:26.293_space_invaders": {
		"encoder": {
			"1": (0,0),
			"3": (4, -1), "out3": (12, -1),
			"5": (2, 1), "6": (4, 1), "12": (6, 1), "17": (8, 1), "20": (10, 1),
			"out20": (12, 1),
			"backgroundnode": {"pos": (-1, 0.4), "width": (1.7, 9.8, 1.5), "height": 4},
			"customedges": {(1, 5): {1: "bend left=90", 2: "bend left=50"}},
			"labelsinclination": 45
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (0, 0), "innerspan": 1, "squarespan": 7},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"63": (4, -3), "70": (6, -3), "85": (8, -3),
			"76": (4, 2), "83": (6, 2), "73": (6, 0), "89": (8, 1),
			"80": (6, 3),
			"customedges": {(10, 85): "bend right=20", (85, "out85"): "bend left=30", (28, "out28"): "bend left=4"},
			"customlabel": {(33, 73): "pos=0.9", (19, 73): "pos=0.9", (27, 83): "pos=0.9", (42, 63): "pos=0.9", (2, 63): "pos=0.9", (63, 70): "pos=0.5", (70, 85): "pos=0.5"},
			"sticky": (10, 3.7),
			"backgroundnode": {"pos": (-2.7, 0), "width": (5.2, 5.8, 2.1), "height": 13}
		},
		"canvas": {
			"rgbpos": (0.03, 0.5), "hrgbpos": (0.1, 1.12), "scorepos": (0.1, 0.52),
			"epos": (0, -0.05), "hepos": (0.1, 0.41),
			"cpos": (1.1, -0.05), "hcpos": (1.2, 1.13)
		}
	},
	"2021-09-01T17:44:01.968_boxing": {
		"encoder": {
			"1": (-1, 2), "2": (3, 3), "4": (3, 1), "6": (7, 2), "out6": (10, 2),
			"3": (1, -1), "9": (3, -1), "11": (5.5, -1), "14": (8.5, -1), "out14": (10, -1)
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (-1, 0), "innerspan": 1, "squarespan": 7},# {"type": "singlenode", "pos": (0, 0)},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"53": (1, 3),
			"74": (5, -6), "81": (7, -6),
			"67": (5, -4.5),
			"78": (5, -2.5), "59": (5, -0.5), "79": (7, -1.5),
			"85": (8, -3.5),
			"53": (8, 4),
			"77": (5, 6),
			"52": (0, 10),
			"69": (5, 0.5), "82": (7, 1.5),
			"sticky": (10, 10)
		},
		"canvas": {
			"rgbpos": (0, 0.4), "hrgbpos": (0, 0.8), "scorepos": (-0.6, 0.1),
			"epos": (0, -0.4), "hepos": (0, 0),
			"cpos": (1.1, 0), "hcpos": (1.1, 0.8)
		}
	},
	"2021-09-03T18:18:34.627_solaris": {
		"encoder": {
			"1": (0, 0),
			"9": (2, 2.62), "12": (5, 2.62), "18": (8, 2.62), "out18": (12, 2.62),
			"4": (4, 0), "8": (7, 0), "20": (10, 0), "out20": (12, 0),
			"2": (2, -2.62), "3": (5, -2.62), "7": (8, -2.62),
			"backgroundnode": {"pos": (-1.1, 0.4), "width": (1.8, 9.9, 1.5), "height": 7.8}
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (-1, 0), "innerspan": 1, "squarespan": 7},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"sticky": (10, 9.6),
			"54": (5, 8),
			"56": (5, 6), "66": (7, 6),
			"63": (7, -0.5), "81": (7, 2.5),
			"59": (2.8, 2.4), "80": (6.7, 4.7),
			"87": (7, -5),
			"77": (7, -6),
			"backgroundnode": {"pos": (-3.7, 1), "width": (5.2, 6.8, 2.1), "height": 19}
		},
		"canvas": {
			"rgbpos": (0.03, 0.5), "hrgbpos": (0.1, 1.12), "scorepos": (0.1, 0.52),
			"epos": (0, -0.3), "hepos": (0.1, 0.41),
			"cpos": (1.1, -0.3), "hcpos": (1.2, 1.13)
		}
	}
}

EDGELABELS = {
	"f_binary": "Binary",
	"f_bitwise_not": "Not",
	"f_bitwise_and": "And",
	"f_bitwise_xor": "Xor",
	"f_subtract": "Subtract",
	"f_threshold": "Threshold",
	"f_dilate": "Dilate"
}

ACTIONLABELS = {
	0: "$\\quad$",
	1: "$\\bullet$",
	2: "$\\uparrow$",
	3: "$\\rightarrow$",
	4: "$\\leftarrow$",
	5: "$\\downarrow$",
	6: "$\\nearrow$",
	7: "$\\nwarrow$",
	8: "$\\searrow$",
	9: "$\\swarrow$",
	10: "$\\bullet \\uparrow$",
	11: "$\\bullet \\rightarrow$",
	12: "$\\bullet \\leftarrow$",
	13: "$\\bullet \\downarrow$",
	14: "$\\bullet \\nearrow$",
	15: "$\\bullet \\nwarrow$",
	16: "$\\bullet \\searrow$",
	17: "$\\bullet \\swarrow$"
}

	
def printinddict(g, verbose=True):
	spacing = "  "
	if verbose:
		for k, v in g.items():
			print(spacing, k, ":", v)
	else:
		for k in ["inputs", "nodes", "outputs"]:
			print(spacing, k, ":", g[k])

def printdict(d):
	for k, v in d.items():
		print(k, ":", v)

def printgdict(gdict):
	print("\nLoaded gdict:")
	print("\nencoder:")
	#print(gdict["encoder"])
	printinddict(gdict["encoder"])
	print("\nreducer:")
	print(gdict["reducer"])
	print("\ncontroller:")
	#print(gdict["controller"])
	printinddict(gdict["controller"])
	print("\nmeta:")
	print(gdict["metadata"])
	print()

def str_to_tuple(s):
	if s[0] == "(":
		s = s[1:-1]
	if s[-1] == ")":
		s = s[0:-2]
	return tuple(map(int, s.split(', ')))

def open_yaml(path):
	with open(path, 'r') as stream:
		try:
			return yaml.safe_load(stream)
		except yaml.YAMLError as exc:
			print(exc)

def rgbfname(frame):
	return str(frame) + "_rgb.png"

def graphfname(frame, indtype):
	return str(frame) + "_graph_" + indtype

def canvasfname(frame):
	return str(frame) + "_canvas"
	
def writeat(path, lines):
	with open(path, 'w') as f:
		for l in lines:
			f.write(l)
			f.write('\n')
		f.close()

def retrieve_buffer(indtype, path, frame):
	if indtype == "encoder":
		return retrieve_img_buffer(path, frame, "e")
	elif indtype == "reducer":
		return retrieve_img_buffer(path, frame, "f")
	elif indtype == "controller":
		return retrieve_cont_buffer(path, frame)
	else:
		raise NameError(indtype)

def retrieve_img_buffer(path, frame, key):
	b = {}
	fprefix = str(frame) + "_" + key
	for f in os.listdir(path):
		if f.startswith(fprefix):
			node = int(f[len(fprefix):-len(IMG_EXT)])
			b[node] = path + f # PIL.Image.open(path + f)
	return b

def retrieve_cont_buffer(path, frame):
	fname = path + str(frame) + "_c.yaml"
	b = open_yaml(fname)
	return b

def retrieve_metadata(path, frame):
	fname = path + str(frame) + "_m.yaml"
	return open_yaml(fname)
	
def get_max_frame(exp_dir):
	if MAX_FRAME is None:
		bdir = get_paths(exp_dir)["metadata"]
		return max([int(f.split("_")[0]) for f in os.listdir(bdir)])
	else:
		return MAX_FRAME

def get_paths(exp_dir):
	paths = {}
	paths["exp"] = exp_dir.split("/")[-1]
	g_dir = exp_dir + "/graphs"
	for f in os.listdir(g_dir):
		indtype = f[0:len(f)-len(".yaml")]
		paths[indtype] = {}
		paths[indtype]["graph"] = g_dir + "/" + f
		paths[indtype]["buffer"] = exp_dir + "/buffers/"
	paths["reducer"] = {}
	paths["reducer"]["buffer"] = exp_dir + "/buffers/"
	paths["metadata"] = exp_dir + "/buffers/"
	return paths

def gdict_from_paths(paths, frame):
	gdict = {}
	for indtype in ["encoder", "controller"]:
		v = paths[indtype]
		g = open_yaml(v["graph"])
		g["inputs"] = list(range(1,1+g["n_in"]))
		g["edges"] = [str_to_tuple(e) for e in g["edges"]]
		g["buffer"] = retrieve_buffer(indtype, v["buffer"], frame)
		gdict[indtype] = g
	gdict["reducer"] = {}
	gdict["reducer"]["buffer"] = retrieve_buffer("reducer", paths["reducer"]["buffer"], frame)
	gdict["metadata"] = retrieve_metadata(paths["metadata"], frame)
	return gdict
	
def getnodename(node, g=None, isout=False):
	if isout:
		node_index_in_cgp = g["outputs"][node] # here, node is the index in g["output"]
		n_prev_occurences = g["outputs"][0:node].count(node_index_in_cgp)
		return "out" + str(node_index_in_cgp) + n_prev_occurences*"'"
	else: # input or inner node
		return str(node)
	
def randompos():
	mag = 10
	return (mag*random.random(), mag*random.random())
	
def postostr(pos):
	for k, v in pos.items():
		pos[k] = str(v[0])+","+str(v[1])
	return pos
	
def twopletostr(t):
	return "(" + str(t[0]) + ", " + str(t[1]) + ")"

def getcanvaspos(expdir):
	scorepos, rgbpos, epos, cpos = "(0, -1)", "(0, 0)", "(1, 0)", "(2, 0)"
	hrgbpos, hepos, hcpos = "(0, 1)", "(1, 1)", "(2, 1)"
	if expdir in list(POS.keys()) and "canvas" in list(POS[expdir].keys()):
		if "scorepos" in list(POS[expdir]["canvas"].keys()):
			scorepos = twopletostr(POS[expdir]["canvas"]["scorepos"])
		if "rgbpos" in list(POS[expdir]["canvas"].keys()):
			rgbpos = twopletostr(POS[expdir]["canvas"]["rgbpos"])
		if "hrgbpos" in list(POS[expdir]["canvas"].keys()):
			hrgbpos = twopletostr(POS[expdir]["canvas"]["hrgbpos"])
		if "epos" in list(POS[expdir]["canvas"].keys()):
			epos = twopletostr(POS[expdir]["canvas"]["epos"])
		if "hepos" in list(POS[expdir]["canvas"].keys()):
			hepos = twopletostr(POS[expdir]["canvas"]["hepos"])
		if "cpos" in list(POS[expdir]["canvas"].keys()):
			cpos = twopletostr(POS[expdir]["canvas"]["cpos"])
		if "hcpos" in list(POS[expdir]["canvas"].keys()):
			hcpos = twopletostr(POS[expdir]["canvas"]["hcpos"])
	return scorepos, rgbpos, hrgbpos, epos, hepos, cpos, hcpos
	
def columnpos(posdict, n_nodes, index):
	orig = posdict["pos"]
	span = posdict["span"]
	return (orig[0], orig[1] - index*span + 0.5*n_nodes*span)
	
def squarepos(gdict, posdict, n_nodes, index):
	n_squares = gdict["encoder"]["n_out"]
	nodes_per_square = gdict["controller"]["n_in"] / n_squares
	size = math.sqrt(nodes_per_square)
	assert float(size).is_integer(), "impossible square size: " + str(size)
	in_square_index = (index-1) % nodes_per_square
	current_square = math.ceil(index / nodes_per_square)
	row = math.floor(in_square_index / size)
	col = int(in_square_index % size)
	innerspan = posdict["innerspan"]
	pos = ((col-(size-1)/2)*innerspan, (-row+(size-1)/2)*innerspan)
	pos = tuple(map(operator.add, pos, posdict["origin"])) # shift to origin
	sqshift = (0, ((n_squares+1)/2-current_square)*posdict["squarespan"])
	pos = tuple(map(operator.add, pos, sqshift)) # shift squares
	return pos

def getpos(gdict, expdir, indtype):
	pos = {}
	g = gdict[indtype]
	n_inp = g["n_in"]
	
	# Position of input nodes
	for i in range(1, n_inp+1):
		node = i
		nodename = getnodename(node)
		pos[nodename] = randompos() # Default to random position
		if ENABLE_MANUAL_POS:
			if expdir in list(POS.keys()) and indtype in list(POS[expdir].keys()):
				if nodename in list(POS[expdir][indtype].keys()):
					pos[nodename] = POS[expdir][indtype][nodename]
				elif "inputs" in list(POS[expdir][indtype].keys()):
					input_pos_dict = POS[expdir][indtype]["inputs"]
					if input_pos_dict["type"] == "singlenode":
						pos[nodename] = input_pos_dict["pos"]
					elif input_pos_dict["type"] == "column":
						pos[nodename] = columnpos(input_pos_dict, n_inp, i)
					elif input_pos_dict["type"] == "squares":
						pos[nodename] = squarepos(gdict, input_pos_dict, n_inp, i)
					else:
						print("WARNING: input position type", input_pos_dict["type"], "unknown.")
	
	# Position of inner nodes
	for node in list(g["buffer"].keys()):
		isinp = node <= n_inp
		if not isinp:
			nodename = getnodename(node)
			pos[nodename] = randompos() # Default to random position
			if ENABLE_MANUAL_POS:
				if expdir in list(POS.keys()) and indtype in list(POS[expdir].keys()):
					if nodename in list(POS[expdir][indtype].keys()):
						pos[nodename] = POS[expdir][indtype][nodename]

	# Position of output nodes
	n_out = len(g["outputs"])
	for i in range(n_out): 
		# node = g["outputs"][i]
		nodename = getnodename(i, g, True)
		pos[nodename] = randompos() # Default to random position
		if ENABLE_MANUAL_POS:
			if expdir in list(POS.keys()) and indtype in list(POS[expdir].keys()):
				if nodename in list(POS[expdir][indtype].keys()):
					pos[nodename] = POS[expdir][indtype][nodename]
				elif "outputs" in list(POS[expdir][indtype].keys()):
					output_pos_dict = POS[expdir][indtype]["outputs"]
					if output_pos_dict["type"] == "singlenode":
						pos[nodename] = output_pos_dict["pos"]
					elif output_pos_dict["type"] == "column":
						pos[nodename] = columnpos(output_pos_dict, n_out, i)
					else:
						print("WARNING: output position type", output_pos_dict["type"], "unknown.")
						
	# Position of sticky node
	nodename = "sticky"
	pos[nodename] = randompos() # Default to random position
	if (
		ENABLE_MANUAL_POS
		and expdir in list(POS.keys())
		and indtype in list(POS[expdir].keys())
		and nodename in list(POS[expdir][indtype].keys())
	):
		pos[nodename] = POS[expdir][indtype][nodename]

	pos = postostr(pos)
	return pos
	
def getnodecontent(gdict, node, nodename, indtype, is_out, index=None, width=1.5):
	if not PRINTBUFFER:
		return nodename
	elif indtype == "encoder":
		wstr = str(width) + "cm"
		if is_out:
			return "\includegraphics[width="+wstr+"]{"+gdict["reducer"]["buffer"][node]+"}"
		else:
			hstr = str(0.76 * width) + "cm"
			return "\includegraphics[width="+wstr+", height="+hstr+"]{"+gdict[indtype]["buffer"][node]+"}"
	elif indtype == "controller":
		if is_out:
			action_name_in_ale = gdict["controller"]["actions"][index]
			act = ACTIONLABELS[action_name_in_ale]
			val = "$" + str(round(gdict[indtype]["buffer"][node], 2)) + "$"
			return act + "\\quad" + val
		else:
			return "$" + str(round(gdict[indtype]["buffer"][node], 2)) + "$"
			
def getnodesettings(gdict, expdir, node, nodename, activated, indtype, isout, iscontout_selected):
	iscontroller = indtype == "controller"
	if (
		iscontroller
		and ENABLE_MANUAL_POS
		and node <= gdict[indtype]["n_in"]
		and nodename[:3] != "out"
		and expdir in list(POS.keys()) 
		and indtype in list(POS[expdir].keys())
		and "inputs" in list(POS[expdir][indtype].keys())
		and POS[expdir][indtype]["inputs"]["type"] == "squares"
	): # reduced images as background
		nodesettings = "draw=none, color=black, fill=white, opacity=0.7, rounded corners=0.1cm, minimum width=0.9cm"
	else:
		issticky = gdict["metadata"]["is_sticky"]
		isactive = (node in activated) and (not issticky or (isout and iscontroller))
		if isactive and isout and iscontroller:
			isactive = not iscontout_selected
			iscontout_selected = True
		nodecolor = COLOR_ACTIVE if isactive else COLOR_INACTIVE
		w = "2cm" if (indtype == "controller" and isout) else "1cm"
		sep = "inner sep=0,outer sep=0," if indtype == "encoder" else ""
		nodesettings = "shape=rectangle, rounded corners=0.1cm, minimum width="+w+", minimum height=0.6cm, fill=white,"+sep+"draw, color="+nodecolor+",fill="+COLOR_BACKGROUND
	return nodesettings, iscontout_selected

def getedgelabel(fname):
	if fname in list(EDGELABELS.keys()):
		return EDGELABELS[fname]
	else:
		return fname[2:].replace('_', ' ')

def appendbackgroundnodes(ts, gdict, expdir, indtype):
	if (ENABLE_MANUAL_POS
		and expdir in list(POS.keys()) 
		and indtype in list(POS[expdir].keys())
	):
		if (GRAPHBACK
			and "backgroundnode" in list(POS[expdir][indtype].keys())
		): # I/O background node
			d = POS[expdir][indtype]["backgroundnode"]
			pos = d["pos"]
			w, h = d["width"], d["height"]
			nodesettings = "anchor=west, text centered, rectangle split, rectangle split horizontal, rectangle split parts=3, draw, rectangle split draw splits=false, color=black, fill=white, rounded corners=0.1cm, minimum height="+str(h)+"cm"
			splitsettings = "dashed"
			pos = str(pos[0]) + "," + str(pos[1])
			ts.append("\\node["+nodesettings+"] (A) at ("+pos+") {\\nodepart[text width="+str(w[0])+"cm]{one}\\begin{minipage}[t]["+str(h)+"cm]{"+str(w[0])+"cm}\centering \\textbf{Input}\\end{minipage} \\nodepart[text width="+str(w[1])+"cm]{two} \\nodepart[text width="+str(w[2])+"cm]{three} \\begin{minipage}[t]["+str(h)+"cm]{"+str(w[2])+"cm}\centering \\textbf{Output}\\end{minipage}};")
			ts.append("\\draw["+splitsettings+"] (A.one split south) -- (A.one split north);")
			ts.append("\\draw["+splitsettings+"] (A.two split south) -- (A.two split north);")
		if (indtype == "controller"
			and "inputs" in list(POS[expdir][indtype].keys())
			and POS[expdir][indtype]["inputs"]["type"] == "squares"
		): # reduced images as background
			posdict = POS[expdir][indtype]["inputs"]
			n_squares = gdict["encoder"]["n_out"]
			nodes_per_square = gdict[indtype]["n_in"] / n_squares
			size = math.sqrt(nodes_per_square)
			assert float(size).is_integer(), "impossible square size: " + str(size)
			width = posdict["innerspan"]*size
			for i in range(n_squares):
				node = gdict["encoder"]["outputs"][i]
				nodename = getnodename(i, gdict["encoder"], True)
				isout = True
				nodecontent = getnodecontent(gdict, node, nodename, "encoder", isout, i, width=width)
				pos = posdict["origin"]
				current_square = i + 1
				sqshift = (0, ((n_squares+1)/2-current_square)*posdict["squarespan"])
				pos = tuple(map(operator.add, pos, sqshift)) # shift squares
				pos = str(pos[0]) + "," + str(pos[1])
				ts.append("\\node[] () at ("+pos+") {"+nodecontent+"};")

def getnode(indtype, nodesettings, nodename, p, nodecontent):
	if BUFFERCLIP and indtype == "encoder" and PRINTBUFFER:
		#color = nodesettings.split("draw=")[1]
		return "\\savebox{\\picbox}{"+nodecontent+"} \\node ["+nodesettings+", minimum width=\\wd\\picbox, minimum height=\\ht\\picbox, path picture={\\node at (path picture bounding box.center) {\\usebox{\\picbox}};}] ("+nodename+") at ("+p+") {};"	
	else:
		return "\\node["+nodesettings+"] ("+nodename+") at ("+p+") {"+nodecontent+"};"
	
def appendnodes(ts, gdict, expdir, indtype):
	g = gdict[indtype]
	activated = gdict["metadata"][indtype]["activated"]
	outputs = gdict["metadata"][indtype]["outputs"]
	pos = getpos(gdict, expdir, indtype)
	appendbackgroundnodes(ts, gdict, expdir, indtype)
	if BUFFERCLIP: ts.append("\\newsavebox{\\picbox}")
	iscontout_selected = False
	for node in g["buffer"].keys():
		nodename = getnodename(node)
		isinput = node <= g["n_in"]
		p = pos[nodename]
		isout = False
		nodecontent = getnodecontent(gdict, node, nodename, indtype, isout)
		nodesettings, iscontout_selected = getnodesettings(gdict, expdir, node, nodename, activated, indtype, isout, iscontout_selected)
		nd = getnode(indtype, nodesettings, nodename, p, nodecontent)
		ts.append(nd)
	for i in range(len(g["outputs"])):
		node = g["outputs"][i]
		nodename = getnodename(i, g, True)
		p = pos[nodename]
		isout = True
		nodecontent = getnodecontent(gdict, node, nodename, indtype, isout, i, width=1)
		nodesettings, iscontout_selected = getnodesettings(gdict, expdir, node, nodename, outputs, indtype, isout, iscontout_selected)
		nd = getnode(indtype, nodesettings, nodename, p, nodecontent)
		ts.append(nd)
	if indtype == "controller":
		is_sticky = gdict["metadata"]["is_sticky"]
		color = COLOR_ACTIVE if is_sticky else COLOR_BACKGROUND
		if not PRINTBUFFER: color = "teal"
		nodename = "sticky"
		p = pos[nodename]
		ts.append("\\node[color="+color+"] ("+nodename+") at ("+p+") {\\textbf{Repeated}};")

def getcustomlabelopt(expdir, indtype, edge, seenedges):
	out = ""
	if expdir in POS.keys() and indtype in POS[expdir].keys() and "customlabel" in POS[expdir][indtype].keys() and edge in POS[expdir][indtype]["customlabel"]:
		out += ", "
		setting = POS[expdir][indtype]["customlabel"][edge]
		if isinstance(setting, str):
			out += setting
		elif isinstance(setting, dict):
			out += setting[2] if edge in seenedges else setting[1]
		else:
			out += ""
	return out

def getcustompathset(expdir, indtype, edge, seenedges):
	out = ""
	if expdir in POS.keys() and indtype in POS[expdir].keys() and "customedges" in POS[expdir][indtype].keys() and edge in POS[expdir][indtype]["customedges"]:
		out += ", "
		setting = POS[expdir][indtype]["customedges"][edge]
		if isinstance(setting, str):
			out += setting
		elif isinstance(setting, dict):
			out += setting[2] if edge in seenedges else setting[1]
		else:
			out += ""
	return out

def appendedges(ts, gdict, expdir, indtype):
	g = gdict[indtype]
	activated = gdict["metadata"][indtype]["activated"]
	outputs = gdict["metadata"][indtype]["outputs"]
	seenedges = []
	for edge in g["edges"]:
		src, dst = str(edge[0]), str(edge[1])
		dstindex = g["nodes"].index(edge[1])
		edgelabel = getedgelabel(g["fs"][dstindex])
		edgeopt = "loop left" if edge[0] == edge[1] else "" # self-loop
		if expdir in POS.keys() and indtype in POS[expdir].keys() and "labelsinclination" in POS[expdir][indtype].keys():
			labelopt = "rotate=" + str(POS[expdir][indtype]["labelsinclination"])
		else:
			labelopt = "above"
		labelopt += ", fill=white, rounded corners=0.1cm, fill opacity=0.8, text opacity=1" if BACKGROUNDEDGELABELS else ""
		labelopt += ",pos=0.75" if indtype == "controller" else ""
		labelopt += getcustomlabelopt(expdir, indtype, edge, seenedges)
		isactive = (edge[1] in activated) and (not gdict["metadata"]["is_sticky"])
		edgecolor = COLOR_ACTIVE if isactive else COLOR_INACTIVE_EDGE
		pathset = "->, color="+edgecolor
		custompathset = getcustompathset(expdir, indtype, edge, seenedges)
		pathset += custompathset
		if HALOEDGELABELS:
			ts.append("\\path[->, color=white, ultra thick"+custompathset+"] ("+src+") edge["+edgeopt+"] node[above] {"+edgelabel+"} ("+dst+");")
		ts.append("\\path["+pathset+"] ("+src+") edge["+edgeopt+"] node["+labelopt+"] {"+edgelabel+"} ("+dst+");")
		seenedges.append(edge)
	iscontoutedge_selected = False
	for i in range(len(g["outputs"])):
		output = g["outputs"][i]
		src = str(output)
		dst = getnodename(i, g, True)
		edge = (output, dst)
		isactive = (output in outputs) and (not gdict["metadata"]["is_sticky"])
		if isactive and not iscontoutedge_selected:
			edgecolor = COLOR_ACTIVE
			if indtype == "controller": iscontoutedge_selected = True
		else:
			edgecolor = COLOR_INACTIVE_EDGE
		pathset = "->, color="+edgecolor
		custompathset = getcustompathset(expdir, indtype, edge, seenedges)
		pathset += custompathset
		if HALOEDGELABELS:
			ts.append("\\path[->, color=white, ultra thick"+custompathset+"] ("+src+") edge node {} ("+dst+");")
		ts.append("\\path["+pathset+"] ("+src+") edge node {} ("+dst+");")

def graph_texscript(gdict, paths, indtype, printtex=False):
	expdir = paths["exp"]
	ts = [] # texscript
	ts.append("\\documentclass[crop,tikz]{standalone}")
	ts.append("\\usepackage{graphicx}")
	ts.append("\\usetikzlibrary{shapes,automata}")
	ts.append("\\begin{document}")
	ts.append("\\begin{tikzpicture}")
	appendnodes(ts, gdict, expdir, indtype)
	appendedges(ts, gdict, expdir, indtype)
	ts.append("\\end{tikzpicture}")
	ts.append("\\end{document}")
	
	if printtex:
		print("\nPrinting graph TeX file for", indtype, ":")
		print(100*"-")
		for l in ts:
			print(l)
		print(100*"-")
	return ts

def canvas_texscript(paths, frame, score, printtex=False):
	savedir = paths["metadata"]
	expdir = paths["exp"]
	rgb_path = savedir + rgbfname(frame)
	e_gpath = savedir + graphfname(frame, "encoder") + ".pdf"
	c_gpath = savedir + graphfname(frame, "controller") + ".pdf"
	rgb_content = "\includegraphics[width=1cm]{"+rgb_path+"}"
	e_content = "\includegraphics[width=1cm]{"+e_gpath+"}"
	c_content = "\includegraphics[width=1cm]{"+c_gpath+"}"
	scorepos, rgbpos, hrgbpos, epos, hepos, cpos, hcpos = getcanvaspos(expdir)
	anch = "anchor=south west, "
	ts = []
	ts.append("\\documentclass[crop,tikz]{standalone}")
	ts.append("\\usepackage{graphicx}")
	ts.append("\\begin{document}")
	ts.append("\\begin{tikzpicture}")
	ts.append("\\node["+anch+"scale=0.2] () at "+hrgbpos+" {1. RGB Image};")
	ts.append("\\node["+anch+"scale=0.8] () at "+rgbpos+" {"+rgb_content+"};")
	ts.append("\\node["+anch+"scale=0.15] () at "+scorepos+" {Score: "+str(score)+"};")
	ts.append("\\node["+anch+"scale=0.2] () at "+hepos+" {2. CGP Encoder};")
	ts.append("\\node["+anch+"] () at "+epos+" {"+e_content+"};")
	ts.append("\\node["+anch+"scale=0.2] () at "+hcpos+" {3. CGP Controller};")
	ts.append("\\node["+anch+"] () at "+cpos+" {"+c_content+"};")
	ts.append("\\end{tikzpicture}")
	ts.append("\\end{document}")
	if printtex:
		print("\nPrinting canvas TeX file :")
		print(100*"-")
		for l in ts:
			print(l)
		print(100*"-")
	return ts
	
def runtex(fname, savedir, texsavepath, iscanvas=False):
	f = sys.stdout if PRINTPDFLATEXOUT else open('/dev/null', 'w')
	subprocess.run(
		["pdflatex", "-interaction", "nonstopmode",
		"-output-directory", savedir, texsavepath],
		stdout=f, stderr=f, capture_output=False
	)
	# clean
	for ext in [".tex", ".aux", ".log"]:
		os.remove(savedir + fname + ext)
	# evince
	if (iscanvas and SHOWFRAMES) or ((not iscanvas) and SHOWGRAPHS):
		subprocess.run(["evince", savedir + fname + ".pdf"])
	
def canvastopng(fname, savedir):
	pdffile = savedir + fname + ".pdf"
	pngfile = savedir + fname + ".png"
	pages = convert_from_path(pdffile, dpi=2000)
	pages[0].save(pngfile, 'PNG')
	if DELETE_CANVAS_PDF:
		os.remove(pdffile)
	
def build_graph(texscript, paths, frame, indtype):
	savedir = paths["metadata"]
	fname = graphfname(frame, indtype)
	texsavepath = savedir + fname + ".tex"
	writeat(texsavepath, texscript)
	runtex(fname, savedir, texsavepath)
	
def build_canvas(texscript, paths, frame):
	savedir = paths["metadata"]
	fname = canvasfname(frame)
	texsavepath = savedir + fname + ".tex"
	writeat(texsavepath, texscript)
	runtex(fname, savedir, texsavepath, iscanvas=True)
	if TOPNG:
		canvastopng(fname, savedir)

def make_graphs(paths, frame, gdict):
	if ONLYENCO:
		indtypes = ["encoder"]
	elif ONLYCONT:
		indtypes = ["controller"]
	else:
		indtypes = ["controller", "encoder"]
	for indtype in indtypes:
		texscript = graph_texscript(gdict, paths, indtype)
		build_graph(texscript, paths, frame, indtype)
		if ONLYENCO or ONLYCONT: exit()
		
def delete_graphs(paths, frame):
	savedir = paths["metadata"]
	for indtype in ["encoder", "controller"]:
		fname = graphfname(frame, indtype)
		os.remove(savedir + fname + ".pdf")

def make_canvas(paths, frame, score):
	texscript = canvas_texscript(paths, frame, score)
	build_canvas(texscript, paths, frame)
	if DELETE_GRAPHS: delete_graphs(paths, frame)
		
def make_video(paths, max_frame, fps, verbose=True):
	bufferdir = paths["metadata"]
	savedir = bufferdir[0:-len("buffers/")]
	fspan = 1000
	n_vid = math.ceil(max_frame / fspan)
	subvideofnames = [savedir + "canvas" + str(i+1) + ".avi" for i in range(n_vid)]
	img = cv2.imread(bufferdir + str(1) + "_canvas.png")
	height, width, layers = img.shape
	size = (width, height)
	ranges = [range(i, i+fspan) for i in range(1, max_frame + 1 - fspan, fspan)]
	ranges.append(range(len(ranges) * fspan + 1, max_frame + 1))
	subvid_index = 0
	if verbose: print("\nCreating video"+"\nfps: "+str(fps))	
	# Creating sub-videos
	for r in ranges:
		if verbose: print("Loading images from", r[0], "to", r[-1], "out of", max_frame, ":")
		img_array = []
		for frame in tqdm(r):
			fname = bufferdir + str(frame) + "_canvas.png"
			img = cv2.imread(fname)
			img_array.append(img)
		if verbose: print("Successfully loaded", len(r), "images")
		videofname = subvideofnames[subvid_index]
		out = cv2.VideoWriter(videofname, cv2.VideoWriter_fourcc(*'DIVX'), fps, size)
		for i in range(len(img_array)):
			out.write(img_array[i])
		out.release()
		if verbose: print("Successfully created sub-video number", subvid_index+1, "at", videofname)
		subvid_index += 1
		
	# Assembling sub-videos
	viddir = os.path.dirname(os.path.dirname(os.path.dirname(savedir)))
	vidname = os.path.basename(os.path.dirname(savedir)) + "_" + str(fps) + "fps.avi"
	finalvideofname = viddir + "/" + vidname	
	video = cv2.VideoWriter(finalvideofname, cv2.VideoWriter_fourcc(*'DIVX'), fps, size)
	if verbose: print("\nAssembling sub-videos:")
	for f in tqdm(subvideofnames):
		v = cv2.VideoCapture(f)
		while v.isOpened():
			r, frame = v.read()
			if not r:
				break
			video.write(frame)
	video.release()
	if verbose: print("Successfully assembled video at", finalvideofname)
	
	# Removing sub-videos
	if verbose: print("\nRemoving sub-videos:")
	for f in tqdm(subvideofnames):
		os.remove(f)
	if verbose: print("Successfully created video!")
	
def make_frames(paths, max_frame, verbose=True):
	if verbose:
		spth = paths["metadata"]
		print("Creating frames")
		print("Number of frames :", str(max_frame))
		print("Experiment id    :", paths["exp"])
		print("Experiment path  :", os.path.dirname(os.path.dirname(spth)))
		print("Saving frames at :", spth)
	for frame in tqdm(range(1, max_frame + 1)):
		gdict = gdict_from_paths(paths, frame)
		score = gdict["metadata"]["score"]
		make_graphs(paths, frame, gdict)
		make_canvas(paths, frame, score)
	if verbose: print("Successfully created frames!")

def get_exp_dir(rom):
	exp_dir = ICGPRES_DIR + "/results/"
	if rom == "boxing":
		return exp_dir + "2021-09-01T17:44:01.968_boxing"
	elif rom == "freeway":
		return exp_dir + "2021-09-03T18:18:35.090_freeway"
	elif rom == "asteroids":
		return exp_dir + "2021-09-23T18:31:09.813_asteroids"
	elif rom == "space_invaders":
		return exp_dir + "2021-10-01T18:23:26.293_space_invaders"
	elif rom == "breakout":
		return exp_dir + "2021-09-23T18:31:09.829_breakout"
	elif rom == "riverraid":
		return exp_dir + "2021-10-01T18:22:33.340_riverraid"
	elif rom == "gravitar":
		return exp_dir + "2021-09-07T17:17:40.579_gravitar"
	else:
		raise NameError(rom)
	
"""
Main make method calling frame-maker and video-maker sequentially.
"""
def make(rom):
	exp_dir = get_exp_dir(rom)
	paths = get_paths(exp_dir)
	max_frame = get_max_frame(exp_dir)
	random.seed(SEED)
	if DOFRAMES: make_frames(paths, max_frame)
	if DOVIDEO:
		for fps in FPSS:
			make_video(paths, max_frame, fps)

if __name__ == "__main__":
	rom = sys.argv[1]
	make(rom)

# python3.8 pytexgraph.py /home/opaweynch/Documents/git/ICGP-results/results/2021-09-01T17:44:01.968_boxing

# python3.8 pytexgraph.py /home/opaweynch/Documents/git/ICGP-results/results/2021-10-01T18:23:26.293_space_invaders

