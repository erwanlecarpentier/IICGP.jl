import cv2


def on_change(val):
	# imageCopy = img.copy()
	img = cv2.imread(imgpath(frames[val]))
	cv2.imshow(windowName, img)

def imgpath(frame):
	return "./images/atlantis_frame_" + str(frame) + ".png"

frames = [0, 1, 2, 30, 31]
img = cv2.imread(imgpath(frames[0]))

windowName = "image"

cv2.imshow(windowName, img)
cv2.createTrackbar("slider", windowName, 0, len(frames)-1, on_change)

cv2.waitKey(0)
cv2.destroyAllWindows()
