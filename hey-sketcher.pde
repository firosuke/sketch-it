// Hey Sketcher!

// Start drawing with your mouse. Press H to show key commands.


// Key command summary
String helpMessage = "Up/Down: Stroke palette (try it)\n"
  + "Left/Right: Background wash\n"
  + "[ / ]: Scale\n"
  + "-/+: Thickness\n"
  + "Z/X: Symmetry (try it)\n"
  + "Enter: Replay (try it)\n"
  + "P: Toggle replay pauses\n"
  + "L/S: Load/save\n"
  + "C: Clear\n"
  + "U: Undo one stroke\n"
  + "D: Debug to console\n"
  + "H: Show/hide help\n";
// TODO: Store bindings and descriptions in a data structure


// Flags
boolean needRedraw = false;
boolean ultraFast = false;
boolean mouseMoved = false;
boolean showHelp = false;
boolean fastMode = false;
boolean replay = false;


// Record of user activity
JSONArray record = new JSONArray();
int recordCount = 1;
int lineCount; // how many lines have been drawn (since replay began, or since the beginning)
int strokes = 0; // a stroke is a series of connected line segments
int lastX, lastY;
int lastJoined = 0;


// Replay
int replayStart;
int nextReplayFrame = 0, nextReplayX, nextReplayY, nextReplayJoinToNext;
int lastReplayX, lastReplayY, lastReplayJoinToNext;
int nextReplayRecordIndex = 0;
int framecountAtResize; // Draw background after a delay


// Colors
color white = #FFFFFF, black = 0;
float drawColorVar1 = 0.005, drawColorVar2 = 3, drawColorVar3 = 1;
int drawColorOffset = 125;
float bgColorVar1 = 0.002, bgColorVar2 = 0.002, bgColorVar3 = 1;
int bgColorOffset = 200;
int seedX = 0, seedY = 0; // X used for BG, and then re-initialised using Y for FG


// Display parameters
int scale = 100;
int symmetry = 3;
int vertexSize = 5;
int strokeWeight = 20;
int oldWidth, oldHeight;
PImage background;


void setup() {
 
 JSONObject o = new JSONObject();
 o.setInt("Symmetry", symmetry);
 o.setInt("SeedX", seedX);
 o.setInt("SeedY", seedY);
 o.setInt("Scale", scale);
 o.setInt("StrokeWeight", strokeWeight);
 record.setJSONObject(0, o);
 oldWidth = 600;
 oldHeight = 600;
 size(600, 600);
 background = createImage(width, height, ARGB);
 surface.setTitle("Hey Sketcher! (Press H for help)");
 surface.setResizable(true);
 strokeWeight(strokeWeight);
 noiseDetail(4, 0.6);
 drawBackground();
}


void drawBackground() {
  loadPixels();
  noiseSeed(seedX);
  for (int i = 0; i < width; i++)
    for (int j = 0; j < height; j++) {
      float r, g, b;
      r = getBGColor(i, j, 1);
      g = getBGColor(i, j, 2);
      b = getBGColor(i, j, 3);
      pixels[i + width * j] = color(r, g, b);
    }
  updatePixels();
  noiseSeed(seedY);
}


void mousePressed() {
  lastX = mouseX;
  lastY = mouseY;
}


void addEntry(int joined) {
  JSONObject entry = new JSONObject();
  entry.setInt("Frame", frameCount - replayStart); // In case we are adding after a replay...
  entry.setInt("X", lastX);
  entry.setInt("Y", lastY);
  entry.setInt("Joined", joined);
  entry.setInt("Stroke", strokes + 1); // Only included for debugging, can be removed
  record.setJSONObject(recordCount, entry);
  recordCount++;
  if (joined == 0) {
    strokes++;
  }
}


void drawLine(float x1, float y1, float x2, float y2) {
  lineCount++;
  x1 *= scale / 100.0;
  x2 *= scale / 100.0;
  y1 *= scale / 100.0;
  y2 *= scale / 100.0;
  stroke(getDrawColor(lineCount, strokes, 1),
            getDrawColor(lineCount, strokes, 2),
            getDrawColor(lineCount, strokes, 3));
  float angle = 0;
  for (int i = 0; i < symmetry; i++) {
    float x12 = cos(angle) * x1 - sin(angle) * y1 + width/2;
    float x22 = cos(angle) * x2 - sin(angle) * y2 + width/2;
    float y12 = sin(angle) * x1 + cos(angle) * y1 + height/2;
    float y22 = sin(angle) * x2 + cos(angle) * y2 + height/2;
    line(x12, y12, x22, y22);
    angle += 2 * PI / symmetry;
    }
}


void addSegment(int joined) {
    // Need to "standardise" X and Y by making them relative to
    // screen centre, in case the animation is replayed in a window
    // of different size
    int newX = (mouseX - width / 2) * 100 / scale;
    int newY = (mouseY - height / 2) * 100 / scale;
    if (lastJoined == 1)
      drawLine(lastX, lastY, newX, newY);
    lastX = newX;
    lastY = newY;
    lastJoined = joined;
    addEntry(joined);
}


void mouseDragged() {
  mouseMoved = true;
  if (!replay)
    addSegment(1);
}


void mouseReleased() {
  if (mouseMoved)
    if (!replay)
      addSegment(0);
  mouseMoved = false;
}


void fileLoad(File selection) {
  if (selection != null) {
     record = loadJSONArray(selection.getAbsolutePath());
     JSONObject nextReplayRecord = record.getJSONObject(0);    
    seedX = nextReplayRecord.getInt("SeedX");
    seedY = nextReplayRecord.getInt("SeedY");
    strokeWeight = nextReplayRecord.getInt("StrokeWeight");
    symmetry = nextReplayRecord.getInt("Symmetry");
    scale = nextReplayRecord.getInt("Scale");
    recordCount = record.size();
    strokeWeight(strokeWeight);
    ultraFast = true;
    triggerReplay();
  }
}


void fileSave(File selection) {
    if (selection != null) {
      saveJSONArray(record, selection.getAbsolutePath());
    }
}


void keyPressed() {
  // All keypresses cause a fast redraw of all user strokes
  ultraFast = true;
  replay = false;
  
  key = Character.toUpperCase(key);
  if (keyCode == UP)
    record.getJSONObject(0).setInt("SeedY", ++seedY);
  else if (keyCode == DOWN)
    record.getJSONObject(0).setInt("SeedY", --seedY);
  else if (keyCode == LEFT)
    record.getJSONObject(0).setInt("SeedX", ++seedX);
  else if (keyCode == RIGHT)
    record.getJSONObject(0).setInt("SeedX", --seedX);
   else if (key == 'H')
     showHelp = !showHelp;
  else if (key == '[') {
    scale -= 10;
    record.getJSONObject(0).setInt("Scale", scale);
  } else if (key == ']') {
    scale += 10;
    record.getJSONObject(0).setInt("Scale", scale);
  }
  else if (key == 'D') {
    println(record);
    //saveStrings("debug.txt", record.toString().split("\n"));
    //ultraFast = false;
  }
  else if (key == '-' && strokeWeight > 1)
    record.getJSONObject(0).setInt("StrokeWeight", --strokeWeight);
  else if ((key == '+' || key == '=') && strokeWeight < 64)
    record.getJSONObject(0).setInt("StrokeWeight", ++strokeWeight);
  else if ((key == 'U') && record.size() > 1) {
    int i;
    for (i = record.size() - 1; i > 0; i--) {
      if(record.getJSONObject(i).getInt("Stroke") <= strokes - 1)
        break;
      record.remove(i);
    }
    recordCount = i + 1;
    strokes--;
  }
  else if (key == 'Z' && symmetry < 32)
    record.getJSONObject(0).setInt("Symmetry", ++symmetry);
  else if (key == 'X' && symmetry > 1)
    record.getJSONObject(0).setInt("Symmetry", --symmetry);
  else if (key == 'L') {
    selectInput("Select a file to load:", "fileLoad");
  }  
  else if (key == 'S') {
    selectOutput("Select a path to save to", "fileSave", new File("record." + Integer.toString(day()) + "-" + Integer.toString(month()) + "-" + Integer.toString(year()) + "." + Integer.toString(hour()) + Integer.toString(minute()) + Integer.toString(second()) + ".json"));
  }
  else if (key == 'C') {
    record = new JSONArray();
    recordCount = 1;
    lineCount = 0;
    strokes = 0;
    lastX = 0;
    lastY = 0;
    lastJoined = 0;
  }
  else if (key == 'P') {
    fastMode = !fastMode;
    ultraFast = false;
  }
  else
    ultraFast = false;
 
  if (ultraFast || (keyCode == ENTER || keyCode == RETURN)) {
    triggerReplay();
  }
}


void triggerReplay() {
  drawBackground();
  if (record.size() <= 1)
    return;
  replayStart = frameCount - record.getJSONObject(1).getInt("Frame");
  lineCount = 0;
  strokeWeight(strokeWeight);    
  JSONObject nextReplayRecord = record.getJSONObject(1);
  nextReplayFrame = nextReplayRecord.getInt("Frame");
  nextReplayX = nextReplayRecord.getInt("X");
  nextReplayY = nextReplayRecord.getInt("Y");
  nextReplayJoinToNext = nextReplayRecord.getInt("Joined");
  nextReplayRecordIndex = 2;
  lastReplayJoinToNext = 0;
  strokes = -1;
  replay = true;
}


float getBGColor(int x, int y, int z) {
  return bgColorOffset + (255 - bgColorOffset) * noise(x * bgColorVar1, y * bgColorVar2, z * bgColorVar3);
}


float getDrawColor(int x, int y, int z) {
  return drawColorOffset + (255 - drawColorOffset) * noise(x * drawColorVar1, y * drawColorVar2, z * drawColorVar3);
}


void draw() { 
  if (showHelp) {
    fill(128, 96, 128);
    textSize(20);
    text(helpMessage, 15, 30);
  }
  if (oldWidth != width || oldHeight != height) {
    replay = false;
    needRedraw = true;
    framecountAtResize = frameCount;
    oldWidth = width;
    oldHeight = height;
  }
  if (needRedraw && framecountAtResize < frameCount - 10) {
    needRedraw = false;
    ultraFast = true;
    triggerReplay();
   }
  while(replay) {
    if (replay && (fastMode || ultraFast || nextReplayFrame <= frameCount - replayStart)) {
      // We've reached (or passed) the "next" frame where something is drawn.
      // Draw a line to nextreplayframe if there was a previous frame and
      // if it is really the previous one (otherwise there was a pause).
      // Either way, get the next replay frame.
      if (lastReplayJoinToNext == 1) {
        drawLine(lastReplayX, lastReplayY, nextReplayX, nextReplayY);
      } else {
        strokes++;
      }
      lastReplayX = nextReplayX;
      lastReplayY = nextReplayY;
      lastReplayJoinToNext = nextReplayJoinToNext;
     
      if (nextReplayRecordIndex == record.size()) {
        strokes++;
        replay = false;
        if (fastMode)
          // If we were fast-forwarding, artificially "fix" the perceived start time
          // in case the user tries to add more strokes
          replayStart = frameCount - nextReplayFrame;
        ultraFast = false;
      } else {
        JSONObject nextReplayRecord = record.getJSONObject(nextReplayRecordIndex);
        //println("next:", record.getJSONObject(nextReplayRecordIndex));
        nextReplayFrame = nextReplayRecord.getInt("Frame");
        nextReplayX = nextReplayRecord.getInt("X");
        nextReplayY = nextReplayRecord.getInt("Y");
        nextReplayJoinToNext = nextReplayRecord.getInt("Joined");
        nextReplayRecordIndex++;
      }
    }
    if (!ultraFast)
      break;
  }
}
