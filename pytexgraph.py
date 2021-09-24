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
CTR_INCR = 200 # increment for controller's nodes names
OUT_INCR = 100 # increment for outputs's nodes names
FEATURE_SIZE = 25 # 5*5 mean-pooling features

# Graph Layout
FRW_NODE_COLOR = "red"
INP_NODE_COLOR = "green"
INN_NODE_COLOR = "black"
OUT_NODE_COLOR = "blue"
POSITIONING = "spring" # circular spring dual single
MERGE_CONTROLLER_INPUT = False
WITH_LABELS = False
FIGSIZE = (5, 5)
XLIM, YLIM = 100, 100
E_XLIM, E_YLIM = 1, 1
C_XLIM, C_YLIM = 1, 1
IMG_SIZE_PROPORTION = 0.01
NODES_SIZE = 30
NODES_SPACING = 1

# Tex
NDSETTING = "shape=circle, draw=black"

POS = {
	"2021-09-01T17:44:01.968_boxing": {
		"11": (0, 0),
		"9": (1, 0),
		"3": (2, 0),
		"2": (0, 1),
		"1": (1, 1),
		"6": (2, 1),
		"14": (0, 2),
		"4": (1, 2),
		"out6": (2, 2),
		"out14": (3, 3),
	}
}

TEST_TEXSCRIPT = [
	"\\documentclass{article}",
	"\\usepackage{tikz}",
	"\\usepackage{verbatim}",
	"\\usepackage{verbatim}",
	"\\usepackage[active,tightpage]{preview}",
	"\\PreviewEnvironment{tikzpicture}",
	"\\setlength\PreviewBorder{5pt}%",
	"\\begin{document}",
	"\\begin{tikzpicture}",
	"\\def \\n{5}",
	"\\def \\radius {3cm}",
	"\\def \\margin {8}",
	"\\foreach \\s in {1,...,\\n}",
	"{",
	"  \\node[draw, circle] at ({360/\\n * (\\s - 1)}:\\radius) {$\\s$};",
	"  \\draw[->, >=latex] ({360/\\n * (\\s - 1)+\\margin}:\\radius)",
	"    arc ({360/\\n * (\\s - 1)+\\margin}:{360/\\n * (\\s)-\\margin}:\\radius);",
	"}",
	"\\end{tikzpicture}",
	"\\end{document}"
]

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
			b[node] = PIL.Image.open(path + f)
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
	paths["meta"] = exp_dir + "/buffers/"
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
	gdict["meta"] = retrieve_metadata(paths["meta"], frame)
	return gdict

def incr_nodes(g, incr):
	for k in ["nodes", "inputs", "outputs"]:
		g[k] = [n + incr for n in g[k]]
	g["edges"] = [(e[0]+incr, e[1]+incr) for e in g["edges"]]
	init_keys = [k for k in g["buffer"].keys()]
	for k in init_keys:
		g["buffer"][k+incr] = g["buffer"].pop(k)
	return g
	
def get_output_nodes_labels(G, outputs):
	out = []
	for i in range(len(outputs)):
		out_i = outputs[i] + OUT_INCR
		while out_i in out:
			out_i += 1
		out.append(out_i)
	return out

def set_graph(G, g, gr=None):
	# Nodes
	G.add_nodes_from(g["buffer"].keys())
	output_nodes = get_output_nodes_labels(G, g["outputs"])
	G.add_nodes_from(output_nodes)

	# Edges
	G.add_edges_from(g["edges"])
	for i in range(len(output_nodes)):
		G.add_edge(g["outputs"][i], output_nodes[i])
	edgelabels = {}
	for e in g["edges"]:
		dest_node = e[1]
		dest_node_index = g["nodes"].index(dest_node)
		edgelabels[e] = g["fs"][dest_node_index]

	# Set colors
	edgecolors = []
	for n in G:
		if n in g["inputs"]:
			edgecolors.append(INP_NODE_COLOR)
		elif n in g["outputs"]:
			edgecolors.append(OUT_NODE_COLOR)
		else:
			edgecolors.append(INN_NODE_COLOR)

	# Set inner buffer
	for n in g["buffer"].keys():
		G.nodes[n]["buffer"] = g["buffer"][n]
	
	# Set output buffer
	for i in range(len(output_nodes)):
		out_node_i = output_nodes[i]
		out_i = g["outputs"][i]
		r_buffer_i = g["buffer"][out_i] if gr is None else gr["buffer"][out_i]
		G.nodes[out_node_i]["buffer"] = r_buffer_i
		
	return G, edgelabels, edgecolors
	
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
	"""
	print("\nreducer:")
	print(gdict["reducer"])
	print("\ncontroller:")
	#print(gdict["controller"])
	printinddict(gdict["controller"])
	print("\nmetadata:")
	print(gdict["meta"])
	"""
	print()
	
def getnodename(node, isout=False):
	return "out"+str(node) if isout else str(node)
	
def getpos(nodename, expdir):
	if expdir in list(POS.keys()):
		pos = POS[expdir][nodename]
	else:
		pos = (random.random(),random.random())
	return str(pos[0])+","+str(pos[1])
	
def appendnodes(ts, gdict, expdir):
	g = gdict["encoder"]
	for node in g["buffer"].keys():
		nodename = getnodename(node)
		pos = getpos(nodename, expdir)
		ts.append("\\node["+NDSETTING+"] ("+nodename+") at ("+pos+") {"+nodename+"};")
	for node in g["outputs"]:
		nodename = getnodename(node, isout=True)
		pos = getpos(nodename, expdir)
		ts.append("\\node["+NDSETTING+"] ("+nodename+") at ("+pos+") {"+nodename+"};")
	
def create_texscript(gdict, paths):
	ts = [] # texscript
	ts.append("\\documentclass[crop,tikz]{standalone}")
	ts.append("\\begin{document}")
	ts.append("\\begin{tikzpicture}")
	appendnodes(ts, gdict, paths["exp"])
	ts.append("\\end{tikzpicture}")
	ts.append("\\end{document}")
	
	# TODO rm START
	for l in ts:
		print(l)
	#exit()
	# TODO rm END
	return ts
	
def build(texscript, paths, frame):
	savedir = paths["meta"]
	fname = "1_enco_graph"
	texsavepath = savedir + fname + ".tex"
	with open(texsavepath, 'w') as f:
		for line in texscript:
			f.write(line)
			f.write('\n')
		f.close()
	print(texsavepath)
	subprocess.run(["pdflatex", "-interaction", "nonstopmode",
			"-output-directory", savedir, texsavepath])
	# remove
	for ext in [".tex", ".aux", ".log"]:
		os.remove(savedir + fname + ext)
	# evince
	subprocess.run(["evince", savedir + fname + ".pdf"])
	# Turn into png here if required
		
def make_graph(paths, frame):
	gdict = gdict_from_paths(paths, frame)
	texscript = create_texscript(gdict, paths)
	build(texscript, paths, frame)

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	max_frame = 1
	paths = get_paths(exp_dir)

	for frame in range(1, max_frame + 1):
		make_graph(paths, frame)

# python3.7 pygraph.py /home/wahara/.julia/dev/IICGP/results/2021-09-01T17:44:01.968_boxing
# python3.8 pygraph.py /home/opaweynch/.julia/environments/v1.6/dev/IICGP/results/2021-09-01T17:44:01.968_boxing

