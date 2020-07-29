import 'dart:html';
import 'dart:web_gl';
import 'dart:math';

import 'matrix.dart';
import "teapot.dart";


final CanvasElement canvas = querySelector("canvas");
RenderingContext gl;
Program shaderProgram;
Buffer vbo, ebo;

double cameraDistance = 5, cameraYaw = 0, cameraPitch = 0;
bool isMouseDown = false;
double mouseX, mouseY;

List<VertexData> teapotData = makeTeapot().map((x)=>x.mesh(50, 50)).toList();

const vsSource = """
attribute vec3 aPos;
attribute vec3 aNormal;

uniform mat4 uModel;
uniform mat4 uView;
uniform mat4 uProjection;

varying vec3 vNormal;

void main() {
    gl_Position = uProjection * uView * uModel * vec4(aPos, 1.0);
    vNormal = aNormal;
    // gl_Position = vec4(aPos, 1.0);
}
""";

const fsSource = """
precision highp float;

varying vec3 vNormal;

uniform float uTime;

void main() {
    // float x = sin(2.0*uTime);
    // float y = cos(2.0*uTime);
    // x = x/4.0 + .5;
    // y = y/4.0 + .5;
    gl_FragColor = vec4(vNormal, 1.0);
}
""";

Shader loadShader(type, source) {
  final shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, WebGL.COMPILE_STATUS)) {
    throw Exception('An error occurred compiling the shaders: ${gl.getShaderInfoLog(shader)}');
  }
  return shader;
}

Program createProgram(vsSource, fsSource) {
  final shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, loadShader(WebGL.VERTEX_SHADER, vsSource));
  gl.attachShader(shaderProgram, loadShader(WebGL.FRAGMENT_SHADER, fsSource));
  gl.linkProgram(shaderProgram);
  if (!gl.getProgramParameter(shaderProgram, WebGL.LINK_STATUS)) {
    throw Exception('Unable to initialize the shader program: ${gl.getProgramInfoLog(shaderProgram)}');
  }
  return shaderProgram;
}

void loop(num now) {
  now /= 1000;
  var eye = Vec3(
    cameraDistance*sin(cameraYaw)*cos(cameraPitch),
    cameraDistance*sin(cameraPitch),
    cameraDistance*cos(cameraYaw)*cos(cameraPitch),
  );
  
  gl.clear(WebGL.COLOR_BUFFER_BIT);
  gl.uniform1f(gl.getUniformLocation(shaderProgram, "uTime"), now);
  var view = Mat4.lookAt(eye, Vec3(0, 0, 0), Vec3(0, 1, 0));
  var w = canvas.width;
  var h = canvas.height;
  var projection = Mat4.perspective(60, w/h, .1, 100);

  gl.uniformMatrix4fv(gl.getUniformLocation(shaderProgram, "uModel"), false, Mat4.id().array());
  gl.uniformMatrix4fv(gl.getUniformLocation(shaderProgram, "uView"), false, view.array());
  gl.uniformMatrix4fv(gl.getUniformLocation(shaderProgram, "uProjection"), false, projection.array());

  for (var vertexData in teapotData) {
    gl.bindBuffer(WebGL.ARRAY_BUFFER, vbo);
    gl.bufferData(
        WebGL.ARRAY_BUFFER,
        vertexData.vertices,
        WebGL.STATIC_DRAW
    );
    gl.enableVertexAttribArray(0);
    gl.vertexAttribPointer(0, 3, WebGL.FLOAT, false, 24, 0);
    gl.enableVertexAttribArray(1);
    gl.vertexAttribPointer(1, 3, WebGL.FLOAT, false, 24, 12);

    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, ebo);
    gl.bufferData(WebGL.ELEMENT_ARRAY_BUFFER, vertexData.indicies, WebGL.STATIC_DRAW);

    gl.drawElements(WebGL.TRIANGLES, vertexData.indicies.length, WebGL.UNSIGNED_SHORT, 0);
  }  
  window.animationFrame.then(loop);
}

void main() {
  gl = canvas.getContext3d();
  shaderProgram = createProgram(vsSource, fsSource);
  gl.useProgram(shaderProgram);

  gl.clearColor(.2, .2, .5, 1);
  gl.enable(WebGL.DEPTH_TEST);
  gl.viewport(0, 0, canvas.width, canvas.height);

  vbo = gl.createBuffer();
  ebo = gl.createBuffer();

  canvas.onMouseDown.listen((event) {
    isMouseDown = true;
    mouseX = event.client.x;
    mouseY = event.client.y;
  });

  canvas.onMouseUp.listen((event) {
    isMouseDown = false;
  });

  canvas.onMouseMove.listen((event) {
    if (isMouseDown) {
      cameraYaw -= (event.client.x - mouseX)*.01;
      cameraPitch += (event.client.y - mouseY)*.01;
      if (cameraPitch >= pi/2) {
        cameraPitch = pi/2-.001;
      } else if (cameraPitch <= -pi/2) {
        cameraPitch = -pi/2+.001;
      }
      mouseX = event.client.x;
      mouseY = event.client.y;
    }
  });

  canvas.onWheel.listen((event) {
    cameraDistance += event.deltaY > 0 ? 1 : -1;
    if (cameraDistance < 1) {
      cameraDistance = 1;
    }
  });

  window.animationFrame.then(loop);
}
