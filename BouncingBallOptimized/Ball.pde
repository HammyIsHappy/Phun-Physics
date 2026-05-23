// Isaiah Hamblin
// Last Edit: 5/21/2026
// Ball class contains constructor and methods to handle collisions

class Ball {
  int id;

  float x;
  float y;
  float vx;
  float vy;
  int radius;

  // Create new ball at location x, y with velocity vx, vy and a radius
  Ball(int id, float x, float y, float vx, float vy, int radius) {
    this.id = id;
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.radius = radius;
  }

  // Move ball by velocity * dt. Then apply gravity
  void updateVectors(float dt) {
    this.x += this.vx * dt;
    this.y += this.vy * dt;

    // Gravity
    this.vy += 700 * dt;
  }

  // Display the ball at x, y
  void display() {
    ellipse(this.x, this.y, this.radius * 2, this.radius * 2);
  }

  // If the ball's center + radius is outside the screen, clip the ball back in and lose some energy
  void checkWalls() {
    if (this.x + this.radius > width) {
      // Clip ball back in
      this.x = width - this.radius;
      // Energy loss
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

  // Check this ball to nearby tracks
  void checkNearbyTrackCollisions() {
    // Get the ball's cell
    int cx = floor(this.x / cellSize);
    int cy = floor(this.y / cellSize);

    // Check all nearby cells
    for (int gx = cx - 1; gx <= cx + 1; gx++) {
      for (int gy = cy - 1; gy <= cy + 1; gy++) {
        String key = cellKey(gx, gy);

        if (!trackGrid.containsKey(key)) continue;
        
        for (Track t : trackGrid.get(key)) {
          checkTrackCollision(t);
        }
      }
    }
  }
  
  // Handles track collisions
  void checkTrackCollision(Track t) {
    if (t.lengthSquared == 0) return;

    float u = ((this.x - t.xStart) * t.tx + (this.y - t.yStart) * t.ty) / t.lengthSquared;
    u = constrain(u, 0, 1);

    float closestX = t.xStart + u * t.tx;
    float closestY = t.yStart + u * t.ty;

    float dx = this.x - closestX;
    float dy = this.y - closestY;

    float distanceSquared = dx * dx + dy * dy;

    if (distanceSquared <= this.radius * this.radius) {
      float distance = sqrt(distanceSquared);

      if (distance == 0) {
        distance = 0.01;
        dx = -t.ty;
        dy = t.tx;
      }

      float nx = dx / distance;
      float ny = dy / distance;

      float overlap = this.radius - distance;

      this.x += nx * overlap;
      this.y += ny * overlap;

      float speedIntoTrack = this.vx * nx + this.vy * ny;

      if (speedIntoTrack < 0) {
        this.vx -= 1.8 * speedIntoTrack * nx;
        this.vy -= 1.8 * speedIntoTrack * ny;
      }
    }
  }

  // Handles ball collions
  void checkBallCollision(Ball b) {
    float dx = b.x - this.x;
    float dy = b.y - this.y;

    float distanceSquared = dx * dx + dy * dy;
    float minimumDistance = this.radius + b.radius;

    if (distanceSquared <= minimumDistance * minimumDistance) {
      float distance = sqrt(distanceSquared);

      if (distance == 0) {
        distance = 0.01;
        dx = 0.01;
        dy = 0;
      }

      float nx = dx / distance;
      float ny = dy / distance;

      float overlap = minimumDistance - distance;

      this.x -= nx * overlap / 2;
      this.y -= ny * overlap / 2;

      b.x += nx * overlap / 2;
      b.y += ny * overlap / 2;

      float dvx = this.vx - b.vx;
      float dvy = this.vy - b.vy;

      float speed = dvx * nx + dvy * ny;

      if (speed < 0) return;

      float m1 = this.radius * this.radius;
      float m2 = b.radius * b.radius;

      float impulse = (2 * speed) / (m1 + m2);

      this.vx -= impulse * m2 * nx;
      this.vy -= impulse * m2 * ny;

      b.vx += impulse * m1 * nx;
      b.vy += impulse * m1 * ny;
    }
  }
}
