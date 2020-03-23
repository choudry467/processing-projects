ArrayList<Ball> balls =  new ArrayList<Ball>();
int infected = 1;
int uninfected = 199;
int recovered = 0;

ArrayList<Column> cols = new ArrayList<Column>();
// position on screen where the next graph column will go
int leftCol = 110;

// counts number of frames, used to limit number of columns that are drawn
int columnCounter = 0;

void setup() {
  size(640, 360);
  for (int i = 0; i < 200; i++) {
    balls.add(new Ball(random(width), random(60, height), 5.0, getIsInfected(i), getIsSocialDistancing(i)));
  }
}

State getIsInfected(int i) {
  return i == 0 ? State.INFECTED : State.UNINFECTED;
}

boolean getIsSocialDistancing(int i) {
  return floor(random(0, 8)) != 0 && i != 0;
}

void draw() {
  background(51);

  for (Ball b : balls) {
    b.update();
    b.display();
    b.checkBoundaryCollision();
  }

  drawStats();
  
  // only draw new parts of the graph every 10 frames so that the screen doesn't fill up too quickly
  if (columnCounter % 10 == 0) {
    cols.add(new Column());
    leftCol += 1;
  }
  columnCounter++;
  for (Column c : cols) {
    c.display();
  }
  
  
  for (int i = 0; i < balls.size(); i++) { //<>//
    for (int j = i + 1; j < balls.size(); j++) {
      balls.get(i).checkCollision(balls.get(j));
    }
  }
}

void drawStats() {
  fill(204);
  rect(0, 0, width, 60);
  fill(51);
  text("healthy: " + uninfected, 10, 30);
  text("sick: " + infected, 10, 40);
  text("recovered: " + recovered, 10, 20);
}



enum State {
  UNINFECTED,
  INFECTED,
  RECOVERED
}



class Ball {
  PVector position;
  PVector velocity;

  float radius, m;
  State state;
  // tracks how many days a person has been infected
  // after 1000 days/frames, the person recovers
  int infectedDays;
  boolean isSocialDistancing;

  Ball(float x, float y, float r_, State state, boolean isSocialDistancing) {
    position = new PVector(x, y);
    radius = r_;
    // people who are social distancing should start and stay at 0 velocity,
    // so they need to be heavy to avoid moving due to collisions
    if (isSocialDistancing) {
      m = 1000;
      velocity = new PVector(0, 0);
    } else {
      m = radius*.1;
      velocity = PVector.random2D();
    }
    this.state = state;
    infectedDays = 0;
    this.isSocialDistancing = isSocialDistancing;
  }

  void update() {
    position.add(velocity);
    if (state == State.INFECTED) {
      infectedDays++;
    }
    if (infectedDays == 1000) {
      state = State.RECOVERED;
      infectedDays = 0;
      infected--;
      recovered++;
    }
  }

  void checkBoundaryCollision() {
    if (position.x > width-radius) {
      position.x = width-radius;
      velocity.x *= -1;
    } else if (position.x < radius) {
      position.x = radius;
      velocity.x *= -1;
    } else if (position.y > height-radius) {
      position.y = height-radius;
      velocity.y *= -1;
    } else if (position.y < radius + 60) {
      position.y = radius + 60;
      velocity.y *= -1;
    }
  }
  
  void checkAndSetInfection(Ball other) {
    if (other.state == State.INFECTED  && this.state == State.UNINFECTED) {
      this.state = State.INFECTED;
      infected++;
      uninfected--;
    }
    if (this.state == State.INFECTED && other.state == State.UNINFECTED) {
      other.state = State.INFECTED;
      infected++;
      uninfected--;
    }
  }

  void checkCollision(Ball other) {

    // Get distances between the balls components
    PVector distanceVect = PVector.sub(other.position, position);

    // Calculate magnitude of the vector separating the balls
    float distanceVectMag = distanceVect.mag();

    // Minimum distance before they are touching
    float minDistance = radius + other.radius;

    if (distanceVectMag < minDistance) {
      checkAndSetInfection(other);
      
      float distanceCorrection = (minDistance-distanceVectMag)/2.0; //<>//
      PVector d = distanceVect.copy();
      PVector correctionVector = d.normalize().mult(distanceCorrection);
      other.position.add(correctionVector);
      position.sub(correctionVector);

      // get angle of distanceVect
      float theta  = distanceVect.heading();
      // precalculate trig values
      float sine = sin(theta);
      float cosine = cos(theta);

      /* bTemp will hold rotated ball positions. You 
       just need to worry about bTemp[1] position*/
      PVector[] bTemp = {
        new PVector(), new PVector()
      };

      /* this ball's position is relative to the other
       so you can use the vector between them (bVect) as the 
       reference point in the rotation expressions.
       bTemp[0].position.x and bTemp[0].position.y will initialize
       automatically to 0.0, which is what you want
       since b[1] will rotate around b[0] */
      bTemp[1].x  = cosine * distanceVect.x + sine * distanceVect.y;
      bTemp[1].y  = cosine * distanceVect.y - sine * distanceVect.x;

      // rotate Temporary velocities
      PVector[] vTemp = {
        new PVector(), new PVector()
      };

      vTemp[0].x  = cosine * velocity.x + sine * velocity.y;
      vTemp[0].y  = cosine * velocity.y - sine * velocity.x;
      vTemp[1].x  = cosine * other.velocity.x + sine * other.velocity.y;
      vTemp[1].y  = cosine * other.velocity.y - sine * other.velocity.x;

      /* Now that velocities are rotated, you can use 1D
       conservation of momentum equations to calculate 
       the final velocity along the x-axis. */
      PVector[] vFinal = {  
        new PVector(), new PVector()
      };

      // final rotated velocity for b[0]
      vFinal[0].x = ((m - other.m) * vTemp[0].x + 2 * other.m * vTemp[1].x) / (m + other.m);
      vFinal[0].y = vTemp[0].y;

      // final rotated velocity for b[0]
      vFinal[1].x = ((other.m - m) * vTemp[1].x + 2 * m * vTemp[0].x) / (m + other.m);
      vFinal[1].y = vTemp[1].y;

      // hack to avoid clumping
      bTemp[0].x += vFinal[0].x;
      bTemp[1].x += vFinal[1].x;

      /* Rotate ball positions and velocities back
       Reverse signs in trig expressions to rotate 
       in the opposite direction */
      // rotate balls
      PVector[] bFinal = { 
        new PVector(), new PVector()
      };

      bFinal[0].x = cosine * bTemp[0].x - sine * bTemp[0].y;
      bFinal[0].y = cosine * bTemp[0].y + sine * bTemp[0].x;
      bFinal[1].x = cosine * bTemp[1].x - sine * bTemp[1].y;
      bFinal[1].y = cosine * bTemp[1].y + sine * bTemp[1].x;

      // !!! IMPORTANT !!!
      // The following lines must be commented out–otherwise there's a clumping issue with large numbers
       //<>//
      // update balls to screen position
      // other.position.x = position.x + bFinal[1].x;
      // other.position.y = position.y + bFinal[1].y;

      // position.add(bFinal[0]);

      // update velocities
      velocity.x = cosine * vFinal[0].x - sine * vFinal[0].y;
      velocity.y = cosine * vFinal[0].y + sine * vFinal[0].x;
      other.velocity.x = cosine * vFinal[1].x - sine * vFinal[1].y;
      other.velocity.y = cosine * vFinal[1].y + sine * vFinal[1].x;
    }
  }

  void display() {
    noStroke();
    if (state == State.INFECTED) {
      fill(252, 3, 40);
    } else if (state == State.UNINFECTED) {
      fill(204);
    } else {
      fill(135, 224, 145);
    }
    
    ellipse(position.x, position.y, radius*2, radius*2);
  }
}


class Column {
  int colWidth = 1;
  int top = 10;
  int totalHeight = 30;
  int numActors = balls.size();
  int infected_, uninfected_, recovered_; //<>//
  // position vars for top/recovered
  PVector position1Top, position1Bottom;
  // position vars for middle/uninfected
  PVector position2Top, position2Bottom;
  // position vars for bottom/infected
  PVector position3Top, position3Bottom;
  
  Column () {
    this.infected_ = infected;
    this.uninfected_ = uninfected;
    this.recovered_ = recovered;
    
    float recoveredShare = recovered_ * 1.0 / numActors * totalHeight;
    float infectedShare = infected_ * 1.0 / numActors * totalHeight;
    float uninfectedShare = uninfected_ * 1.0 / numActors * totalHeight;
    
    position1Top = new PVector(leftCol, top);
    position1Bottom = new PVector(leftCol + colWidth, top + recoveredShare);
    position2Top = new PVector(leftCol, top + recoveredShare);
    position2Bottom = new PVector(leftCol + colWidth, top + recoveredShare + uninfectedShare);
    position3Top = new PVector(leftCol, top + recoveredShare + uninfectedShare);
    position3Bottom = new PVector(leftCol + colWidth, top + recoveredShare + infectedShare + uninfectedShare);
  }
  
  void display() {
    noStroke();
    rectMode(CORNERS);
    fill(135, 224, 145);
    rect(position1Top.x, position1Top.y, position1Bottom.x, position1Bottom.y);
    fill(180);
    rect(position2Top.x, position2Top.y, position2Bottom.x, position2Bottom.y); //<>//
    fill(252, 3, 40);
    rect(position3Top.x, position3Top.y, position3Bottom.x, position3Bottom.y);
  }
}
