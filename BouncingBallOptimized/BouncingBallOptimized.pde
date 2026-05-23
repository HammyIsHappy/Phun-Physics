// Isaiah Hamblin
// Last Edit: 5/22/2026
// This file serves as the backbone for the project, keeping track of spacial grids, creating tracks, buttons, adding balls, graphics, etc.

import java.util.*;

int lastTime;
boolean paused = false;
boolean makingTrack = false;
float trackX, trackY;

int cellSize = 64;
int nextBallId = 0;

ArrayList<Ball> balls = new ArrayList<Ball>();
ArrayList<Track> tracks = new ArrayList<Track>();

// Use one drawing to display all tracks rather than rendering each track each frame
PGraphics trackLayer;

HashMap<String, ArrayList<Ball>> ballGrid = new HashMap<String, ArrayList<Ball>>();
HashMap<String, ArrayList<Track>> trackGrid = new HashMap<String, ArrayList<Track>>();

// setup() runs when the program first starts
void setup() {
  // Sets size, background color, framerate, and initilizes lastTime
  size(800, 600, P2D);
  background(255);
  frameRate(60);
  // How many miliseconds the program has run for
  lastTime = millis();
  
  // Sets up trackLayer
  trackLayer = createGraphics(width, height);
  trackLayer.beginDraw();
  trackLayer.background(255, 0);
  trackLayer.endDraw();
}

// draw() runs each frame
void draw() {
  
  // Clear screen and add buttons
  background(255);
  drawButton(10, 10, 100, 30, "Add Ball");
  drawButton(120, 10, 100, 30, "Clear");
  drawButton(230, 10, 100, 30, paused ? "Resume" : "Pause");

  // Calculate the time that has passed sense last call of draw()
  int currentTime = millis();
  float dt = (currentTime - lastTime) / 1000.0;
  lastTime = currentTime;
  // If lag prevent large jumps in time
  dt = min(dt, 0.03);

  if (!paused) {
    // Update ball locations
    for (Ball b : balls) {
      b.updateVectors(dt);
      b.checkWalls();
    }

    // Build spacial grid to optimize collisions
    buildBallGrid();

    // Check balls for track collisions
    for (Ball b : balls) {
      b.checkNearbyTrackCollisions();
    }

    // Check for ball collisions
    checkNearbyBallCollisions();
  }

  // Display the tracks
  image(trackLayer, 0, 0);

  // Display the balls
  for (Ball b : balls) {
    b.display();
  }

  // Show a line of where the track will go as it is being made
  if (makingTrack) {
    line(trackX, trackY, mouseX, mouseY);
  }
}

// Helper method, makes a button
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

// Runs when the mouse is pressed
void mousePressed() {
  // Makes a new ball if over add ball button
  if (overButton(10, 10, 100, 30)) {
    // Random start pos, velocity, and radius
    balls.add(new Ball(
      nextBallId++,
      (float)(Math.random() * 700 + 50),
      (float)(Math.random() * 500 + 50),
      (float)(Math.random() * 300 - 150),
      (float)(Math.random() * 300 - 150),
      (int)(Math.random() * 15 + 5)
    ));
    return;
  }

  // Clears everything if over clear button
  else if (overButton(120, 10, 100, 30)) {
    balls.clear();
    tracks.clear();
    ballGrid.clear();
    trackGrid.clear();
    trackLayer.beginDraw();
    trackLayer.clear();
    trackLayer.endDraw();
    nextBallId = 0;
    return;
  }

  // Pauses or resumes if over pause button
  else if (overButton(230, 10, 100, 30)) {
    paused = !paused;
    return;
  }

  // Start making a track
  else {
    makingTrack = true;
    trackX = mouseX;
    trackY = mouseY;
  }
}

// Runs whenever the mouse is dragged
void mouseDragged() {
  if (makingTrack) {
    // Figure out how long the track currently is
    float dx = mouseX - trackX;
    float dy = mouseY - trackY;

    // Make the track if it is longer than 4 pixels (using pythag!)
    if (dx * dx + dy * dy >= 4 * 4){
      Track t = new Track(trackX, trackY, mouseX, mouseY);
      tracks.add(t);
      addTrackToGrid(t);

      // Start drawing a new track
      trackLayer.beginDraw();
      trackLayer.line(trackX, trackY, mouseX, mouseY);
      trackLayer.endDraw();

      trackX = mouseX;
      trackY = mouseY;
    }
  }
}

// Runs when mouse is released
void mouseReleased() {
  // Stop making a track
  makingTrack = false;
}

// Returns a cell key
String cellKey(int cx, int cy) {
  return cx + "," + cy;
}

// Creates the spacial grid for the balls
void buildBallGrid() {
  ballGrid.clear();

  for (Ball b : balls) {
    // Get a cell key for the ball
    int cx = floor(b.x / cellSize);
    int cy = floor(b.y / cellSize);
    String key = cellKey(cx, cy);

    // Use a HashMap to keep track of which cell balls are in
    if (!ballGrid.containsKey(key)) {
      ballGrid.put(key, new ArrayList<Ball>());
    }
    ballGrid.get(key).add(b);
  }
}

// Adds a track to the spacial grid
void addTrackToGrid(Track t) {
  // Figure out the min and max x and y of this track
  int minCX = floor(min(t.xStart, t.xEnd) / cellSize);
  int maxCX = floor(max(t.xStart, t.xEnd) / cellSize);
  int minCY = floor(min(t.yStart, t.yEnd) / cellSize);
  int maxCY = floor(max(t.yStart, t.yEnd) / cellSize);

  // Add the track to each cell it is in, this works because tracks are 4 pixels max
  // Cells are 64 pixels wide, this code would need to be updated if cell size was decreased or if track sizes were increased
  for (int cx = minCX; cx <= maxCX; cx++) {
    for (int cy = minCY; cy <= maxCY; cy++) {
      String key = cellKey(cx, cy);
      
      // Use a HashMap to keep track of which cells the track is in
      if (!trackGrid.containsKey(key)) {
        trackGrid.put(key, new ArrayList<Track>());
      }
      trackGrid.get(key).add(t);
    }
  }
}

// Calculates collisions between balls
void checkNearbyBallCollisions() {
  for (Ball b : balls) {
    // Figure out which cell we are in
    int cx = floor(b.x / cellSize);
    int cy = floor(b.y / cellSize);

    // Check the surrounding cells
    for (int gx = cx - 1; gx <= cx + 1; gx++) {
      for (int gy = cy - 1; gy <= cy + 1; gy++) {
        String key = cellKey(gx, gy);

        if (!ballGrid.containsKey(key)) continue;
        
        // Check the other balls in this grid
        for (Ball other : ballGrid.get(key)) {
          if (other.id <= b.id) continue;
          // Calculates collisions, method in Ball class
          b.checkBallCollision(other);
        }
      }
    }
  }
}
