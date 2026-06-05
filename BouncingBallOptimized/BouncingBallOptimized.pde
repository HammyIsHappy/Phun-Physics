// Isaiah Hamblin
// Last Edit: 5/29/2026
// This file serves as the backbone for the project, keeping track of spacial grids, creating tracks, buttons, adding balls, graphics, etc.

import java.util.*;

int lastTime;
boolean paused = false;
boolean makingTrack = false;
boolean erasing = false;
float trackX, trackY;

boolean menuOpen = false;
boolean wasPausedBeforeMenu = false;

boolean debug = false;

PImage gearIcon;

int cellSize = 64;
int nextBallId = 0;

PVector globalAcc;
float wallBounce = 0.75;
float elasticity = 1.0;

ArrayList<Ball> balls = new ArrayList<Ball>();
ArrayList<Track> tracks = new ArrayList<Track>();
int ballCount = 0;
int trackCount = 0;

// Use one drawing to display all tracks rather than rendering each track each frame
PGraphics trackLayer;

HashMap<Integer, ArrayList<Ball>> ballGrid = new HashMap<Integer, ArrayList<Ball>>();
HashMap<Integer, ArrayList<Track>> trackGrid = new HashMap<Integer, ArrayList<Track>>();

// setup() runs when the program first starts
void setup() {
  // Sets size, background color, framerate, gravity, and initilizes lastTime
  size(800, 600, P2D);
  surface.setResizable(true);
  background(255);
  frameRate(60);
  globalAcc = new PVector(0, 700);
  // How many miliseconds the program has run for
  lastTime = millis();
  
  gearIcon = loadImage("gear.png");
  
  // Sets up trackLayer
  trackLayer = createGraphics(width, height);
  trackLayer.beginDraw();
  trackLayer.background(255, 0);
  trackLayer.endDraw();
}

// draw() runs each frame
void draw() {
  // Clear screen
  background(255);
  
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
  
  // Draw buttons
  drawButton(10, 10, 100, 30, "Add Ball");
  drawButton(120, 10, 100, 30, "Clear");
  drawButton(230, 10, 100, 30, paused ? "Resume" : "Pause");
  drawButton(340, 10, 100, 30, erasing ? "Draw" : "Erase");
  
  // Draw gear button
  fill(200);
  rect(width - 46, 10, 36, 36);
  image(gearIcon, width - 40, 16, 24, 24);
  fill(0);
  
  // Calculate the time that has passed sense last call of draw()
  int currentTime = millis();
  float dt = (currentTime - lastTime) / 1000.0;
  lastTime = currentTime;
  // If lag prevent large jumps in time
  dt = min(dt, 0.03);

  // Debug menu
  if (debug) {
    trackCount = countTracks();
    fill(0, 255, 128);
    text("Ball Count: " + ballCount, 50, height - 20);
    text("Track Count: " + trackCount, 50, height - 40);
  }
  fill(0);

  if (!paused) {
    // Calculate how many sub-frames we need and cap it at 6
    // Don't allow frames where a ball moves more than 5 pixels because that is the smallest possible radius
    int steps = ceil(maxBallSpeed() * dt / 5.0);
    steps = constrain(steps, 1, 6);
    
    float subDt = dt / steps;
    
    // Do this for every sub-frame
    for (int i = 0; i < steps; i++) {
      for (Ball b : balls) {
        b.updateVectors(subDt);
        b.checkWalls();
      }
    
      buildBallGrid();
    
      for (Ball b : balls) {
        b.checkNearbyTrackCollisions();
      }
    
      checkNearbyBallCollisions();
    }
    
    
    // Legacy Code: runs faster but balls would sometimes clip through walls
    /*
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
    */
  }


  
  // Display something else if menu is open
  if (menuOpen) {
    // Dim background
    fill(0, 128);
    rect(0, 0, width, height);
    
    // Menu buttons
    drawButton(300, 200, 200, 40, "Gravity: " + (int) (globalAcc.y / 7) + "%");
    drawButton(250, 200, 40, 40, "-");
    drawButton(510, 200, 40, 40, "+");
    drawButton(300, 250, 200, 40, "Wind: " + (int) (globalAcc.x / 7) + "%");
    drawButton(250, 250, 40, 40, "-");
    drawButton(510, 250, 40, 40, "+");
    drawButton(300, 300, 200, 40, "Wall Bounce: " + (int) (wallBounce * 100) + "%");
    drawButton(250, 300, 40, 40, "-");
    drawButton(510, 300, 40, 40, "+");
    drawButton(300, 350, 200, 40, "Ball Elasticity: " + (int) (elasticity * 100) + "%");
    drawButton(250, 350, 40, 40, "-");
    drawButton(510, 350, 40, 40, "+");
    drawButton(300, 400, 200, 40, "Resume");
    
    // Display energy warning
    if (elasticity > 1 || wallBounce == 1) {
        fill(0);
        textAlign(CENTER, CENTER);
        text("Warning - Energy will explode", 400, 180);
    }
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
  if (!menuOpen) {
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
      ballCount++;
      return;
    }
    
    // Toggles erasing mode if over button
    else if (overButton(340, 10, 100, 30)) {
      erasing = !erasing;
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
      ballCount = 0;
      trackCount = 0;
      return;
    }
  
    // Pauses or resumes if over pause button
    else if (overButton(230, 10, 100, 30)) {
      paused = !paused;
      return;
    }
    
    // Opens menu
    else if (overButton(width - 46, 10 , 36, 36)) {
      wasPausedBeforeMenu = paused;
      paused = true;
      menuOpen = true;
      return;
    }
  
    // Start making a track
    else if (!erasing) {
      makingTrack = true;
      trackX = mouseX;
      trackY = mouseY;
    }
  }
  else {
    // Menu buttons
    
    // Gravity
    if (overButton(250, 200, 40, 40) && globalAcc.y > -1400) {
      globalAcc.y -= 350;
    }
    if (overButton(510, 200, 40, 40) && globalAcc.y < 1400) {
      globalAcc.y += 350;
    }
    
    // Wind
    if (overButton(250, 250, 40, 40) && globalAcc.x > -1400) {
      globalAcc.x -= 350;
    }
    if (overButton(510, 250, 40, 40) && globalAcc.x < 1400) {
      globalAcc.x += 350;
    }
    
    // Wall Bounce
    if (overButton(250, 300, 40, 40) && wallBounce > 0) {
      wallBounce -= 0.25;
    }
    if (overButton(510, 300, 40, 40) && wallBounce < 1) {
      wallBounce += 0.25;
    }
    
    // Elasticity between balls
    if (overButton(250, 350, 40, 40) && elasticity > 0) {
      elasticity -= 0.25;
    }
    if (overButton(510, 350, 40, 40) && elasticity < 2) {
      elasticity += 0.25;
    }
         
    // Resume
    if (overButton(300, 400, 200, 40)) {
      menuOpen = false;
      paused = wasPausedBeforeMenu;
      return;
    }
  }
}

// Runs whenever the mouse is dragged
void mouseDragged() {
  if (!menuOpen) {
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
    
    if (erasing) {
      // Keep track of which track segments to remove
      HashSet<Track> toRemove = new HashSet<Track>();
      
      int cx = floor(mouseX / cellSize);
      int cy = floor(mouseY / cellSize);
  
      int curKey = cellKey(cx, cy);
      
      // Mark all the tracks in this cell to remove them
      if (trackGrid.keySet().contains(curKey)) {
        for (Track t : trackGrid.get(curKey)) {
          toRemove.add(t);
        }
        // Remove tracks and redraw track grid
        tracks.removeAll(toRemove);
        rebuildTrackGrid();
      }
    }
  }
}

// Runs when mouse is released
void mouseReleased() {
  // Stop making a track
  makingTrack = false;
}

// Returns a cell key
int cellKey(int cx, int cy) {
  return (cx * 100) + cy;
}

// Creates the spacial grid for the balls
void buildBallGrid() {
  ballGrid.clear();

  for (Ball b : balls) {
    // Get a cell key for the ball
    int cx = floor(b.pos.x / cellSize);
    int cy = floor(b.pos.y / cellSize);
    int key = cellKey(cx, cy);

    // Use a HashMap to keep track of which cell balls are in
    if (!ballGrid.containsKey(key)) {
      ballGrid.put(key, new ArrayList<Ball>());
    }
    ballGrid.get(key).add(b);
  }
}

// Runs when a key is pressed
void keyPressed() {
  if (key == 'd' || key == 'D') {
    debug = !debug;
  }
}

// Counts how many tracks there are
int countTracks() {
  int count = 0;
  for (Track t : tracks) {
    if (t != null) {
      count++;
    }
  }
  return count;
}

// Adds a track to the spacial grid
void addTrackToGrid(Track t) {
  // Figure out the min and max x and y of this track
  int minCX = floor(min(t.start.x, t.end.x) / cellSize);
  int maxCX = floor(max(t.start.x, t.end.x) / cellSize);
  int minCY = floor(min(t.start.y, t.end.y) / cellSize);
  int maxCY = floor(max(t.start.y, t.end.y) / cellSize);

  // Add the track to each cell it is in, this works because tracks are 4 pixels max
  // Cells are 64 pixels wide, this code would need to be updated if cell size was decreased or if track sizes were increased
  for (int cx = minCX; cx <= maxCX; cx++) {
    for (int cy = minCY; cy <= maxCY; cy++) {
      int key = cellKey(cx, cy);
      
      // Use a HashMap to keep track of which cells the track is in
      if (!trackGrid.containsKey(key)) {
        trackGrid.put(key, new ArrayList<Track>());
      }
      trackGrid.get(key).add(t);
    }
  }
}

// Rebuild the track grid and PGraphics layer
void rebuildTrackGrid() {
  // Clear and repopulate the spacial grid
  trackGrid.clear();
  for (Track t : tracks) {
    addTrackToGrid(t);
  }
  
  // Clear and redraw the PGraphic
  trackLayer.beginDraw();
  trackLayer.clear();
  for (Track t : tracks) {
    trackLayer.line(
      t.start.x,
      t.start.y,
      t.end.x,
      t.end.y
    );
  }
  trackLayer.endDraw();
}

// Calculates collisions between balls
void checkNearbyBallCollisions() {
  for (Ball b : balls) {
    // Figure out which cell we are in
    int cx = floor(b.pos.x / cellSize);
    int cy = floor(b.pos.y / cellSize);

    // Check the surrounding cells
    for (int gx = cx - 1; gx <= cx + 1; gx++) {
      for (int gy = cy - 1; gy <= cy + 1; gy++) {
        int key = cellKey(gx, gy);

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

// Calculates the speed of the fatest ball
float maxBallSpeed() {
  float max = 0;
  for (Ball b : balls) {
    max = Math.max(max, b.vel.mag());
  }
  return max;
}
