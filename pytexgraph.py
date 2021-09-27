#!/usr/bin/python

import sys
import os
import subprocess
import math
import yaml
import PIL
import random
import matplotlib.animation as animation
from matplotlib.widgets import Slider


# Meta parameters
SEED = 1234
DIR_PATH = os.path.dirname(os.path.realpath(__file__))
IMG_EXT = ".png"
IMG_TYPE = PIL.PngImagePlugin.PngImageFile

# Graph layout
NOBUFFER = True
ACTIVE_COLOR = "red"
NDSETTING = "shape=rectangle, rounded corners=0.1cm"

POSITIONING = "random" # manual random
ENABLE_MANUAL_POS = True
POS = {
	"2021-09-01T17:44:01.968_boxing": {
		"encoder": {
			"3": (1, 2), "9": (3, 2), "11": (5.5, 2), "14": (8.5, 2), "out14": (10, 2),
			"1": (-1, -2), "2": (1, -1), "4": (1, -3), "6": (3, -2), "out6": (10, -2)
		},
		"controller": {
			"inputs": (0, 0), "outputs": (1, 1)
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

def retrieve_buffer(ind_name, path, frame):
	if ind_name == "encoder":
		return retrieve_img_buffer(path, frame, "e")
	elif ind_name == "reducer":
		return retrieve_img_buffer(path, frame, "f")
	elif ind_name == "controller":
		return retrieve_cont_buffer(path, frame)
	else:
		raise NameError(ind_name)

def retrieve_img_buffer(path, frame, key):
	b = {}
	for f in os.listdir(path):
		if int(f[0]) == frame and f[2] == key:
			node = int(f[3:-len(IMG_EXT)])
			b[node] = path+f # PIL.Image.open(path + f)
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
		ind_name = f[0:len(f)-len(".yaml")]
		paths[ind_name] = {}
		paths[ind_name]["graph"] = g_dir + "/" + f
		paths[ind_name]["buffer"] = exp_dir + "/buffers/"
	paths["reducer"] = {}
	paths["reducer"]["buffer"] = exp_dir + "/buffers/"
	paths["metadata"] = exp_dir + "/buffers/"
	return paths

def gdict_from_paths(paths, frame):
	gdict = {}
	for ind_name in ["encoder", "controller"]:
		v = paths[ind_name]
		g = open_yaml(v["graph"])
		g["inputs"] = list(range(1,1+g["n_in"]))
		g["edges"] = [str_to_tuple(e) for e in g["edges"]]
		g["buffer"] = retrieve_buffer(ind_name, v["buffer"], frame)
		gdict[ind_name] = g
	gdict["reducer"] = {}
	gdict["reducer"]["buffer"] = retrieve_buffer("reducer", paths["reducer"]["buffer"], frame)
	gdict["metadata"] = retrieve_metadata(paths["metadata"], frame)
	return gdict
	
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
	
def getnodename(node, isout=False):
	return "out"+str(node) if isout else str(node)
	
def randompos():
	mag = 10
	return (mag*random.random(), mag*random.random())

# Deprecated
"""
def getpos(nodename, expdir, indtype, isinput):
	if (
		POSITIONING == "manual" and
		expdir in list(POS.keys()) and
		indtype in list(POS[expdir].keys())
	):
		if nodename in list(POS[expdir][indtype].keys()):
			pos = POS[expdir][indtype][nodename]
		elif isinput and "inputs" in list(POS[expdir][indtype].keys()):
			pos = POS[expdir][indtype]["inputs"]
		else:
			pos = randompos()
	else:
		pos = randompos()
	return str(pos[0])+","+str(pos[1])
"""
def postostr(pos):
	for k, v in pos.items():
		pos[k] = str(v[0])+","+str(v[1])
	return pos

def getpos(gdict, expdir, indtype):
	pos = {}
	g = gdict[indtype]
	for node in list(g["buffer"].keys()):
		nodename = getnodename(node, False)
		pos[nodename] = randompos() # Default to random position
		if ENABLE_MANUAL_POS:
			isout = False
			isinp = node <= g["n_in"]
			if expdir in list(POS.keys()) and indtype in list(POS[expdir].keys()):
				if nodename in list(POS[expdir][indtype].keys()):
					pos[nodename] = POS[expdir][indtype][nodename]
				elif isinp and "inputs" in list(POS[expdir][indtype].keys()):
					pos[nodename] = POS[expdir][indtype]["inputs"]
	for node in g["outputs"]:
		nodename = getnodename(node, True)
		pos[nodename] = randompos() # Default to random position
		if ENABLE_MANUAL_POS:
			if expdir in list(POS.keys()) and indtype in list(POS[expdir].keys()):
				if nodename in list(POS[expdir][indtype].keys()):
					pos[nodename] = POS[expdir][indtype][nodename]
				elif isinp and "outputs" in list(POS[expdir][indtype].keys()):
					pos[nodename] = POS[expdir][indtype]["outputs"]
	pos = postostr(pos)
	
	printdict(pos)
	return pos
	
def getnodecontent(gdict, node, nodename, indtype, is_out):
	if NOBUFFER:
		return nodename
	elif indtype == "encoder":
		if is_out:
			return "\includegraphics[width=1cm]{"+gdict["reducer"]["buffer"][node]+"}"
		else:
			return "\includegraphics[width=1cm]{"+gdict[indtype]["buffer"][node]+"}"
	elif indtype == "controller":
		return "$" + str(round(gdict[indtype]["buffer"][node], 2)) + "$"

def getedgelabel(fname):
	if fname in list(EDGELABELS.keys()):
		return EDGELABELS[fname]
	else:
		return fname[2:].replace('_', ' ')
	
def appendnodes(ts, gdict, expdir, indtype):
	g = gdict[indtype]
	activated = gdict["metadata"][indtype]["activated"]
	outputs = gdict["metadata"][indtype]["outputs"]
	pos = getpos(gdict, expdir, indtype)
	for node in g["buffer"].keys():
		nodename = getnodename(node)
		isinput = node <= g["n_in"]
		p = pos[nodename]
		nodecontent = getnodecontent(gdict, node, nodename, indtype, False)
		nodecolor = ACTIVE_COLOR if node in activated else "black"
		nodeset = NDSETTING+", draw="+nodecolor
		ts.append("\\node["+nodeset+"] ("+nodename+") at ("+p+") {"+nodecontent+"};")
	for node in g["outputs"]:
		nodename = getnodename(node, True)
		p = pos[nodename]
		nodecontent = getnodecontent(gdict, node, nodename, indtype, True)
		nodecolor = ACTIVE_COLOR if node in outputs else "black"
		nodeset = NDSETTING+", draw="+nodecolor
		ts.append("\\node["+nodeset+"] ("+nodename+") at ("+p+") {"+nodecontent+"};")

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
		ts.append("\\path["+pathset+"] ("+src+") edge["+edgeopt+"] node[above] {"+edgelabel+"} ("+dst+");")
	for output in g["outputs"]:
		src = str(output)
		dst = getnodename(output, True)
		edgecolor = ACTIVE_COLOR if output in outputs else "black"
		pathset = "->, color="+edgecolor
		ts.append("\\path["+pathset+"] ("+src+") edge node {} ("+dst+");")

def create_texscript(gdict, paths, indtype, printtex=True):
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
		print("\nPrinting TeX file for", indtype, ":")
		print(100*"-")
		for l in ts:
			print(l)
		print(100*"-")
	return ts
	
def build(texscript, paths, frame, indtype):
	savedir = paths["metadata"]
	fname = str(frame) + "_graph_" + indtype
	texsavepath = savedir + fname + ".tex"
	with open(texsavepath, 'w') as f:
		for line in texscript:
			f.write(line)
			f.write('\n')
		f.close()
	print(texsavepath)
	subprocess.run(["pdflatex", "-interaction", "nonstopmode",
			"-output-directory", savedir, texsavepath])
	# clean
	for ext in [".tex", ".aux", ".log"]:
		os.remove(savedir + fname + ext)
	# evince
	subprocess.run(["evince", savedir + fname + ".pdf"])
	# Turn into png here if required

def make_graph(paths, frame):
	gdict = gdict_from_paths(paths, frame)
	for indtype in ["encoder", "controller"]:
		texscript = create_texscript(gdict, paths, indtype)
		build(texscript, paths, frame, indtype)

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	max_frame = 1
	paths = get_paths(exp_dir)
	random.seed(SEED)

	for frame in range(1, max_frame + 1):
		make_graph(paths, frame)

# python3.7 pygraph.py /home/wahara/.julia/dev/IICGP/results/2021-09-01T17:44:01.968_boxing
# python3.8 pygraph.py /home/opaweynch/.julia/environments/v1.6/dev/IICGP/results/2021-09-01T17:44:01.968_boxing

