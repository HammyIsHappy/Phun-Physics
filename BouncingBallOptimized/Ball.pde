// Isaiah Hamblin
// Last Edit: 6/5/2026
// Ball class contains constructor and methods to handle collisions

class Ball {
  int id;

  PVector pos;
  PVector vel;
  int radius;

  // Create new ball at location x, y with velocity vx, vy and a radius
  Ball(int id, float x, float y, float vx, float vy, int radius) {
    this.id = id;
    this.pos = new PVector(x, y);
    this.vel = new PVector(vx, vy);
    this.radius = radius;
  }

  // Move ball by velocity * dt. Then apply gravity
  void updateVectors(float dt) {
    pos.add(PVector.mult(vel, dt));
    vel.add(PVector.mult(globalAcc, dt));
  }

  // Display the ball at x, y
  void display() {
    ellipse(pos.x, pos.y, radius * 2, radius * 2);
  }

  // If the ball's center + radius is outside the screen, clip the ball back in and lose some energy
  void checkWalls() {
    if (pos.x + radius > width) {
      // Clip ball back in
      pos.x = width - radius;
      // Energy loss
      vel.x *= -wallBounce;
    }

    if (pos.x - radius < 0) {
      pos.x = radius;
      vel.x *= -wallBounce;
    }

    if (pos.y + radius > height) {
      pos.y = height - radius;
      vel.y *= -wallBounce;
    }

    if (pos.y - radius < 0) {
      pos.y = radius;
      vel.y *= -wallBounce;
    }
  }

  // Check this ball to nearby tracks
  void checkNearbyTrackCollisions() {
    // Get the ball's cell
    int cx = floor(pos.x / cellSize);
    int cy = floor(pos.y / cellSize);

    // Check all nearby cells
    for (int gx = cx - 1; gx <= cx + 1; gx++) {
      for (int gy = cy - 1; gy <= cy + 1; gy++) {
        int key = cellKey(gx, gy);

        if (!trackGrid.containsKey(key)) continue;
        
        for (Track t : trackGrid.get(key)) {
          checkTrackCollision(t);
        }
      }
    }
  }
  
  // Handles track collisions
  void checkTrackCollision(Track t) {
    // If a track with length 0 somehow exists just ignore it
    if (t.lengthSquared == 0) return;
  
    PVector trackVector = PVector.sub(t.end, t.start);
  
    float u = PVector.sub(pos, t.start).dot(trackVector) / t.lengthSquared;
    u = constrain(u, 0, 1);
  
    PVector closestPoint = PVector.add(t.start, PVector.mult(trackVector, u));
  
    PVector delta = PVector.sub(pos, closestPoint);
  
    float distanceSquared = delta.magSq();
  
    if (distanceSquared <= radius * radius) {
      float distance = sqrt(distanceSquared);
  
      if (distance == 0) {
        distance = 0.01;
        delta.set(-trackVector.y, trackVector.x);
      }
  
      PVector normal = delta.copy();
      normal.div(distance);
  
      float overlap = radius - distance;
  
      pos.add(PVector.mult(normal, overlap));
  
      float speedIntoTrack = vel.dot(normal);
  
      if (speedIntoTrack < 0) {
        PVector bounce = PVector.mult(normal, 1.8 * speedIntoTrack);
        vel.sub(bounce);
      }
    }
  }
  
  // Handles ball collisions
  void checkBallCollision(Ball b) {
    PVector delta = PVector.sub(b.pos, pos);
  
    float distanceSquared = delta.magSq();
    float minimumDistance = radius + b.radius;
  
    if (distanceSquared <= minimumDistance * minimumDistance) {
      float distance = sqrt(distanceSquared);
  
      if (distance == 0) {
        delta.set(0.01, 0);
        distance = 0.01;
      }
  
      PVector normal = delta.copy();
      normal.div(distance);
  
      float overlap = minimumDistance - distance;
  
      PVector separation = PVector.mult(normal, overlap / 2);
  
      pos.sub(separation);
      b.pos.add(separation);
  
      PVector relativeVelocity = PVector.sub(vel, b.vel);
  
      float speed = relativeVelocity.dot(normal);
  
      if (speed < 0) return;
  
      float m1 = radius * radius;
      float m2 = b.radius * b.radius;
  
      float impulse = ((1 + elasticity) * speed) / (m1 + m2);
  
      PVector impulseVector = PVector.mult(normal, impulse);
  
      vel.sub(PVector.mult(impulseVector, m2));
      b.vel.add(PVector.mult(impulseVector, m1));
    }
  }
}
