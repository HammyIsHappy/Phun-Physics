import java.util.*;

boolean paused = false;
ArrayList<Ball> balls = new ArrayList<Ball>();

void setup() {
  size(800, 800);
  background(255);
  //smooth(8);
  frameRate(60);
}

void draw() {
  background(255);

  drawButton(10, 10, 100, 30, "Add Ball");
  drawButton(120, 10, 100, 30, "Clear");
  drawButton(230, 10, 100, 30, paused ? "Resume" : "Pause");

  double dt = 1.0 / 60.0;

  if (!paused) {
    // Update positions and wall collisions
    for (Ball b : balls) {
      b.updateVectors(dt);
      b.checkWalls();
    }

    // Check ball-to-ball collisions
    for (Ball b : balls) {
      b.checkCollision();
    }
  }

  // Display the balls
  for (Ball b : balls) {
    b.display();
  }
}

// Draws the buttons
void drawButton(int x, int y, int w, int h, String label) {
  fill(200);
  rect(x, y, w, h);

  fill(0);
  textAlign(CENTER, CENTER);
  text(label, x + w / 2, y + h / 2);
}

// Checks if mouse is over a button
boolean overButton(int x, int y, int w, int h) {
  return mouseX > x && mouseX < x + w &&
         mouseY > y && mouseY < y + h;
}

// What to do when mouse is pressed
void mousePressed() {
  
  // If over the add ball button
  if (overButton(10, 10, 100, 30)) {
    balls.add(new Ball(
      (float)(Math.random() * 700 + 50),
      (float)(Math.random() * 700 + 50),
      (float)(Math.random() * 300 - 150),
      (float)(Math.random() * 300 - 150),
      (int)(Math.random() * 15 + 5)
    ));
    return;
  }

  // If over the clear button
  if (overButton(120, 10, 100, 30)) {
    balls.clear();
    return;
  }

  // If over the pause button
  if (overButton(230, 10, 100, 30)) {
    paused = !paused;
    return;
  }
}


// Ball class
class Ball {
  float x;
  float y;
  float vx;
  float vy;
  int radius;

  // Constructor
  Ball(float x, float y, float vx, float vy, int radius) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.radius = radius;
  }

  // Updates position and applies gravity
  void updateVectors(double dt) {
    this.x += this.vx * dt;
    this.y += this.vy * dt;

    // Gravity
    this.vy += 700 * dt;
  }

  // Draws the ball
  void display() {
    ellipse(this.x, this.y, this.radius * 2, this.radius * 2);
  }

  // Handles bouncing off the walls
  // Clips the balls out of the wall and reduces speed by 10%
  void checkWalls() {
    if (this.x + this.radius > width) {
      this.x = width - this.radius;
      this.vx *= -0.9;
    }

    if (this.x - this.radius < 0) {
      this.x = this.radius;
      this.vx *= -0.9;
    }

    if (this.y + this.radius > height) {
      this.y = height - this.radius;
      this.vy *= -0.9;
    }

    if (this.y - this.radius < 0) {
      this.y = this.radius;
      this.vy *= -0.9;
    }
  }

  // Handles collisions between this ball and every other ball
  void checkCollision() {
    for (Ball b : balls) {
      if (b == this) {
        continue;
      }

      float dx = b.x - this.x;
      float dy = b.y - this.y;

      float distanceSquared = dx * dx + dy * dy;
      float minimumDistance = this.radius + b.radius;

      if (distanceSquared <= minimumDistance * minimumDistance) {
        float distance = sqrt(distanceSquared);

        // Prevents division by zero if two balls are exactly on top of each other
        if (distance == 0) {
          distance = 0.01;
          dx = 0.01;
          dy = 0;
        }

        // Normal vector: direction from this ball to the other ball
        float nx = dx / distance;
        float ny = dy / distance;

        // Push balls apart so they do not stay stuck inside each other
        float overlap = minimumDistance - distance;

        this.x -= nx * overlap / 2;
        this.y -= ny * overlap / 2;

        b.x += nx * overlap / 2;
        b.y += ny * overlap / 2;

        // Difference in velocity
        float dvx = this.vx - b.vx;
        float dvy = this.vy - b.vy;

        // Speed along the collision direction
        float speed = dvx * nx + dvy * ny;

        // If speed is negative, the balls are already moving apart
        if (speed < 0) {
          continue;
        }

        // Use radius squared as mass because this is a 2D simulation
        float m1 = this.radius * this.radius;
        float m2 = b.radius * b.radius;

        // Elastic collision impulse
        float impulse = (2 * speed) / (m1 + m2);

        this.vx -= impulse * m2 * nx;
        this.vy -= impulse * m2 * ny;

        b.vx += impulse * m1 * nx;
        b.vy += impulse * m1 * ny;
      }
    }
  }
}
