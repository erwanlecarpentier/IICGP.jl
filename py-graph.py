#!/usr/bin/python

import sys
import os
import networkx as nx
import matplotlib.pyplot as plt
import yaml

DIR_PATH = os.path.dirname(os.path.realpath(__file__))
SEED = 123


def get_g_paths_dict(exp_dir):
	g_dir = exp_dir + "/graphs"
	dct = {}
	for f in  os.listdir(g_dir):
		ind_name = f[0:len(f)-len(".yaml")]
		dct[ind_name] = g_dir + "/" + f
	return dct

def g_dict_from_g_paths_dict(g_paths_dict):
	g_dict = {}
	for k, v in g_paths_dict.items():
		with open(v, 'r') as stream:
			try:
				g = yaml.safe_load(stream)
				g_dict[k] = g
			except yaml.YAMLError as exc:
				print(exc)
	return g_dict

def make_graph(g):
	G = nx.Graph()
	for n in g["nodes"]:
		G.add_node(n)
	return G

def draw_graph(G):
	fig, ax = plt.subplots()
	ax.set_aspect('equal')
	plt.xlim(-1.5,1.5)
	plt.ylim(-1.5,1.5)
	pos = nx.spring_layout(G, seed=SEED)
	edge_options = {
		"pos": pos,
		"ax": ax,
		"arrows": True,
		"arrowstyle": "-"
	}

	# Note: the min_source/target_margin kwargs only work with FancyArrowPatch objects.
	# Force the use of FancyArrowPatch for edge drawing by setting `arrows=True`,
	# but suppress arrowheads with `arrowstyle="-"`
	nx.draw_networkx_edges(G, **edge_options)
	# nx.draw_networkx(G, **graph_options)

	# Transform from data coordinates (scaled between xlim and ylim) to display coordinates
	tr_figure = ax.transData.transform
	# Transform from display to figure coordinates
	tr_axes = fig.transFigure.inverted().transform

	ax.axis("off")
	plt.show()

if __name__ == "__main__":
	exp_dir = sys.argv[1]

	g_paths_dict = get_g_paths_dict(exp_dir)
	g_dict = g_dict_from_g_paths_dict(g_paths_dict)

	g_enco = make_graph(g_dict["encoder"])
	draw_graph(g_enco)
	



'''
# IMAGE IN GRAPH

# Select the size of the image (relative to the X axis)
img_size = (ax.get_xlim()[1] - ax.get_xlim()[0]) * 0.1
img_center = img_size / 2.0

# Add the respective image to each node
for n in G.nodes:
	xf, yf = tr_figure(pos[n])
	print(pos[n])
	print(xf, yf)
	print()
	xa, ya = tr_axes((xf, yf))
	# get overlapped axes and plot icon
	a = plt.axes([xa - img_center, ya - img_center, img_size, img_size])
	a.imshow(G.nodes[n]["image"])
	a.axis("off")
ax.axis("off")
plt.show()

exit()
'''





'''
graph_options = {
	"pos": pos,
	"ax": ax,
 	"font_size": 36,
	"node_size": 3000,
	"node_color": "white",
	"edgecolors": "black",
	"linewidths": 5,
	"width": 5,
}

# Set margins for the axes so that nodes aren't clipped
ax = plt.gca()
ax.margins(0.20)
plt.axis("off")
plt.show()
'''
