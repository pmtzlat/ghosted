import processing.sound.*;

PFont titleFont; // spooky font imported

//soundfiles created
SoundFile menuMusic;
SoundFile uiSelect;
SoundFile thunder;
SoundFile death_music;
SoundFile eat;

//images created
PImage candy1;
PImage candy2;
PImage candy3;
PImage title;
PImage death_msg;
PImage play;
PImage quit;
PImage arrowLeft;
PImage arrowRight;
PImage ghost;
PImage player;
PImage plus100;
PImage score;
PImage pumpkin_icon;
PImage pumpkin_sprite;
PImage bone_icon;
PImage pumpkin_title;
PImage bones_title;
PImage pop;
PImage menu_btn;

float level = 0; //determines which screen the user is displayed, and what code is run

int death = 0;  //determines if the player is dead

//variables created to control user input to prevent interruptions between button presses
int singlePlayerMovementX = 0;
int singlePlayerMovementY = 0;

float blockStartingHeight = height/2-12; //determines at what height the bones spawn
float blockSpeed = 2; // determines bone speed
int player_score= 0; //determines the score
int eaten = 0; // used to time the sounds. If it is 0, no sound is played. If it is 1, a sound is played. If it is -1, it's waiting to turn to 0 again.
// this triple value is made to avoid playing the same sound lots of times due to the nature of the draw() function. When a collision happens, the 
// candy object in bone rush plays the sound and switches it to -1. Once the candy is reset to the top of the stage, it resets this variable to 0 so that the 
// collision can switch it back to 1. It's a three-step cycle.

int increasePumpkinVel = 0;  //used to control when to increase the pumpkin's speed. Works like 'eaten', in a three step process(the values represent the same thing).

//these variables determine where the boundary for the game is, to limit player and object movement
float leftBoundary = 330; 
float rightBoundary = 750;
float topBoundary = 80;
float bottomBoundary = 630;

int num_pump =0; // keeps track of the number of pumpkins

Player singlePlayer= new Player(500, 630); // creates the player object

Pumpkin candy_pumpkin = null; //initializes the candy for pumpkin mode as null

//these variables are used in the bone rush game
int starterBlock=0; //determines the number of bones that are stored in the array of bones, used to control when the bones spawn
int starterCandy = 0; // determines the number of candies that are stored in the array of candies, used to control when the candies spawn
int bones_noBlock =0; // keeps track of what section of the screen has been used most recently to spawn a bone

Block[] block_arr= new Block[4]; //array to store the bone objects
Candy[] cObjArr = new Candy[2]; // array to store the candy objects in bone rush
PImage[] candyArr = new PImage[4]; // array to store the candy images to be displayed
Pumpkin[] pump_arr = new Pumpkin[6]; // array to store the pumpkin objects

class Pumpkin {  //pumpkin class created
  float xpos;  // x coordinate
  float ypos;  // y coordinate
  float xvel;  // x velocity
  float yvel;   // y velocity
  int blinker;  //determines whether the pumpkin should blink or not
  int maxTime;  //serves as a timestamp to deal with timing mechanisms
  int candy;  //determines whether the pumpkin object acts as a candy or not. The candy behaves like a pumpkin except for a few differences, so they are in the same class.
  int candyVal; //determines what image of candy will be used
  int destroyed;  //determines if the pumpkin has been destroyed

  Pumpkin(float x, float y, float xv, float yv, int c) {  //constructor
    xpos = x;
    ypos = y;
    xvel = xv;
    yvel = yv;
    blinker = 1;  //blinker starts at 1, so that the objects spawn while blinking
    candy = c;
    destroyed = 0;  //object is not destroyed form the start
    candyVal = int(random(0, 3));  //random variable determines what image for the candy will be displayed. It is used as index for the 
    maxTime = frameCount;  //timestamp
  }

  void drawer() {
    if (destroyed == 1) { // if the pumpkin is destroyed, it will show a different image depending on if its a candy or not.

      if (candy ==1) {
        image(candyArr[3], xpos, ypos, 50, 50);
      } else {
        image(pop, xpos, ypos, 50, 50);
      }
    } else {  // if it is not desroyed, it will blink for 500 frames using the maxTime attr.
      if (frameCount - maxTime < 500) {
        if (frameCount % 45 ==0) { // if the framecount is a multiple of 45, switch the value of 'blinker'
          blinker = -blinker;
        }
        if (blinker ==1) {  // if 'blinker' is 1, display the images. A different image is displayed if the pumpkin is a candy or not.
          if (candy == 0 ) {

            image(pumpkin_sprite, xpos, ypos);
          } else if (candy == 1) {
            image(candyArr[candyVal], xpos, ypos, 50, 50);
          }
        }
      } else {  //once the blinking time ends, diplsy the images
        if (candy == 0 ) {

          image(pumpkin_sprite, xpos, ypos);
        } else if (candy == 1) {
          image(candyArr[candyVal], xpos, ypos, 50, 50);
        }
      }
    }
  }

  void move() { // method to update the pumpkin's coordinates
    if (destroyed ==1) {  // if the pumpkin is destroyed, waits for 150 frames, and then destroys itself
      if (frameCount - maxTime >150) {
        if (candy==0)despawnPumpkin();
        if (candy==1)despawnCandyPumpkin();
      }
    } else {
      //switches velocities if pumpkin has hit boundary
      if ((xpos>rightBoundary)||(xpos<leftBoundary)) {
        xvel = -xvel;
      }
      if ((ypos>bottomBoundary+40)||(ypos<topBoundary-10)) {
        yvel = -yvel;
      }
      if (frameCount - maxTime > 500) {  //checks for collisions once the blinking period has ended
        collisionCheck();
      }
      //updates the coordinates according to the pumpkin's speed
      xpos +=xvel;
      ypos +=yvel;
    }
  }

  void collisionCheck() { //checks for collisions with the player using the player and the pumpkin's coordinates
    float xP = singlePlayer.xpos;
    float yP = singlePlayer.ypos;
    if (((xpos < xP+35) && (xpos > xP-35))&&((ypos < yP+45) && (ypos > yP-45))) {
      if (candy ==0) {  //if the pumpkin is not a candy, plays death sfx, and activates the death variable.
        death_music.play();
        death=1;
      } else {  //if it's a candy
        eat.play();  //plays sfx
        pump_arr[num_pump-1].destroyed = 1;  //sets the last element of the pumpkin array to destroyed = 1, which will make the pumpkin change image and then self-destruct
        pump_arr[num_pump-1].maxTime = frameCount;  //refreshes its timestamp too, so that the 'pop' image is displayed the correct amount of time
        player_score += 100;  // adds 100 to the score
        destroyed = 1;  // sets its destroyed value as 1
        increasePumpkinVel = 0; // sets the varibale into being ready to change the speed of the pumpkins
        maxTime = frameCount;  //updates its timestamp
      }
    }
  }
}

class Candy { //candy object for the bone rush game
  int segment;  //determines the part of the screen it will fall in
  float ypos; // y coordinate
  int candy;  // variable to deterine the image of the candy it will display
  int exploded;  // variable to change the image of the object to a '+100'
  float yExplosion;  //y coordinate of the explosion, to it doesnt move down as it explodes
  int timestamp; // timestamp for the display of '+100'

  Candy () {  
    segment = int(random(1, 5));  //appears on a random segment, but the checks if that segment is 'noBlock', 
    // and if it is, it rolls the dice again. This is to avoid having many bones/candies falling 
    //in the same column
    while (segment==bones_noBlock) {
      segment = int(random(1, 5));
    }
    ypos = blockStartingHeight-100; // spawns the candy just over the upper limit
    candy = int(random(0, 3));
    bones_noBlock = segment; // saves the segment in 'noBlock'
    exploded=0;  //seved to 0 as the candy hasnt exploded yet
    yExplosion=0;  
    timestamp =0;
  } 

  void move() {
    if (ypos<290+height/2) {  // if the candy hasn't reached the bottom and hasn't exploded, updates the y coordinate
      if (exploded==0) ypos += blockSpeed;
    } else {  //if the candy gets to the bottom
      segment = int(random(1, 5));  //appears on a random segment, but the checks if that segment is 'noBlock', 
      // and if it is, it rolls the dice again. This is to avoid having many bones/candies falling 
      //in the same column
      while (segment==bones_noBlock) {
        segment = int(random(1, 5));
      }
      candy = int(random(0, 3));
      bones_noBlock = segment;
      ypos = blockStartingHeight-100;
      if (exploded==1) {  //if it has exploded, it adds 100 to the score
        player_score +=100;
      }
      exploded = 0; //resets the variables
      eaten=0;
    }
  }

  void drawer() {  //draws the candy
    if (exploded ==0) {   // if it hasn't exploded, display a candy
      image(candyArr[candy], 184.5+segment*118.5+58, ypos, 70, 70);
    } else if (exploded ==1) {
      if (frameCount - timestamp <50) { // if it has epxloded, displays '+100' for 50 frames, then disappears
        image(candyArr[candy], 184.5+segment*118.5+58, ypos, 70, 70);
        if (eaten==1) { // plays the sound of eating a candy and sets 'eaten' to -1
          eat.play();
          eaten=-1;
        }
      } else ypos = 290+height/2; // if it has exploded and the timestamp is up, move the candy to the top, where it will be reprocessed by the move() method
    }
  }

  void explode() { // switches variables to ensure proper actions take place. Only executed once, when the main function of bone rush detects a collision.
    candy = 3;
    exploded = 1;
    timestamp = frameCount;
  }
}


class Player { // player class
  float xpos;
  float ypos;
  float speed;
  int face;  // used to filp the sprite around depending on the input. 1= right, -1=left
  Player (float x, float y) {  
    xpos = x;  
    ypos = y;
    speed = 3;
    face=1;
  } 
  void drawer() {
    pushMatrix();
    scale(face, 1); //used to flip the image
    image(ghost, face*xpos, ypos, 80, 80);
    popMatrix();
  }

  void moveLeft() { 

    if (xpos > leftBoundary+10) { //if in boundary, moves the player left, and changes the value of 'face'
      xpos -= speed;
      face=-1;
    }
  } 

  void moveRight() { 

    if (xpos < rightBoundary-10) { //if in boundary, moves the player right, and changes the value of 'face'
      xpos += speed;
      face=1;
    }
  } 

  void moveUp() {
    if ( ypos > topBoundary) {
      ypos -= speed;
    }
  }
  void moveDown() {
    if ( ypos < bottomBoundary) {
      ypos += speed;
    }
  }
}


class Block { // class for the bones
  int segment;  //determines which of the four columns of the play space it will spawn in 
  float ypos;

  Block () {  
    segment = int(random(1, 5));   //appears on a random segment, but the checks if that segment is 'noBlock', 
    // and if it is, it rolls the dice again. This is to avoid having many bones/candies falling 
    //in the same column
    while (segment==bones_noBlock) {
      segment = int(random(1, 5));
    }
    bones_noBlock = segment; // sets a new value for 'noBlock'
    ypos = blockStartingHeight;  //sets the starting y coordinate to the top
  } 

  void move() {
    if (ypos<310+height/2) {  //if the y coord is not over the bottom, move the bone down
      ypos += blockSpeed;
    } else { // if the bone gets to the bottom
      segment = int(random(1, 5));//appears on a random segment, but the checks if that segment is 'noBlock', 
      // and if it is, it rolls the dice again. This is to avoid having many bones/candies falling 
      //in the same column
      while (segment==bones_noBlock) {
        segment = int(random(1, 5));
      }
      bones_noBlock = segment;  // sets a new value for 'noBlock'
      ypos = blockStartingHeight;  //sets the starting y coordinate to the top
    }
  }

  void drawer() {  //draws the bone, with the segment adding x*118.5 to the left boundary to get different positioning of the bones

    fill(255);
    rectMode(CORNER);
    noStroke();
    rect(184.5+segment*118.5, ypos, 118.5, 10);
    ellipse(184.5+segment*118.5+2, ypos-1, 10, 10);
    ellipse(184.5+segment*118.5+2, ypos+11, 10, 10);
    ellipse(184.5+segment*118.5+118.5-2, ypos-1, 10, 10);
    ellipse(184.5+segment*118.5+118.5-2, ypos+11, 10, 10);

    rectMode(CENTER);
  }
}




void setup() {  // setup function. loads all the assets and initialises arrays

  title = loadImage("title.png");
  play = loadImage("play.png");
  quit = loadImage("quit.png");
  arrowLeft = loadImage("leftArrow.png");
  arrowRight = loadImage("rightArrow.png");
  ghost = loadImage("ghost.png");
  player = loadImage("player.png");
  plus100 = loadImage("+100.png");
  death_msg = loadImage("death_msg.png");
  candy1 = loadImage("candy1.png");
  candy2 = loadImage("candy2.png");
  candy3 = loadImage("candy3.png");
  score = loadImage("score.png");
  pumpkin_icon = loadImage("pumpkin icon.png");
  pumpkin_sprite = loadImage("pumpkin_sprite.png");
  bone_icon = loadImage("boneSprite.png");
  pop = loadImage("pop.png");
  pumpkin_title = loadImage("pumpkins.png");
  bones_title = loadImage("bones.png");
  menu_btn = loadImage("menu_btn.png");
  candyArr[0] = candy1;
  candyArr[1] = candy2;
  candyArr[2] = candy3;
  candyArr[3] = plus100;

  for (int i=0; i<4; i++) {
    block_arr[i] = new Block();
  }
  for (int i=0; i<2; i++) {
    cObjArr[i] = new Candy();
  }

  titleFont = loadFont("Chiller-Regular-80.vlw");


  size(1080, 720);
  background(0);
  menuMusic = new SoundFile(this, "lofi_cut.mp3");
  uiSelect = new SoundFile(this, "ui_select.mp3");
  thunder = new SoundFile(this, "thunder.mp3");
  death_music = new SoundFile(this, "death.mp3");
  eat = new SoundFile(this, "eat.mp3");

  menuMusic.loop(); //loops the music
  frameRate(120);  //as this project doesnt require much processing power, a high framerate is possible
}

void drawArrows(float x1, float y1, float x2, float y2) {  //draws arrows for buttons on the screen
  drawArrowLeft(x1, y1);
  drawArrowRight(x2, y2);
}

void drawArrowLeft(float x1, float y1) {  //draws left arrow
  imageMode(CENTER);
  image(arrowLeft, x1-50, y1);
}

void drawArrowRight(float x2, float y2) {  //draws right arrow
  imageMode(CENTER);
  image(arrowRight, x2+50, y2);
}

void drawTitle() {  //draws the title fo the main menu.
  float titleposx = width/2;
  float titleposy = height/2-200;
  translate(titleposx, titleposy);
  imageMode(CENTER);
  image(title, 0, 0, 728, 160);
  translate(-width/2, -(height/2-200));
}

void drawButtons() {  // draws the buttons for the main menu
  translate(700, 600);
  imageMode(CENTER);
  image(play, 0, 0);

  translate(-300, 0);
  image(quit, 0, 0);
  translate(-400, -600);
}

void drawMenu() {  //draws the main menu
  background(0);
  image(ghost, width/2, height/2+30, 250, 250);
  drawTitle();
  drawButtons();
  if ((mouseY>575)&&(mouseY<625)) {  //draws the arrows if themouse hovers over the buttons' coordinates
    if ((mouseX>650)&&(mouseX<760)) {
      drawArrows(680, 603, 722, 603);
    }
    if ((mouseX>350)&&(mouseX<460)) {
      drawArrows(380, 603, 422, 603);
    }
  }
}

void drawStageSelect() {  //draws the game select screen
  rectMode(CENTER);
  if ((mouseY>110)&&(mouseY<570)) {   //if the mouse hovers over the game modes, a golden rectangle will envelop the button
    if ((mouseX>190)&&(mouseX<480)) {

      fill(255, 215, 0);
      rect(335, 360, 290+70, 460+30);
      fill(0);
      rect(335, 360, 274+70, 444+30);
    }
  }
  if ((mouseY>110)&&(mouseY<570)) {
    if ((mouseX>190+410)&&(mouseX<480+410)) {
      fill(255, 215, 0);
      rect(335+410, 360, 290+70, 460+30);
      fill(0);
      rect(335+410, 360, 274+70, 444+30);
    }
  }
  drawQuitandMenu();  //draws the quit and menu buttons
  fill(150);
  float x= 0.9;
  float y= 0.9;
  ellipseMode(CENTER);//draws the images for the buttons accordingly
  ellipse(330, 300, 200, 200);
  ellipse(740, 300, 200, 200);
  image(bones_title, 330, 500, 255*x, 134*x);
  image(pumpkin_title, 730, 500, 353*y, 251*y);
  image(bone_icon, 330, 300, 170, 80);
  image(pumpkin_icon, 740, 300, 180, 226);
}

void drawQuitandMenu() {  //draws the quit and menu buttons at the corner of the screen, and draws an arrow next to them if the mouse hovers over them
  image(quit, 80, 40);
  if ((mouseY>18)&&(mouseY<65)) {
    if ((mouseX>35)&&(mouseX<130)) {
      drawArrowRight(100, 40);
    }
  }
  image(menu_btn, 80, 95, 110, 55);
  if ((mouseY>75)&&(mouseY<115)) {
    if ((mouseX>35)&&(mouseX<130)) {
      drawArrowRight(100, 95);
    }
  }
}

void drawScreen(int x) {  //draws the main frame of the game modes, whic is basically the quit and menu buttons,
  // and the rectange for the game area, and the score.
  fill(255, 215, 0);
  rect(width/2, height/2, 290+x, 460+x);
  fill(0);
  rect(width/2, height/2, 274+x, 444+x);
  image(score, 900, height/2-300, 116, 38);
  fill(255, 215, 0);
  rect(900, height/2-200, 170, 130);
  fill(0);
  rect(900, height/2-200, 162, 122);
  fill(255, 215, 0);
  textSize(40);
  text(player_score, 850, height/2-200);
}

void drawTopCover() {      // draws a gold and a black rectange at the top of the game area so that when objects relocate
  // to the top of the screen in bone rush they aren't visible, and as they move down they appear
  // smoothly

  fill(255, 215, 0);
  rect(width/2, height/2-370, 490, -100);
  fill(0);
  rect(width/2, height/2-378, 490, -100);
}

void drawBones() {    // the main function of the bone rush mode
  drawQuitandMenu();
  drawScreen(200);
  if ((death>=1)&&(death<100)) {  // if death is more than 1 but less than 100

    singlePlayer.drawer();  //draw the player 
    for (int i=0; i<4; i++) {  // draw the bones
      block_arr[i].drawer();
    }
    for (int i=0; i<2; i++) {  // draw the candies
      cObjArr[i].drawer();
    }
    fill(255, 3*death);  //draw a white film that gets more opaque as 'death' goes up
    rectMode(CENTER);
    rect(width/2, height/2, 474, 644);
    death+=1;
  } else if (death==100) {  //if death gets to 100

    fill(255);
    rectMode(CENTER);
    rect(width/2, height/2, 474, 644);
    image(death_msg, width/2, height/2, 395, 105);  // draws game over message
  } else if (death==0) {  

    //these if statements change the difficulty of the game by changing the speed as the 
    // player's score rises in a predetermined way
    blockSpeed = 2 + 0.5*(player_score/1000);

    pushMatrix();
    singlePlayer.drawer();  //draws the player
    popMatrix();
    if (singlePlayerMovementX ==1) {  
      singlePlayer.moveLeft();
    } else if (singlePlayerMovementX == -1) {
      singlePlayer.moveRight();
    }

    //the first bone is drawn and moved first
    if (starterBlock==0) {

      block_arr[0].drawer();
      block_arr[0].move();
    } else {  //then, if starterBlock is not 0, all the objects in the array are drawn and moved
      for (int i=0; i<starterBlock+1; i++) {
        block_arr[i].drawer();
        block_arr[i].move();
      }
    }

    if ((block_arr[starterBlock].ypos == 200) && (starterBlock<3)) { // once the 3 most recent bones spawned reached a quarter of the way down, 
      // starterBlock is increased by 1 to allow more bones to be spawned in
      starterBlock+=1;
    }

    if ((block_arr[0].ypos == 200)||(cObjArr[0].ypos == 322)) {  // if the first bone reaches a quarter of the way down, 
      // or the first candy reaches a given y value, increase startercandy by 1
      if (starterCandy<2) starterCandy += 1;
    }


    if (starterCandy >=1) {    //starterCandy determines which candy objects to draw and move, as it gets bigger, it spawns the candies

      for (int i=0; i<starterCandy; i++) {
        println("i: " + i);
        cObjArr[i].drawer();
        cObjArr[i].move();
      }
    }


    for (int i=0; i<4; i++) { // this for loop iterates over the bone objects and detects collisions
      if ((block_arr[i].ypos>230+height/2)&&(block_arr[i].ypos<270+height/2)) {

        if ((singlePlayer.xpos>184.5+block_arr[i].segment*118.5)
          &&(singlePlayer.xpos<184.5+block_arr[i].segment*118.5+118.5)) {
          // if a collision is detected, the music sound is played, and 'death' is switched on 
          death_music.play();
          death+=1;
        }
      }
    }
    for (int i=0; i<2; i++) {   // this for loop detects collisions with the candies
      if ((cObjArr[i].ypos>210+height/2)&&(cObjArr[i].ypos<315+height/2)) {

        if ((singlePlayer.xpos>184.5+cObjArr[i].segment*118.5)
          &&(singlePlayer.xpos<184.5+cObjArr[i].segment*118.5+118.5)) {

          if (eaten==0) { // this if statement is only executed once  by switching the value of 'eaten', 
            // that way the 'eat' souund is only played once

            eaten = 1;
            cObjArr[i].explode();  // explodes the cnady that has collided
          }
        }
      }
    }

    drawTopCover();
  }
}

void drawPumpkins() {
  drawQuitandMenu();
  drawScreen(200);

  if ((death>=1)&&(death<100)) { //if 'death' is between 1 and 100 , it draws the transparent film over the game

    singlePlayer.drawer();
    for (int i=0; i<6; i++) {
      if (pump_arr[i] != null) {
        pump_arr[i].drawer();
      }
    }
    fill(255, 3*death); //the opacity increases as 'death' does
    rectMode(CENTER);
    rect(width/2, height/2, 474, 644);
    death+=1;
  } else if (death==100) {  // draws the game over message

    fill(255);
    rectMode(CENTER);
    rect(width/2, height/2, 474, 644);
    image(death_msg, width/2, height/2, 395, 105);
  } else if (death==0) { // if the player is not dead

    singlePlayer.drawer();
    // the following if statements are put in so that if the player hits two keys at the same time in a diagonal direction, 
    // the player speed in that diagonal direction is the same as the horizontal (achiebed using the pythagorean thm)
    if ((singlePlayerMovementX!=0) && (singlePlayerMovementY!=0)) {
      singlePlayer.speed=2.1;
    } else {
      singlePlayer.speed = 2.1;
    }

    //singlePlayerMovement(X and Y) control the movement of the player
    if (singlePlayerMovementX ==1) {
      singlePlayer.moveLeft();
    } else if (singlePlayerMovementX == -1) {
      singlePlayer.moveRight();
    }
    if (singlePlayerMovementY ==-1) {
      singlePlayer.moveUp();
    } else if (singlePlayerMovementY == 1) {
      singlePlayer.moveDown();
    }


    if (frameCount %1000==0) {  //if the framecount is a multiple of 1000, the pumpkin that spawns has a faster velocity
      spawnPumpkin(0+(player_score/100));
    }

    if ((player_score%300==0)&&(player_score>0)) { // if the player a score thats a multiple of 500, all the pumpkins move faster
      if (increasePumpkinVel == 0) {
        increasePumpkinVel =1;  // this activates the signal to increase the velocity
      }
    }
    
    if(increasePumpkinVel==1){
      for (int i=0; i<num_pump; i++) {  // if the signal increasePumpkinVel is activated, the pumpkins' speeds are increased
        pump_arr[i].xvel +=0.2;
        pump_arr[i].yvel +=0.2;
      }
      increasePumpkinVel = -1;  // the variable is switched to another value 
    }
    if ((frameCount %1775==0)&&(num_pump>0)&&(candy_pumpkin == null)) {  // spawns the candy pumpkin on a given framecount time
                                                                         // if there is more than one pumpkin and there is no candy pumpkin
      spawnCandyPumpkin();
    }
    if (candy_pumpkin != null) {  //draw and move the candy pumpkin
      candy_pumpkin.drawer();
      candy_pumpkin.move();
    }

    for (int i=0; i<6; i++) {  //draw and move all the active regular pumpkins
      if (pump_arr[i] != null) {
        pump_arr[i].drawer();
        pump_arr[i].move();
      }
    }
  }
}

void spawnPumpkin(int acc) {  // spawns a pumpkin

  if (num_pump <6) {  //limits the number of pumpkins to six
    float x = random(leftBoundary, rightBoundary);  //spawns the pumpkin in a random coordinate
    float y = random(topBoundary, bottomBoundary);
    float sx = random(0.1+0.1*acc, 1+0.1*acc);  //spawns the pumpkin with a random speed that increases as the acceleration goes up
    float sy = random(0.1+0.1*acc, 1+0.1*acc);

    pump_arr[num_pump] = new Pumpkin(x, y, sx, sy, 0);  //inserts the pumpkin into the array
    num_pump +=1;   // updates num_pump
  }
}

void spawnCandyPumpkin() {  //works the same as spawnPumpkin but doesn't accelerate or update num_pump

  float x = random(leftBoundary, rightBoundary);
  float y = random(topBoundary, bottomBoundary);
  float sx = random(0.1, 1.5);
  float sy = random(0.1, 1.5);
  candy_pumpkin = new Pumpkin(x, y, sx, sy, 1);
}


void despawnPumpkin() {  //deletes the pumpkin by updating num_pump and emptying the last pumpkin in the array (like a stack)
  if (num_pump>0) {
    num_pump -=1;
    pump_arr[num_pump] = null;
  } else if (num_pump ==0) {
    pump_arr[0]=null;
  }
}

void despawnCandyPumpkin() {  //deletes the candy pumpkin
  candy_pumpkin = null;
}

void deathReset() {  //resets all variables and game conditions  
  singlePlayer= new Player(500, 630);
  for (int i=0; i<4; i++) {
    block_arr[i] = new Block();
  }
  for (int i=0; i<2; i++) {
    cObjArr[i] = new Candy();
  }
  for (int i=0; i<6; i++) {
    pump_arr[i] = null;
  }
  if (level ==2) {  //if pumpkin bash gamemode is selected, the player spawns in the middle of the screen
    singlePlayer.xpos = width/2;
    singlePlayer.ypos = height/2;
  }

  death=0;
  candy_pumpkin = null;
  starterBlock=0;
  starterCandy=0;
  player_score=0;
  thunder.play();  //plays thunder every time the game is reset 
  num_pump=0;
}
void draw() {  //runs different code depending on what needs to be shown on screen
  background(0);
  if (level==0) {
    //main menu
    drawMenu();
  }
  if (level==0.5) {
    //stage select
    drawStageSelect();
  } 
  if (level==1) {
    //Bones game
    drawBones();
  } 
  if (level==2) {
    // Pumpkin game
    drawPumpkins();
  }
}


void mouseClicked() {  //depending on the game mode and the mouse coordinates, the mouse click does different things. 
  if (level==0) {  //main menu
    if ((mouseY>575)&&(mouseY<625)) {
      if ((mouseX>650)&&(mouseX<760)) {
        uiSelect.play();  //plays a ui sfx
        level=0.5;  // changes the level to the game mode select screen
      }
      if ((mouseX>350)&&(mouseX<460)) {
        uiSelect.play();
        exit();  //exits the game
      }
    }
  }
  if (level>0) {  //all the levels except the main menu have a common button setup, with a quit and a menu button
    if ((mouseY>18)&&(mouseY<65)) {
      if ((mouseX>35)&&(mouseX<130)) {
        uiSelect.play();  //plays a UI sfx
        exit();  //closes the game
      }
    }
    if ((mouseY>75)&&(mouseY<115)) {
      if ((mouseX>35)&&(mouseX<130)) {
        uiSelect.play();  // plays a ui sfx
        level = 0;  // changes the level back to the menu
      }
    }
  }
  if (level==0.5) {  // level select screen
    if ((mouseY>110)&&(mouseY<570)) {
      if ((mouseX>190)&&(mouseX<480)) {
        deathReset();  //resets the variables in preparation for gameplay 
        level=1;  // changes the level to bone rush
      }
    }
    if ((mouseY>110)&&(mouseY<570)) {
      if ((mouseX>190+410)&&(mouseX<480+410)) {
        deathReset();  // resets the variables
        singlePlayer.xpos = width/2;   //moves the player to the middle of the screen
        singlePlayer.ypos = height/2;
        level=2;  //changes the level to pumpkin rush
      }
    }
  }
}

void keyPressed() {  //keyboard controls for the games
  //to enable holding down buttons, the keypress activates a variable which signals the player object's
  // move() method to update the coords of the player accordingly. 0 = stop, 1 = one direction, -1 = opposite direction
  // the variable will have the value of the key that has been pressed most recently
  if (level==1) {
    if (key == CODED) {
      if (keyCode == LEFT) {
        singlePlayerMovementX = 1;  
      } else if (keyCode == RIGHT) {
        singlePlayerMovementX = -1;
      }
    }
  } else if (level==2) {
    if (key == CODED) {
      if (keyCode == LEFT) {
        singlePlayerMovementX = 1;
      } else if (keyCode == RIGHT) {
        singlePlayerMovementX = -1;
      } else if (keyCode == UP) {
        singlePlayerMovementY = -1;
      } else if (keyCode == DOWN) {
        singlePlayerMovementY = 1;
      }
    }
  }
  if (keyCode == 82) {   // this is used to detect the 'R' key so that the player can start again after a game over.
                         // it only does something when the player has died 
    if (death>0) {
      deathReset();
      death=0;
    }
  }
}

void keyReleased() {  // key release to stop player movement
  if (level==1) {  
    if (key == CODED) {
      if ((keyCode == LEFT)&&(singlePlayerMovementX==1)) {  // to prevent the keypress and the keyrelease to interfere with each other 
                                                            // when two keys are being pressed and one is released before the other,
                                                            // the keyrelease only stops the player movement if singlePlayerMovement
                                                            // has the value corresponding to the direction that is released. 
                                                            // that way the player only stops when both keys are released
        singlePlayerMovementX = 0;
      } else if ((keyCode == RIGHT)&&(singlePlayerMovementX==-1)) {
        singlePlayerMovementX = 0;
      }
    }
  } else if (level==2) {
    if (key == CODED) {
      if ((keyCode == LEFT)&&(singlePlayerMovementX==1)) {
        singlePlayerMovementX = 0;
      } else if ((keyCode == RIGHT)&&(singlePlayerMovementX==-1)) {
        singlePlayerMovementX = 0;
      } else if ((keyCode == UP)&&(singlePlayerMovementY==-1)) {
        singlePlayerMovementY = 0;
      } else if ((keyCode == DOWN)&&(singlePlayerMovementY==1)) {
        singlePlayerMovementY = 0;
      }
    }
  }
}
