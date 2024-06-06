from process import process
from PIL import Image
import numpy as np

warped = Image.fromarray(np.uint8(process("./IMG_0088.JPG") * 255))

warped.save("./test.jpg")