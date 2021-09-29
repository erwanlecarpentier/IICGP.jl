#!/usr/bin/python

import sys
import os
import subprocess
import math
import yaml
import PIL
import random
import operator
import matplotlib.animation as animation
from matplotlib.widgets import Slider


# Meta parameters
SEED = 1234
DIR_PATH = os.path.dirname(os.path.realpath(__file__))
IMG_EXT = ".png"
IMG_TYPE = PIL.PngImagePlugin.PngImageFile

# Graph layout
NOBUFFER = False # Set to True to display nodes names instead of buffers
ACTIVE_COLOR = "red"
NDSETTING = "shape=rectangle, rounded corners=0.1cm, minimum width=1cm, minimum height=0.6cm, fill=black!10"
HALOEDGES = True
ENABLE_MANUAL_POS = True

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
	"2021-09-01T17:44:01.968_boxing": {
		"encoder": {
			"3": (1, 2), "9": (3, 2), "11": (5.5, 2), "14": (8.5, 2), "out14": (10, 2),
			"1": (-1, -2), "2": (1, -1), "4": (1, -3), "6": (3, -2), "out6": (10, -2)
		},
		"controller": {
			"inputs": {"type": "squares", "origin": (-5, 0), "innerspan": 1, "squarespan": 7},# {"type": "singlenode", "pos": (0, 0)},
			"outputs": {"type": "column", "pos": (10, 0), "span": 1},
			"53": (1, 3),
			"74": (2, -4), "81": (4, -4),
			"67": (4, -1.5),
			"78": (6, -1.7), "59": (6, -1.3), "79": (8, -2),
		},
		"canvas": {
			"rgbpos": (0, 0.5),
			"epos": (0, -0.5),
			"cpos": (1, 0)
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
	0: "",
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
	for f in os.listdir(path):
		if int(f[0]) == frame and f[2] == key:
			node = int(f[3:-len(IMG_EXT)])
			b[node] = path + f # PIL.Image.open(path + f)
	return b

def retrieve_cont_buffer(path, frame):
	fname = path + str(frame) + "_c.yaml"
	b = open_yaml(fname)
	return b

def retrieve_metadata(path, frame):
	fname = path + str(frame) + "_m.yaml"
	return open_yaml(fname)

def get_paths(exp_dir):
	paths = {}
	paths["exp"] = exp_dir.split("results/",1)[1]
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
	rgbpos, epos, cpos = "(0, 0)", "(1, 0)", "(2, 0)"
	if expdir in list(POS.keys()) and "canvas" in list(POS[expdir].keys()):
		if "rgbpos" in list(POS[expdir]["canvas"].keys()):
			rgbpos = twopletostr(POS[expdir]["canvas"]["rgbpos"])
		if "epos" in list(POS[expdir]["canvas"].keys()):
			epos = twopletostr(POS[expdir]["canvas"]["epos"])
		if "cpos" in list(POS[expdir]["canvas"].keys()):
			cpos = twopletostr(POS[expdir]["canvas"]["cpos"])
	return rgbpos, epos, cpos
	
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
	row = int(in_square_index % size)
	col = math.floor(in_square_index / size)
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
	pos = postostr(pos)
	return pos
	
def getnodecontent(gdict, node, nodename, indtype, is_out, index=None, width="1cm"):
	if NOBUFFER:
		return nodename
	elif indtype == "encoder":
		if is_out:
			return "\includegraphics[width="+width+"]{"+gdict["reducer"]["buffer"][node]+"}"
		else:
			return "\includegraphics[width="+width+"]{"+gdict[indtype]["buffer"][node]+"}"
	elif indtype == "controller":
		if is_out:
			action_name_in_ale = gdict["controller"]["actions"][index]
			return ACTIONLABELS[action_name_in_ale]
		else:
			return "$" + str(round(gdict[indtype]["buffer"][node], 2)) + "$"
			
def getnodesettings(gdict, expdir, node, nodename, activated, indtype):
	if (
		indtype == "controller"
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
		nodecolor = ACTIVE_COLOR if node in activated else "black"
		nodesettings = NDSETTING+", draw="+nodecolor
	return nodesettings

def getedgelabel(fname):
	if fname in list(EDGELABELS.keys()):
		return EDGELABELS[fname]
	else:
		return fname[2:].replace('_', ' ')

def appendbackgroundnodes(ts, gdict, expdir, indtype):
	if (
		indtype == "controller"
		and ENABLE_MANUAL_POS
		and expdir in list(POS.keys()) 
		and indtype in list(POS[expdir].keys())
		and "inputs" in list(POS[expdir][indtype].keys())
		and POS[expdir][indtype]["inputs"]["type"] == "squares"
	): # reduced images as background
		posdict = POS[expdir][indtype]["inputs"]
		n_squares = gdict["encoder"]["n_out"]
		nodes_per_square = gdict[indtype]["n_in"] / n_squares
		size = math.sqrt(nodes_per_square)
		assert float(size).is_integer(), "impossible square size: " + str(size)
		width = str(posdict["innerspan"]*size)+"cm"
		for i in range(n_squares):
			node = gdict["encoder"]["outputs"][i]
			nodename = getnodename(i, gdict["encoder"], True)
			nodecontent = getnodecontent(gdict, node, nodename, "encoder", True, i, width=width)
			pos = posdict["origin"]
			current_square = i + 1
			sqshift = (0, ((n_squares+1)/2-current_square)*posdict["squarespan"])
			pos = tuple(map(operator.add, pos, sqshift)) # shift squares
			pos = str(pos[0]) + "," + str(pos[1])
			ts.append("\\node[] () at ("+pos+") {"+nodecontent+"};")

def appendnodes(ts, gdict, expdir, indtype):
	g = gdict[indtype]
	activated = gdict["metadata"][indtype]["activated"]
	outputs = gdict["metadata"][indtype]["outputs"]
	pos = getpos(gdict, expdir, indtype)
	appendbackgroundnodes(ts, gdict, expdir, indtype)
	for node in g["buffer"].keys():
		nodename = getnodename(node)
		isinput = node <= g["n_in"]
		p = pos[nodename]
		nodecontent = getnodecontent(gdict, node, nodename, indtype, False)
		nodesettings = getnodesettings(gdict, expdir, node, nodename, activated, indtype)
		ts.append("\\node["+nodesettings+"] ("+nodename+") at ("+p+") {"+nodecontent+"};")
	for i in range(len(g["outputs"])):
		node = g["outputs"][i]
		nodename = getnodename(i, g, True)
		p = pos[nodename]
		nodecontent = getnodecontent(gdict, node, nodename, indtype, True, i)
		nodesettings = getnodesettings(gdict, expdir, node, nodename, outputs, indtype)
		ts.append("\\node["+nodesettings+"] ("+nodename+") at ("+p+") {"+nodecontent+"};")

def appendedges(ts, gdict, indtype):
	g = gdict[indtype]
	activated = gdict["metadata"][indtype]["activated"]
	outputs = gdict["metadata"][indtype]["outputs"]
	for edge in g["edges"]:
		src, dst = str(edge[0]), str(edge[1])
		dstindex = g["nodes"].index(edge[1])
		edgelabel = getedgelabel(g["fs"][dstindex])
		edgeopt = "loop above" if edge[0] == edge[1] else "" # self-loop
		edgecolor = ACTIVE_COLOR if edge[1] in activated else "black"
		pathset = "->, color="+edgecolor
		if HALOEDGES:
			ts.append("\\path[->, color=white, ultra thick] ("+src+") edge["+edgeopt+"] node[above] {"+edgelabel+"} ("+dst+");")
		ts.append("\\path["+pathset+"] ("+src+") edge["+edgeopt+"] node[above] {"+edgelabel+"} ("+dst+");")
	for i in range(len(g["outputs"])):
		output = g["outputs"][i]
		src = str(output)
		dst = getnodename(i, g, True)
		edgecolor = ACTIVE_COLOR if output in outputs else "black"
		pathset = "->, color="+edgecolor
		if HALOEDGES:
			ts.append("\\path[->, color=white, ultra thick] ("+src+") edge node {} ("+dst+");")
		ts.append("\\path["+pathset+"] ("+src+") edge node {} ("+dst+");")

def graph_texscript(gdict, paths, indtype, printtex=True):
	ts = [] # texscript
	ts.append("\\documentclass[crop,tikz]{standalone}")
	ts.append("\\usepackage{graphicx}")
	ts.append("\\begin{document}")
	ts.append("\\begin{tikzpicture}")
	appendnodes(ts, gdict, paths["exp"], indtype)
	appendedges(ts, gdict, indtype)
	ts.append("\\end{tikzpicture}")
	ts.append("\\end{document}")
	
	if printtex:
		print("\nPrinting graph TeX file for", indtype, ":")
		print(100*"-")
		for l in ts:
			print(l)
		print(100*"-")
	return ts

def canvas_texscript(paths, frame, printtex=True):

	savedir = paths["metadata"]
	expdir = paths["exp"]
	rgb_path = savedir + rgbfname(frame)
	e_gpath = savedir + graphfname(frame, "encoder") + ".pdf"
	c_gpath = savedir + graphfname(frame, "controller") + ".pdf"
	
	rgb_content = "\includegraphics[width=1cm]{"+rgb_path+"}"
	e_content = "\includegraphics[width=1cm]{"+e_gpath+"}"
	c_content = "\includegraphics[width=1cm]{"+c_gpath+"}"
	
	rgbpos, epos, cpos = getcanvaspos(expdir)
	
	ts = []
	ts.append("\\documentclass[crop,tikz]{standalone}")
	ts.append("\\usepackage{graphicx}")
	ts.append("\\begin{document}")
	ts.append("\\begin{tikzpicture}")
	ts.append("\\node[] (e) at "+rgbpos+" {"+rgb_content+"};")
	ts.append("\\node[] (e) at "+epos+" {"+e_content+"};")
	ts.append("\\node[] (c) at "+cpos+" {"+c_content+"};")
	ts.append("\\end{tikzpicture}")
	ts.append("\\end{document}")
	
	if printtex:
		print("\nPrinting canvas TeX file :")
		print(100*"-")
		for l in ts:
			print(l)
		print(100*"-")
	return ts
	
def runtex(fname, savedir, texsavepath, show=True):
	subprocess.run(["pdflatex", "-interaction", "nonstopmode",
			"-output-directory", savedir, texsavepath])
	# clean
	for ext in [".tex", ".aux", ".log"]:
		os.remove(savedir + fname + ext)
	# evince
	if show:
		subprocess.run(["evince", savedir + fname + ".pdf"])
	
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
	runtex(fname, savedir, texsavepath)

def make_graphs(paths, frame):
	gdict = gdict_from_paths(paths, frame)
	for indtype in ["controller", "encoder"]:
		texscript = graph_texscript(gdict, paths, indtype)
		build_graph(texscript, paths, frame, indtype)
		exit()

def make_canvas(paths, frame):
	texscript = canvas_texscript(paths, frame)
	build_canvas(texscript, paths, frame)

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	max_frame = 1
	paths = get_paths(exp_dir)
	random.seed(SEED)

	for frame in range(1, max_frame + 1):
		make_graphs(paths, frame)
		# make_canvas(paths, frame)

# python3.7 pygraph.py /home/wahara/.julia/dev/IICGP/results/2021-09-01T17:44:01.968_boxing
# python3.8 pygraph.py /home/opaweynch/.julia/environments/v1.6/dev/IICGP/results/2021-09-01T17:44:01.968_boxing

