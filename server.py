from flask import Flask, request, jsonify, send_file
from werkzeug.utils import secure_filename
import os
import numpy as np
from process import process
from PIL import Image
import base64
import io

UPLOAD_FOLDER = "temp"
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

app = Flask(__name__)
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
  
@app.route("/process_image", methods=["POST"])
def process_image():
  if 'file' not in request.files:
    return jsonify({
      'msg': 'bad file',
    })
  
  file = request.files['file']
  if file.filename == '':
    return jsonify({
      'msg': 'bad file',
    })
  if file and allowed_file(file.filename):
    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    file.save(filepath)
    
    warped = Image.fromarray(np.uint8(process(filepath) * 255))
    warped_filepath = os.path.join(app.config['UPLOAD_FOLDER'], "temp.png")
    warped.save(warped_filepath)
    
    os.remove(filepath)
    result = send_file(warped_filepath)
    os.remove(warped_filepath)
    
    return result
  else:
    return jsonify({
      'msg': 'bad file',
    })