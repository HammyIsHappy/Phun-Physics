// Isaiah Hamblin
// Last Edit 5/21/2026
// Track class includes constructors and display method

class Track {
  int id;
  
  float xStart;
  float yStart;
  float xEnd;
  float yEnd;

  // Change in x and y
  float tx;
  float ty;
  float lengthSquared;

  // Build track from point a to point b
  Track(float xs, float ys, float xe, float ye) {
    this.xStart = xs;
    this.yStart = ys;
    this.xEnd = xe;
    this.yEnd = ye;

    this.tx = this.xEnd - this.xStart;
    this.ty = this.yEnd - this.yStart;
    this.lengthSquared = this.tx * this.tx + this.ty * this.ty;
  }
  
  // Draws line on sketch
  void display() {
    line(xStart, yStart, xEnd, yEnd);
  }
}
