import networkx as nx
import matplotlib.pyplot as plt
import os

DIR_PATH = os.path.dirname(os.path.realpath(__file__))
IMG_DIR = DIR_PATH + "/images/"
fname = IMG_DIR + "lost_luggage_frame_31.png"

img = plt.imread(fname)


G = nx.Graph()
G.add_node(0, image=img)
G.add_node(1, image=img)
G.add_node(2, image=img)
G.add_edge(0, 1)
G.add_edge(1, 2)
G.add_edge(2, 0)

# Get a reproducible layout and create figure
pos = nx.spring_layout(G, seed=123)
# pos = {1: (0, 0), 2: (-1, 0.3)}
fig, ax = plt.subplots()
ax.set_aspect('equal')
plt.xlim(-1.5,1.5)
plt.ylim(-1.5,1.5)


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
edge_options = {
	"pos": pos,
	"ax": ax,
	"arrows": True,
	"arrowstyle": "-",
#	"min_source_margin"=15,
#	"min_target_margin"=15,
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





# Set margins for the axes so that nodes aren't clipped
ax = plt.gca()
ax.margins(0.20)
plt.axis("off")
plt.show()
