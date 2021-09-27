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
NOBUFFER = False
ACTIVE_NODE_COLOR = "red"
NDSETTING = "shape=rectangle, rounded corners=0.2cm"

POSITIONING = "manual" # manual random
POS = {
	"2021-09-01T17:44:01.968_boxing": {
		"3": (1, 2),
		"9": (3, 2),
		"11": (5.5, 2),
		"14": (8.5, 2),
		"1": (-1, -2),
		"2": (1, -1),
		"4": (1, -3),
		"6": (3, -2),
		"out6": (10, -2),
		"out14": (10, 2),
	}
}
EDGENAMES = {
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
	print("\nreducer:")
	print(gdict["reducer"])
	print("\ncontroller:")
	#print(gdict["controller"])
	printinddict(gdict["controller"])
	print("\nmeta:")
	print(gdict["meta"])
	print()
	
def getnodename(node, isout=False):
	return "out"+str(node) if isout else str(node)
	
def getpos(nodename, expdir):
	if POSITIONING == "manual" and expdir in list(POS.keys()):
		pos = POS[expdir][nodename]
	else:
		pos = (5*random.random(),5*random.random())
	return str(pos[0])+","+str(pos[1])
	
def appendnodes(ts, gdict, expdir):
	g = gdict["encoder"]
	activated = gdict["meta"]["e_activated"]
	nodecontent = "O"
	for node in g["buffer"].keys():
		nodename = getnodename(node)
		pos = getpos(nodename, expdir)
		nodecontent = nodename if NOBUFFER else "\includegraphics[width=1cm]{"+g["buffer"][node]+"}"
		nodecolor = ACTIVE_NODE_COLOR if node in activated else "black"
		nodeset = NDSETTING+", draw="+nodecolor
		ts.append("\\node["+nodeset+"] ("+nodename+") at ("+pos+") {"+nodecontent+"};")
	for node in g["outputs"]:
		nodename = getnodename(node, True)
		pos = getpos(nodename, expdir)
		nodecontent = nodename if NOBUFFER else "\includegraphics[width=1cm]{"+gdict["reducer"]["buffer"][node]+"}"
		nodecolor = ACTIVE_NODE_COLOR if node in activated else "black"
		nodeset = NDSETTING+", draw="+nodecolor
		ts.append("\\node["+nodeset+"] ("+nodename+") at ("+pos+") {"+nodecontent+"};")
		
def appendedges(ts, gdict):
	g = gdict["encoder"]
	for edge in g["edges"]:
		src, dst = str(edge[0]), str(edge[1])
		dstindex = g["nodes"].index(edge[1])
		edgeopt = ""
		edgelabel = EDGENAMES[g["fs"][dstindex]]
		if edge[0] == edge[1]: # self-loop
			edgeopt += "loop above"
		ts.append("\\path[->] ("+src+") edge["+edgeopt+"] node[above] {"+edgelabel+"} ("+dst+");")
	for output in g["outputs"]:
		src = str(output)
		dst = getnodename(output, True)
		ts.append("\\path[->] ("+src+") edge node {} ("+dst+");")
	
	#for i in range(len(output_nodes)):
	#	G.add_edge(g["outputs"][i], output_nodes[i])
	
def create_texscript(gdict, paths):
	ts = [] # texscript
	ts.append("\\documentclass[crop,tikz]{standalone}")
	ts.append("\\usepackage{graphicx}")
	ts.append("\\begin{document}")
	ts.append("\\begin{tikzpicture}")
	appendnodes(ts, gdict, paths["exp"])
	appendedges(ts, gdict)
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
	fname = "1_graph" # TODO differentiate for controller
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
	printgdict(gdict)
	texscript = create_texscript(gdict, paths)
	build(texscript, paths, frame)

if __name__ == "__main__":
	exp_dir = sys.argv[1]
	max_frame = 1
	paths = get_paths(exp_dir)
	random.seed(SEED)

	for frame in range(1, max_frame + 1):
		make_graph(paths, frame)

# python3.7 pygraph.py /home/wahara/.julia/dev/IICGP/results/2021-09-01T17:44:01.968_boxing
# python3.8 pygraph.py /home/opaweynch/.julia/environments/v1.6/dev/IICGP/results/2021-09-01T17:44:01.968_boxing

