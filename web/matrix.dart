import 'dart:math';

import 'dart:typed_data';

class Vec3 {
  double x, y, z;
  
  Vec3(this.x, this.y, this.z);
  Vec3 operator *(double c) => Vec3(c*x, c*y, c*z);
  Vec3 operator /(double c) => Vec3(x/c, y/c, z/c);
  Vec3 operator +(Vec3 v) => Vec3(x+v.x, y+v.y, z+v.z);
  Vec3 operator -(Vec3 v) => Vec3(x-v.x, y-v.y, z-v.z);
  Vec3 operator -() => Vec3(-x, -y, -z);
  double dot(Vec3 v) => x*v.x + y*v.y + z*v.z;
  double norm() => sqrt(this.dot(this));
  Vec3 normalize() => this/this.norm();
  Vec3 cross(Vec3 v) => Vec3(y*v.z - z*v.y, z*v.x - x*v.z, x*v.y - y*v.x);
  Vec4 p() => Vec4(x, y, z, 1);
  Vec4 d() => Vec4(x, y, z, 0);
  @override
  String toString() => "Vec3($x, $y, $z)";
  List<double> list() => [x, y, z];
}

class Vec4 {
  double x, y, z, w;
  Vec4(this.x, this.y, this.z, this.w);
  Vec4 operator *(double c) => Vec4(c*x, c*y, c*z, c*w);
  Vec4 operator +(Vec4 v) => Vec4(x+v.x, y+v.y, z+v.z, w+v.w);
  Vec3 h() => Vec3(x, y, z);
  @override
  String toString() => "Vec4($x, $y, $z, $w)";
  List<double> list() => [x, y, z, w];
}

class Mat4 {
  Vec4 c1, c2, c3, c4;
  Mat4(this.c1, this.c2, this.c3, this.c4);
  static Mat4 id() => Mat4(Vec4(1,0,0,0), Vec4(0,1,0,0), Vec4(0,0,1,0), Vec4(0,0,0,1));
  Vec4 apply(Vec4 v) => (c1*v.x) + (c2*v.y) + (c3*v.z) + (c4*v.w);
  Mat4 operator *(Mat4 m) => Mat4(this.apply(m.c1), this.apply(m.c2), this.apply(m.c3), this.apply(m.c4));
  Mat4 t() => Mat4(
    Vec4(c1.x, c2.x, c3.x, c4.x),
    Vec4(c1.y, c2.y, c3.y, c4.y),
    Vec4(c1.z, c2.z, c3.z, c4.z),
    Vec4(c1.w, c2.w, c3.w, c4.w),
  );
  static Mat4 translate(Vec3 v) => Mat4(Vec4(1,0,0,0), Vec4(0,1,0,0), Vec4(0,0,1,0), v.p());
  static Mat4 lookAt(Vec3 eye, Vec3 target, Vec3 up) {
    final forward = (target-eye).normalize();
    final proj = forward*forward.dot(up);
    up = (up - proj).normalize();
    final right = forward.cross(up);
    final r = Mat4(right.d(), up.d(), (-forward).d(), Vec4(0, 0, 0, 1)).t();
    final t = Mat4.translate(-eye);
    return r*t;
  }
  static Mat4 frustum(double n, double f, double l, double r, double b, double t) =>
     Mat4(
        Vec4(2*n/(r-l), 0, 0, 0),
        Vec4(0, 2*n/(t-b), 0, 0),
        Vec4((r+l)/(r-l), (t+b)/(t-b), (n+f)/(n-f), -1),
        Vec4(0, 0, 2*f*n/(n-f), 0),
      );
  static Mat4 perspective(double fovx, double aspect, double n, double f) {
    var deg = fovx*pi/180;
    var halfw = tan(deg/2)*n;
    var halfh = halfw/aspect;
    return Mat4.frustum(n, f, -halfw, halfw, -halfh, halfh);
  }
  @override
  String toString() {
    return "Mat4($c1, $c2, $c3, $c4)";
  }
  Float32List array() => Float32List.fromList([c1.list(), c2.list(), c3.list(), c4.list()].expand((x) => x).toList());
}