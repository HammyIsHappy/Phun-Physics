// Isaiah Hamblin
// Last Edit 5/29/2026
// Track class includes constructors and display method

class Track {
  int id;
  
  PVector start;
  PVector end;

  float lengthSquared;

  // Build track from point a to point b
  Track(float xs, float ys, float xe, float ye) {
    start = new PVector(xs, ys);
    end = new PVector(xe, ye);

    this.lengthSquared = PVector.sub(start, end).magSq();
  }
  
  // Draws line on sketch
  void display() {
    line(start.x, start.y, end.x, end.y);
  }
}
