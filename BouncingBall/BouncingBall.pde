import java.util.*;

boolean paused = false;
ArrayList<Ball> balls = new ArrayList<Ball>();

void setup() {
  size(800, 800);
  background(255);
  smooth(8);
  frameRate(60);
}

// Draw button function
void drawButton(int x, int y, int w, int h, String label) {
  fill(200);
  rect(x, y, w, h);
  fill(0);
  textAlign(CENTER, CENTER);
  text(label, x + w / 2, y + h / 2);
}

// To determine if mouse if hovering over a button
boolean overButton(int x, int y, int w, int h) {
  return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
}

// If mouse gets pressed
void mousePressed() {
  // Buttons
  if (overButton(10, 10, 100, 30)) {
    balls.add(new Ball((float) (Math.random() * 700), 
    (float) (Math.random() * 700), 
    (float) (Math.random() * 300), 
    (float) (Math.random() * 300), 
    (int) (Math.random() * 15 + 5)));
    return;
  }
  if (overButton(120, 10, 100, 30)) {
    balls.clear();
    return;
  }
  if (overButton(230, 10, 100, 30)) {
    paused = !paused;
    return;
  }
}


// Update everything
void draw() {
  background(255);
  // Draw buttons
  drawButton(10, 10, 100, 30, "Add Ball");
  drawButton(120, 10, 100, 30, "Clear");
  drawButton(230, 10, 100, 30, paused ? "Resume" : "Pause");
  
  // Number of miliseconds sense program started
  double dt = 1.0 / frameRate;

  if (!paused) {
    for (Ball b : balls) {
      b.update(dt);  
    }
  } 
  else {
    for (Ball b : balls) {
     b.display();
    }
  } 
  

}

class Ball {
  float x;
  float y;
  float vx;
  float vy;
  int radius;
  
  public Ball(float x, float y, float vx, float vy, int radius) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.radius = radius;
  }
  
  public void update(double dt) {
    this.updateVectors(dt);
    this.checkWalls();
    this.checkCollision();
    this.display();
  }
  
  void updateVectors(double dt) {
    this.x += vx * dt;
    this.y += vy * dt;
    this.vy += 300 * dt;
  }
  
  void display() {
    ellipse(this.x, this.y, this.radius * 2, this.radius * 2);
  }
  
  void checkWalls() {
    if (this.x + radius > width) {this.x = width - radius; vx *= -0.9;} 
    if (this.x - radius < 0) {this.x = radius; vx *= -0.9;}
    if (this.y + radius > height) {this.y = height - radius; vy *= -0.9;}
    if (this.y - radius < 0) {this.y = radius; vy *= -0.9;}
  }
  
  void checkCollision() {
    for (Ball b : balls) {
      if (b.equals(this)) {continue;}
      
      float dx = b.x - this.x;
      float dy = by - this.y;
      float distSq = dx * dx + dy * dy;
      float minDistSq = this.radius * this.radius + b.radius * b.radius;
      
      if (distSq <= minDistSq) {
        float dist = sqrt(distSq);
        
        if (dist == 0) {
          dist = 0.01;
          dx = 0.01;
          dy = 0;
        }
      
      }
      
      
      && (this.x - b.x) * (this.x - b.x) + (this.y - b.y) * (this.y - b.y) <= (this.radius + b.radius) * (this.radius + b.radius)) {
        float vxNewThis = (this.radius - b.radius) / (this.radius + b.radius) * this.vx + (2 * b.radius) / (this.radius + b.radius) * b.vx;
        float vyNewThis = (this.radius - b.radius) / (this.radius + b.radius) * this.vy + (2 * b.radius) / (this.radius + b.radius) * b.vy;
        float vxNewOther = (2 * this.radius) / (this.radius + b.radius) * this.vx + (b.radius - this.radius) / (this.radius + b.radius) * b.vx;
        float vyNewOther = (2 * this.radius) / (this.radius + b.radius) * this.vy + (b.radius - this.radius) / (this.radius + b.radius) * b.vy;
        this.vx = vxNewThis;
        this.vy = vyNewThis;
        b.vx = vxNewOther;
        b.vy = vyNewOther;
      }
    }
  }
}
